#!/usr/bin/env python3
"""Install the compiler's reviewed distiller files, independent of its checkout."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import uuid


FILES = ("nightly-entry.py", "runtime-proof.py", "c8-mcp.py", "teamkb-compile-daily.sh", "eval-distiller-output.mjs")


def install(source, destination, revision):
    def git(*args):
        return subprocess.run(["git", "-C", str(source), *args], check=True, capture_output=True).stdout

    resolved = git("rev-parse", "--verify", f"{revision}^{{commit}}").decode().strip()
    if not re.fullmatch(r"[a-f0-9]{40}", resolved):
        raise ValueError("invalid compiler revision")
    git("merge-base", "--is-ancestor", resolved, "refs/remotes/origin/main")
    destination.mkdir(parents=True, exist_ok=True)
    releases = destination / "releases"
    releases.mkdir(exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".install-", dir=releases))
    try:
        hashes = {}
        for name in FILES:
            data = git("show", f"{resolved}:scripts/distiller/{name}")
            (stage / name).write_bytes(data)
            (stage / name).chmod(0o755)
            hashes[name] = hashlib.sha256(data).hexdigest()
        subprocess.run(["bash", "-n", str(stage / "teamkb-compile-daily.sh")], check=True)
        for name in FILES:
            if name.endswith(".py"):
                compile((stage / name).read_bytes(), name, "exec")
        manifest = {"revision": resolved, "sha256": hashes}
        (stage / "manifest.json").write_text(json.dumps(manifest, sort_keys=True) + "\n")
        target = releases / resolved
        if target.exists():
            if (target / "manifest.json").read_bytes() != (stage / "manifest.json").read_bytes():
                raise ValueError("existing compiler manifest differs")
            for name, digest in hashes.items():
                if hashlib.sha256((target / name).read_bytes()).hexdigest() != digest:
                    raise ValueError("existing compiler release drifted")
        else:
            os.replace(stage, target)
        current = destination / "current"
        previous = current.resolve(strict=True) if current.exists() else None
        if current.exists() and not current.is_symlink():
            raise ValueError("current compiler must be a managed symlink")
        if previous and previous != target:
            old = destination / f".previous-{uuid.uuid4().hex}"
            old.symlink_to(previous)
            os.replace(old, destination / "previous")
        link = destination / f".current-{uuid.uuid4().hex}"
        link.symlink_to(target)
        os.replace(link, current)
        return {"event": "compiler_bundle_installed", "revision": resolved,
                "previous_revision": previous.name if previous else None, "files": len(FILES)}
    finally:
        if stage.exists():
            shutil.rmtree(stage)  # Only this invocation's newly-created staging directory.


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--revision", default="refs/remotes/origin/main")
    args = parser.parse_args()
    print(json.dumps(install(args.source, args.destination, args.revision)))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError):
        raise SystemExit("teamkb-compile: reviewed compiler bundle installation failed; current entry retained") from None
