#!/usr/bin/env bash
# Hermetic proof for the TeamKB full-brain backup Buzz migration.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/bin/teamkb-backup.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0

pass() {
  printf 'PASS: %s\n' "$*"
  PASS=$((PASS + 1))
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  FAIL=$((FAIL + 1))
}

assert_file() {
  local path="$1" label="$2"
  [[ -e "$path" ]] && pass "$label" || fail "$label (missing $path)"
}

assert_not_file() {
  local path="$1" label="$2"
  [[ ! -e "$path" ]] && pass "$label" || fail "$label (unexpected $path)"
}

assert_contains() {
  local needle="$1" path="$2" label="$3"
  grep -Fq -- "$needle" "$path" && pass "$label" || fail "$label (missing '$needle')"
}

for token in notify-lib intent-runtime cron_fail ntfy slack_post hooks.slack.com buzz-notify.sh; do
  if grep -Fqi -- "$token" "$SCRIPT"; then
    fail "canonical source contains retired reach: $token"
  fi
done
[[ "$FAIL" -eq 0 ]] && pass 'canonical source has no retired delivery or liveness reach'

make_case() {
  local name="$1"
  CASE="$TMP/$name"
  HOME_DIR="$CASE/home"
  TEAMKB_HOME="$CASE/teamkb"
  DB="$TEAMKB_HOME/teamkb.db"
  ICO_DB="$TEAMKB_HOME/brain/.ico/state.db"
  BACKUP_DIR="$CASE/backups"
  LOG_DIR="$CASE/log"
  LIVENESS_DIR="$CASE/liveness"
  FAKEBIN="$CASE/bin"
  AF_LOG="$CASE/af.log"
  mkdir -p "$HOME_DIR" "$TEAMKB_HOME/brain/.ico" "$TEAMKB_HOME/brain/raw" \
    "$TEAMKB_HOME/brain/audit" "$TEAMKB_HOME/spool" \
    "$TEAMKB_HOME/audit" "$TEAMKB_HOME/brain/wiki" "$TEAMKB_HOME/feedback" \
    "$FAKEBIN"
  : > "$DB"
  : > "$ICO_DB"
  printf 'source\n' > "$TEAMKB_HOME/brain/raw/source.md"
  printf 'receipt\n' > "$TEAMKB_HOME/brain/audit/log.md"
  printf 'spool\n' > "$TEAMKB_HOME/spool/item.jsonl"
  printf '{"anchor":1}\n' > "$TEAMKB_HOME/audit/anchors.jsonl"
  printf 'wiki\n' > "$TEAMKB_HOME/brain/wiki/index.md"
  printf 'feedback\n' > "$TEAMKB_HOME/feedback/item.jsonl"
  printf '{"token":"hashed"}\n' > "$TEAMKB_HOME/tokens.json"
  printf 'age-key\n' > "$CASE/age.key"

  cat > "$FAKEBIN/sqlite3" <<'EOF'
#!/usr/bin/env bash
set -u
sql="${2-}"
if [[ "${FAKE_SQLITE_MODE:-ok}" == fail ]]; then
  exit 7
fi
if [[ "$sql" == VACUUM\ INTO\ * ]]; then
  output="${sql#VACUUM INTO }"
  output="${output#\'}"
  output="${output%\'}"
  mkdir -p "$(dirname "$output")"
  printf 'sqlite-snapshot\n' > "$output"
  exit 0
fi
case "$sql" in
  'PRAGMA integrity_check;'*) printf 'ok\n' ;;
  *'count(*) FROM sqlite_master'*) printf '3\n' ;;
  *) exit 8 ;;
esac
EOF

  cat > "$FAKEBIN/age" <<'EOF'
#!/usr/bin/env bash
set -u
if [[ "${FAKE_AGE_MODE:-ok}" == fail && "$*" == *' -d '* ]]; then
  exit 7
fi
output=''
input=''
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o) output="${2-}"; shift 2 ;;
    -i|-r) shift 2 ;;
    -d) shift ;;
    *) input="$1"; shift ;;
  esac
done
[[ -n "$output" && -n "$input" ]] || exit 8
cp -f -- "$input" "$output"
EOF

  cat > "$FAKEBIN/tar" <<'EOF'
#!/usr/bin/env bash
set -u
archive=''
destination=''
mode=''
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -cf) mode=create; archive="${2-}"; shift 2 ;;
    -xf) mode=extract; archive="${2-}"; shift 2 ;;
    -C) destination="${2-}"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ "$mode" == create ]]; then
  printf 'archive\n' > "$archive"
  exit 0
