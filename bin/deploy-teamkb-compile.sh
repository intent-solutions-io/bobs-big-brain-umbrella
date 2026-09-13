#!/usr/bin/env bash
# Deploy the reviewed teamkb runtime scripts (this repo == source of truth) to
# their runtime locations. The repo copy under bin/ is CANONICAL; ~/bin holds
# deploy artifacts, never hand-edited (Track 0, bead compile-then-govern-6ps.1 —
# a bash test must exercise the copy cron/systemd actually runs).
#   .claude/skills/teamkb-compile/  ->  ~/.claude/skills/teamkb-compile/
#   .claude/skills/teamkb-review/   ->  ~/.claude/skills/teamkb-review/   (jfv.8 / 014-AT-DECR)
#   bin/teamkb-compile-daily.sh     ->  ~/bin/teamkb-compile-daily.sh   (cron 03:30)
#   bin/teamkb-quality-digest.sh    ->  ~/bin/teamkb-quality-digest.sh  (nightly govern-quality canary)
#   bin/teamkb-backup.sh            ->  ~/bin/teamkb-backup.sh          (teamkb-backup.service 04:30)
#
# The runtime-local methodology/decisions.jsonl audit log is PRESERVED (never
# overwritten by the repo's empty template). Idempotent. Run after merge.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILE_ONLY=0
case "${1:-}" in
  '') ;;
  --compile-only) COMPILE_ONLY=1 ;;
  *) printf '%s\n' 'Usage: deploy-teamkb-compile.sh [--compile-only]' >&2; exit 64 ;;
esac
COMPILER_REPO="${TEAMKB_COMPILER_REPO:-$HOME/000-projects/bobs-big-brain-compiler}"
COMPILER_RELEASES="$HOME/.local/lib/teamkb-compile"
# An explicitly selected release cannot silently resolve to a stale tracking ref.
if [[ ! "${TEAMKB_COMPILER_REVISION:-}" =~ ^[a-f0-9]{40}$ ]]; then
  printf '%s\n' 'TEAMKB_COMPILER_REVISION must name the full reviewed compiler commit SHA' >&2
  exit 64
fi
SKILL_SRC="$REPO_DIR/.claude/skills/teamkb-compile"
SKILL_DST="$HOME/.claude/skills/teamkb-compile"
REVIEW_SRC="$REPO_DIR/.claude/skills/teamkb-review"
REVIEW_DST="$HOME/.claude/skills/teamkb-review"
WRAP_SRC="$REPO_DIR/bin/teamkb-compile-daily.sh"
WRAP_DST="$HOME/bin/teamkb-compile-daily.sh"
DIGEST_SRC="$REPO_DIR/bin/teamkb-quality-digest.sh"
DIGEST_DST="$HOME/bin/teamkb-quality-digest.sh"
BACKUP_SRC="$REPO_DIR/bin/teamkb-backup.sh"
BACKUP_DST="$HOME/bin/teamkb-backup.sh"

mkdir -p "$SKILL_DST" "$REVIEW_DST" "$HOME/bin"
# Cron opens the `>> .../cron.log` redirect BEFORE the wrapper runs, so the state
# dir must exist on a fresh install or the very first cron tick fails silently.
mkdir -p "$HOME/.local/state/teamkb-compile-daily"
umask 077
BACKUP_DIR="$(mktemp -d "$HOME/.local/state/teamkb-compile-daily/deploy-$(date -u +%Y%m%dT%H%M%SZ).XXXXXXXX")"
if [[ -d "$SKILL_DST" ]]; then
  tar -czf "$BACKUP_DIR/compile-skill-before.tar.gz" -C "$SKILL_DST" .
fi
if [[ "$COMPILE_ONLY" = 0 && -d "$REVIEW_DST" ]]; then
  tar -czf "$BACKUP_DIR/review-skill-before.tar.gz" -C "$REVIEW_DST" .
fi
# Resolve files from reviewed Git objects, never the compiler's mutable checkout.
python3 "$REPO_DIR/bin/install-teamkb-compiler.py" --source "$COMPILER_REPO" \
  --destination "$COMPILER_RELEASES" --revision "${TEAMKB_COMPILER_REVISION}"

# Sync the compile skill, but never clobber the runtime audit log.
rsync -a --delete \
  --exclude 'methodology/decisions.jsonl' \
  --exclude 'methodology/index.db' \
  "$SKILL_SRC/" "$SKILL_DST/"
# Seed an empty audit log on first deploy only.
[ -f "$SKILL_DST/methodology/decisions.jsonl" ] || : > "$SKILL_DST/methodology/decisions.jsonl"

# Sync the review skill (no runtime-local state to preserve).
if [[ "$COMPILE_ONLY" = 0 ]]; then
  rsync -a --delete "$REVIEW_SRC/" "$REVIEW_DST/"
fi

if [[ -f "$WRAP_DST" ]] && ! cmp -s "$WRAP_SRC" "$WRAP_DST"; then
  install -m 0700 "$WRAP_DST" "$HOME/.local/state/teamkb-compile-daily/wrapper-before-$(date -u +%Y%m%dT%H%M%SZ).sh"
fi
install -m 0755 "$WRAP_SRC" "$WRAP_DST.new"
mv -f "$WRAP_DST.new" "$WRAP_DST"
if [[ "$COMPILE_ONLY" = 0 ]]; then
  install -m 0755 "$DIGEST_SRC" "$DIGEST_DST"
  install -m 0755 "$BACKUP_SRC" "$BACKUP_DST"
fi
chmod +x "$SKILL_DST/scripts/gather-signals.sh" "$SKILL_DST/scripts/scan-session-transcripts.py" 2>/dev/null || true

echo "Deployed:"
echo "  compile skill  -> $SKILL_DST"
echo "  compile wrapper-> $WRAP_DST"
echo "  private backup -> $BACKUP_DIR"
if [[ "$COMPILE_ONLY" = 0 ]]; then
  echo "  review skill   -> $REVIEW_DST"
  echo "  quality digest -> $DIGEST_DST"
  echo "  backup script  -> $BACKUP_DST"
else
  echo "  review skill, quality digest and backup script left unchanged (--compile-only)"
fi
echo "Crontab (install once): 30 3 * * * $WRAP_DST >> \$HOME/.local/state/teamkb-compile-daily/cron.log 2>&1"
