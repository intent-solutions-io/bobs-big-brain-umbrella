#!/usr/bin/env bash
# Regression proof: the compile wrapper owns .compile.lock while brain writers
# own .write.lock. Reusing one file self-deadlocks auto-mode brain_govern.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="$ROOT/bin/teamkb-compile-daily.sh"

command -v flock >/dev/null 2>&1 || {
  echo "SKIP: flock is unavailable"
  exit 0
}

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
test_home="$test_root/home"
teamkb_home="$test_home/.teamkb"
skill_dir="$test_home/.claude/skills/teamkb-compile"
mkdir -p "$skill_dir/scripts" "$skill_dir/methodology" "$teamkb_home"
: > "$skill_dir/scripts/brain-mcp-config.json"
: > "$skill_dir/methodology/decisions.jsonl"

run_wrapper() {
  HOME="$test_home" \
    TEAMKB_HOME="$teamkb_home" \
    TEAMKB_COMPILE_MODE=digest \
    TEAMKB_COMPILE_DRYRUN=1 \
    TEAMKB_LOCK_WAIT=0 \
    TEAMKB_COMPILE_DATE=2026-08-17 \
    bash "$WRAPPER"
}

# A normal dry run must use only the run-level compile lock.
run_wrapper >/dev/null
test -f "$teamkb_home/.compile.lock"
test ! -e "$teamkb_home/.write.lock"

# A second wrapper must skip, rather than queue, while .compile.lock is held.
exec 8>"$teamkb_home/.compile.lock"
flock -n 8
skip_output="$(run_wrapper)"
grep -q 'skipping this compile run' <<<"$skip_output"

# The child brain writer must still be able to acquire its independent lock.
flock -n "$teamkb_home/.write.lock" -c true
exec 8>&-

echo "PASS: compile and brain-writer locks remain independent"