fi
[[ "$mode" == extract && -f "$archive" && -n "$destination" ]] || exit 8
mkdir -p "$destination/dbs" "$destination/brain/raw" "$destination/brain/audit" "$destination/audit"
: > "$destination/dbs/teamkb.db"
: > "$destination/dbs/ico-state.db"
if [[ "${FAKE_TAR_MODE:-ok}" != corrupt ]]; then
  printf 'source\n' > "$destination/brain/raw/source.md"
  printf 'receipt\n' > "$destination/brain/audit/log.md"
  printf '{"anchor":1}\n' > "$destination/audit/anchors.jsonl"
  printf '{"token":"hashed"}\n' > "$destination/tokens.json"
fi
EOF

  cat > "$FAKEBIN/rsync" <<'EOF'
#!/usr/bin/env bash
set -u
args="$*"
if [[ "$args" == *' -e '* || "$args" == '-e '* ]] && [[ "${FAKE_RSYNC_MODE:-ok}" == fail ]]; then
  exit 7
fi
if [[ "$args" == *' -e '* || "$args" == '-e '* ]]; then
  exit 0
fi
src="${@: -2:1}"
dest="${@: -1}"
src="${src%/}"
dest="${dest%/}"
mkdir -p "$dest"
cp -a "$src"/. "$dest"/
EOF

  cat > "$FAKEBIN/flock" <<'EOF'
#!/usr/bin/env bash
set -u
if [[ "${FAKE_FLOCK_MODE:-ok}" == fail ]]; then
  exit 1
fi
exec /usr/bin/flock "$@"
EOF

  cat > "$FAKEBIN/ssh" <<'EOF'
#!/usr/bin/env bash
set -u
printf 'ssh %s\n' "$*" >> "${FAKE_SSH_LOG:?}"
if [[ "${FAKE_SSH_MODE:-ok}" == fail ]]; then
  exit 7
fi
exit 0
EOF

  cat > "$FAKEBIN/alert-floor.sh" <<'EOF'
#!/usr/bin/env bash
set -u
printf 'mode=%s normalize=%s topic=%s raw=%s fallback=%s severity=%s\n' \
  "${FAKE_AF_MODE:-delivered}" "${AF_LLM_NORMALIZE:-}" "${5-}" "${2-}" "${3-}" "${4-}" >> "${FAKE_AF_LOG:?}"
case "${FAKE_AF_MODE:-delivered}" in
  delivered) printf 'af_dispatch: status=delivered topic=%s\n' "${5-}"; exit 0 ;;
  dedup) printf 'af_dispatch: status=dedup_suppressed topic=%s\n' "${5-}"; exit 5 ;;
  fail) printf 'af_dispatch: status=failed topic=%s\n' "${5-}"; exit 3 ;;
  *) exit 9 ;;
esac
EOF

  cat > "$FAKEBIN/zstd" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  cat > "$CASE/systemmap.sh" <<'EOF'
