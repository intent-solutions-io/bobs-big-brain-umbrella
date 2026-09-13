#!/usr/bin/env bash
# Installed entry only. The compiler owns implementation; deployment installs a
# reviewed commit-addressed, hash-verified bundle so an unrelated repo checkout cannot change cron.
set -euo pipefail
export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
RELEASE="${TEAMKB_COMPILE_RELEASE:-$HOME/.local/lib/teamkb-compile/current}"
if [[ ! -f "$RELEASE/manifest.json" || ! -f "$RELEASE/nightly-entry.py" ]]; then
  printf '%s\n' 'teamkb-compile: reviewed compiler bundle missing; run deploy-teamkb-compile.sh --compile-only' >&2
  exit 69
fi
python3 - "$RELEASE" <<'PY_VERIFY'
import hashlib
import json
from pathlib import Path
import re
import sys
try:
    root = Path(sys.argv[1]).resolve(strict=True)
    manifest = json.loads((root / 'manifest.json').read_text())
    if not re.fullmatch(r'[a-f0-9]{40}', manifest['revision']):
        raise ValueError('revision')
    expected = {'nightly-entry.py', 'runtime-proof.py', 'c8-mcp.py', 'teamkb-compile-daily.sh', 'eval-distiller-output.mjs'}
    if not isinstance(manifest['sha256'], dict) or set(manifest['sha256']) != expected:
        raise ValueError('bundle files')
    for name, digest in manifest['sha256'].items():
        if hashlib.sha256((root / name).read_bytes()).hexdigest() != digest:
            raise ValueError('bundle drift')
except (OSError, ValueError, KeyError, TypeError):
    print('teamkb-compile: compiler bundle verification failed', file=sys.stderr)
    raise SystemExit(69) from None
PY_VERIFY
exec python3 "$RELEASE/nightly-entry.py" "$@"
