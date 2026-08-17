#!/usr/bin/env python3
"""Render every fenced Mermaid block in Markdown through the local mmdc."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUPPETEER_CONFIG = ROOT / "scripts" / "mermaid-puppeteer.json"
BLOCK = re.compile(r"^```mermaid\s*\n(.*?)^```\s*$", re.MULTILINE | re.DOTALL)


def newest_playwright_chrome() -> Path | None:
    override = os.environ.get("PUPPETEER_EXECUTABLE_PATH")
    if override:
        path = Path(override).expanduser()
        return path if path.is_file() and os.access(path, os.X_OK) else None

    cache = Path.home() / ".cache" / "ms-playwright"
    candidates = [
        path
        for path in cache.glob("chromium-*/**/chrome")
        if path.is_file() and os.access(path, os.X_OK)
    ]
    def build_number(path: Path) -> int:
        for part in path.parts:
            if part.startswith("chromium-"):
                suffix = part.removeprefix("chromium-")
                return int(suffix) if suffix.isdigit() else 0
        return 0

    return max(candidates, key=lambda path: (build_number(path), str(path))) if candidates else None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("documents", nargs="+", type=Path)
    parser.add_argument("--output-dir", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    mmdc = shutil.which("mmdc")
    chrome = newest_playwright_chrome()
    if mmdc is None:
        print("render-mermaid: mmdc is not installed", file=sys.stderr)
        return 2
    if chrome is None:
        print(
            "render-mermaid: Playwright Chromium not found; run `npx playwright install chromium`",
            file=sys.stderr,
        )
        return 2

    output_dir = args.output_dir or Path(tempfile.mkdtemp(prefix="bbb-mermaid-"))
    output_dir.mkdir(parents=True, exist_ok=True)
    env = {**os.environ, "PUPPETEER_EXECUTABLE_PATH": str(chrome)}
    rendered = 0

    for document in args.documents:
        if not document.is_file():
            print(f"render-mermaid: missing document: {document}", file=sys.stderr)
            return 2
        blocks = BLOCK.findall(document.read_text(encoding="utf-8"))
        if not blocks:
            print(f"render-mermaid: no Mermaid blocks in {document}", file=sys.stderr)
            return 1
        safe_stem = re.sub(r"[^a-zA-Z0-9_.-]+", "-", str(document.with_suffix("")))
        for index, source in enumerate(blocks, start=1):
            input_path = output_dir / f"{safe_stem}-{index}.mmd"
            output_path = output_dir / f"{safe_stem}-{index}.svg"
            input_path.write_text(source.rstrip() + "\n", encoding="utf-8")
            result = subprocess.run(
                [
                    mmdc,
                    "-p",
                    str(PUPPETEER_CONFIG),
                    "-i",
                    str(input_path),
                    "-o",
                    str(output_path),
                ],
                env=env,
                text=True,
            )
            if result.returncode != 0 or not output_path.is_file() or output_path.stat().st_size == 0:
                print(
                    f"render-mermaid: FAIL {document} block {index}; source={input_path}",
                    file=sys.stderr,
                )
                return 1
            rendered += 1
            print(f"render-mermaid: PASS {document} block {index} -> {output_path}")

    print(f"render-mermaid: {rendered} block(s) rendered; output={output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