#!/usr/bin/env bash
printf 'systemmap refreshed\n' >> "${SYSTEMMAP_LOG:?}"
EOF

  chmod 700 "$FAKEBIN"/* "$CASE/systemmap.sh"
  FAKE_AF_MODE=delivered
  FAKE_AGE_MODE=ok
  FAKE_FLOCK_MODE=ok
  FAKE_RSYNC_MODE=ok
  FAKE_SQLITE_MODE=ok
  FAKE_TAR_MODE=ok
  FAKE_SSH_MODE=ok
  TEST_VPS_REMOTE=''
}

run_backup() {
  env \
    HOME="$HOME_DIR" \
    TEAMKB_HOME="$TEAMKB_HOME" \
    TEAMKB_DB="$DB" \
    TEAMKB_ICO_DB="$ICO_DB" \
    TEAMKB_BACKUP_DIR="$BACKUP_DIR" \
    TEAMKB_BACKUP_LOGDIR="$LOG_DIR" \
    TEAMKB_AGE_RECIPIENT=local \
    TEAMKB_AGE_RECIPIENT_VPS=vps \
    SOPS_AGE_KEY_FILE="$CASE/age.key" \
    AGE_BIN="$FAKEBIN/age" \
    TEAMKB_R2_REMOTE='' \
    TEAMKB_VPS_REMOTE="$TEST_VPS_REMOTE" \
    TEAMKB_SYSTEMMAP="$CASE/systemmap.sh" \
    AF_NOTIFY_ALERT_FLOOR="$FAKEBIN/alert-floor.sh" \
    INTENT_OS_LIVENESS_DIR="$LIVENESS_DIR" \
    FAKE_AF_MODE="$FAKE_AF_MODE" \
    FAKE_AF_LOG="$AF_LOG" \
    FAKE_AGE_MODE="$FAKE_AGE_MODE" \
    FAKE_FLOCK_MODE="$FAKE_FLOCK_MODE" \
    FAKE_RSYNC_MODE="$FAKE_RSYNC_MODE" \
    FAKE_SQLITE_MODE="$FAKE_SQLITE_MODE" \
    FAKE_TAR_MODE="$FAKE_TAR_MODE" \
    FAKE_SSH_MODE="$FAKE_SSH_MODE" \
    FAKE_SSH_LOG="$CASE/ssh.log" \
    SYSTEMMAP_LOG="$CASE/systemmap.log" \
    PATH="$FAKEBIN:$PATH" \
    bash "$SCRIPT"
}

make_case success
if run_backup; then
  pass 'verified local backup completes'
else
  fail 'verified local backup completes'
fi
compgen -G "$BACKUP_DIR/teamkb-full-*.tar.zst.age" >/dev/null && pass 'encrypted backup artifact exists' || fail 'encrypted backup artifact exists'
assert_file "$LIVENESS_DIR/teamkb-backup.beat" 'success writes beat'
assert_file "$LIVENESS_DIR/teamkb-backup.ok" 'success writes .ok only after restore'
assert_not_file "$LIVENESS_DIR/teamkb-backup.skipped" 'success clears skipped marker'
assert_contains 'restore round-trip OK' "$LOG_DIR/backup.log" 'restore proof is logged'
assert_contains 'systemmap refreshed' "$CASE/systemmap.log" 'post-restore system map hook remains'

make_case lock-skip
FAKE_FLOCK_MODE=fail
if run_backup >/dev/null; then
  pass 'lock contention exits gracefully'
else
  fail 'lock contention exits gracefully'
fi
assert_file "$LIVENESS_DIR/teamkb-backup.beat" 'lock skip writes beat'
assert_file "$LIVENESS_DIR/teamkb-backup.skipped" 'lock skip writes explicit skipped marker'
assert_not_file "$LIVENESS_DIR/teamkb-backup.ok" 'lock skip never creates false .ok'
if compgen -G "$BACKUP_DIR/teamkb-full-*.tar.zst.age" >/dev/null; then
  fail 'lock skip creates no archive'
else
  pass 'lock skip creates no archive'
fi

make_case missing-db
DB="$TEAMKB_HOME/missing.db"
if run_backup >/dev/null; then
  fail 'missing DB fails closed'
else
  pass 'missing DB fails closed'
fi
assert_file "$LIVENESS_DIR/teamkb-backup.beat" 'fatal preflight writes beat'
assert_not_file "$LIVENESS_DIR/teamkb-backup.ok" 'fatal preflight withholds .ok'
assert_contains 'topic=sys-backups' "$AF_LOG" 'fatal path uses governed sys-backups topic'
assert_contains 'normalize=1' "$AF_LOG" 'fatal path requests MiniMax normalization'

make_case restore-failure
FAKE_TAR_MODE=corrupt
if run_backup >/dev/null; then
  fail 'restore failure is non-zero'
else
  pass 'restore failure is non-zero'
fi
assert_not_file "$LIVENESS_DIR/teamkb-backup.ok" 'restore failure withholds .ok'
assert_contains 'restore round-trip failed' "$AF_LOG" 'restore failure is presented through governed dispatch'

make_case dispatch-failure
DB="$TEAMKB_HOME/missing.db"
FAKE_AF_MODE=fail
if run_backup >/dev/null; then
  fail 'missing DB remains non-zero when alert delivery fails'
else
  pass 'missing DB remains non-zero when alert delivery fails'
fi
assert_not_file "$LIVENESS_DIR/teamkb-backup.ok" 'failed alert receipt withholds .ok'
assert_contains 'mode=fail' "$AF_LOG" 'failed alert receipt remains visible'

make_case marker-failure
mkdir -p "$LIVENESS_DIR/teamkb-backup.ok"
if run_backup >/dev/null; then
  fail 'marker failure is non-zero'
else
  pass 'marker failure is non-zero'
fi
assert_file "$LIVENESS_DIR/teamkb-backup.beat" 'marker failure preserves beat'
assert_contains 'success marker write failed' "$AF_LOG" 'marker failure is governed'

make_case offhost-failure
TEST_VPS_REMOTE='fake-vps:/backups'
FAKE_RSYNC_MODE=fail
if run_backup >/dev/null; then
  pass 'off-host push failure retains a verified local backup'
else
  fail 'off-host push failure retains a verified local backup'
fi
assert_file "$LIVENESS_DIR/teamkb-backup.ok" 'off-host failure does not erase local restore success'
assert_contains 'off-host push failed' "$AF_LOG" 'off-host failure is alerted through governed dispatch'
assert_contains 'topic=sys-backups' "$AF_LOG" 'off-host alert stays on sys-backups'

printf 'Focused checks: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
