#!/usr/bin/env python3
"""Hermetic ownership/rollback tests with Git objects and real installed entries."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("installer", ROOT / "bin/install-teamkb-compiler.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="compiler-install-")
        self.root = Path(self.temp.name)
        self.source = self.root / "compiler"
        self.source.mkdir()
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.payload = self.source / "scripts/distiller"
        self.payload.mkdir(parents=True)
        for name in installer.FILES:
            text = "#!/bin/sh\nexit 0\n" if name.endswith(".sh") else "# fixture\n" if name.endswith(".py") else "// fixture\n"
            (self.payload / name).write_text(text)
        (self.payload / "nightly-entry.py").write_text("print('fixture-compiler-ran')\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Fixture reviewed compiler")
        self.revision = self.git("rev-parse", "HEAD").strip()
        self.git("update-ref", "refs/remotes/origin/main", self.revision)
        self.destination = self.root / "home/.local/lib/teamkb-compile"

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.source), *args], check=True, capture_output=True, text=True).stdout

    def run_entry(self):
        env = os.environ.copy()
        env["HOME"] = str(self.root / "home")
        env.pop("TEAMKB_COMPILE_RELEASE", None)
        return subprocess.run(["bash", str(ROOT / "bin/teamkb-compile-daily.sh")], env=env,
                              capture_output=True, text=True, timeout=10)

    def test_git_objects_ignore_changed_checkout_and_deploy_idempotently(self):
        (self.payload / "nightly-entry.py").write_text("raise SystemExit('wrong checkout')\n")
        receipt = installer.install(self.source, self.destination, self.revision)
        self.assertEqual(receipt["revision"], self.revision)
        result = self.run_entry()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "fixture-compiler-ran")
        installer.install(self.source, self.destination, self.revision)
        self.assertEqual((self.destination / "current").resolve().name, self.revision)

    def test_unreviewed_revision_refused_without_replacing_current(self):
        installer.install(self.source, self.destination, self.revision)
        (self.payload / "nightly-entry.py").write_text("print('unreviewed')\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Fixture unreviewed compiler")
        with self.assertRaises(subprocess.CalledProcessError):
            installer.install(self.source, self.destination, self.git("rev-parse", "HEAD").strip())
        self.assertEqual((self.destination / "current").resolve().name, self.revision)

    def test_mutable_ref_is_refused_even_when_local_main_exists(self):
        for revision in ("refs/remotes/origin/main", "main", self.revision[:12], ""):
            with self.subTest(revision=revision), self.assertRaises(ValueError):
                installer.install(self.source, self.destination, revision)
        self.assertFalse((self.destination / "current").exists())

    def test_deploy_requires_explicit_revision_before_any_install(self):
        env = os.environ.copy()
        env.update(HOME=str(self.root / "empty-home"), TEAMKB_COMPILER_REPO=str(self.source))
        env.pop("TEAMKB_COMPILER_REVISION", None)
        result = subprocess.run(["bash", str(ROOT / "bin/deploy-teamkb-compile.sh"), "--compile-only"],
                                env=env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 64)
        self.assertIn("full reviewed compiler commit SHA", result.stderr)
        self.assertFalse((self.root / "empty-home").exists())

    def test_missing_file_refused_without_activation(self):
        (self.payload / "c8-mcp.py").unlink()
        self.git("add", ".")
        self.git("commit", "-qm", "Fixture incomplete compiler")
        revision = self.git("rev-parse", "HEAD").strip()
        self.git("update-ref", "refs/remotes/origin/main", revision)
        with self.assertRaises(subprocess.CalledProcessError):
            installer.install(self.source, self.destination, revision)
        self.assertFalse((self.destination / "current").exists())

    def test_runtime_drift_is_refused_before_compiler_exec(self):
        installer.install(self.source, self.destination, self.revision)
        (self.destination / "current/nightly-entry.py").write_text("print('untrusted')\n")
        result = self.run_entry()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("untrusted", result.stdout)
        with self.assertRaises(ValueError):
            installer.install(self.source, self.destination, self.revision)

    def test_malformed_manifest_returns_sanitized_unavailable_status(self):
        installer.install(self.source, self.destination, self.revision)
        manifest = self.destination / "current/manifest.json"
        data = json.loads(manifest.read_text())
        data["sha256"] = list(installer.FILES)
        manifest.write_text(json.dumps(data))
        result = self.run_entry()
        self.assertEqual(result.returncode, 69)
        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_upgrade_retains_previous_bundle_for_rollback(self):
        installer.install(self.source, self.destination, self.revision)
        (self.payload / "nightly-entry.py").write_text("print('second-compiler')\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Fixture reviewed upgrade")
        revision = self.git("rev-parse", "HEAD").strip()
        self.git("update-ref", "refs/remotes/origin/main", revision)
        installer.install(self.source, self.destination, revision)
        self.assertEqual((self.destination / "previous").resolve().name, self.revision)
        rollback = self.destination / "rollback-link"
        rollback.symlink_to((self.destination / "previous").resolve())
        os.replace(rollback, self.destination / "current")
        self.assertEqual(self.run_entry().stdout.strip(), "fixture-compiler-ran")

    def test_compile_only_deploy_preserves_audit_and_unrelated_runtimes(self):
        home = self.root / "home"
        audit = home / ".claude/skills/teamkb-compile/methodology/decisions.jsonl"
        audit.parent.mkdir(parents=True)
        audit.write_text('{"date":"fixture-preserved"}\n')
        (home / "bin").mkdir()
        for name in ("teamkb-backup.sh", "teamkb-quality-digest.sh"):
            (home / "bin" / name).write_text("existing runtime fixture\n")
        env = os.environ.copy()
        env.update(HOME=str(home), TEAMKB_COMPILER_REPO=str(self.source), TEAMKB_COMPILER_REVISION=self.revision)
        result = subprocess.run(["bash", str(ROOT / "bin/deploy-teamkb-compile.sh"), "--compile-only"],
                                env=env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(audit.read_text(), '{"date":"fixture-preserved"}\n')
        for name in ("teamkb-backup.sh", "teamkb-quality-digest.sh"):
            self.assertEqual((home / "bin" / name).read_text(), "existing runtime fixture\n")
        result = subprocess.run(["bash", str(home / "bin/teamkb-compile-daily.sh")], env=env,
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "fixture-compiler-ran")


if __name__ == "__main__":
    unittest.main()
