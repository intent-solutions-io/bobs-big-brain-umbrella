#!/usr/bin/env bash
# Runtime lock regression now exercises the owning compiler in its CI suite:
# scripts/distiller/test_nightly_compile.py::test_compile_lock_never_takes_brain_writer_lock.
# This repo verifies that deployment reaches exactly that owner and fails on drift.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$ROOT/scripts/test-compile-install.py" -v
