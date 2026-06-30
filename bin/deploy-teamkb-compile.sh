#!/usr/bin/env bash
# Deploy the reviewed /teamkb-compile source (this repo) to its runtime locations.
#   .claude/skills/teamkb-compile/  ->  ~/.claude/skills/teamkb-compile/
#   bin/teamkb-compile-daily.sh     ->  ~/bin/teamkb-compile-daily.sh
#
# The runtime-local methodology/decisions.jsonl audit log is PRESERVED (never
# overwritten by the repo's empty template). Idempotent. Run after merge.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SRC="$REPO_DIR/.claude/skills/teamkb-compile"
SKILL_DST="$HOME/.claude/skills/teamkb-compile"
WRAP_SRC="$REPO_DIR/bin/teamkb-compile-daily.sh"
WRAP_DST="$HOME/bin/teamkb-compile-daily.sh"

mkdir -p "$SKILL_DST" "$HOME/bin"

# Sync the skill, but never clobber the runtime audit log.
rsync -a --delete \
  --exclude 'methodology/decisions.jsonl' \
  --exclude 'methodology/index.db' \
  "$SKILL_SRC/" "$SKILL_DST/"
# Seed an empty audit log on first deploy only.
[ -f "$SKILL_DST/methodology/decisions.jsonl" ] || : > "$SKILL_DST/methodology/decisions.jsonl"

install -m 0755 "$WRAP_SRC" "$WRAP_DST"
chmod +x "$SKILL_DST/scripts/gather-signals.sh" "$SKILL_DST/scripts/scan-session-transcripts.py" 2>/dev/null || true

echo "Deployed:"
echo "  skill   -> $SKILL_DST"
echo "  wrapper -> $WRAP_DST"
echo "Crontab (install once): 30 3 * * * $WRAP_DST >> \$HOME/.local/state/teamkb-compile-daily/cron.log 2>&1"
