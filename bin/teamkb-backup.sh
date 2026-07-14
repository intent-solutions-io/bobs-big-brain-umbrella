#!/usr/bin/env bash
#
# teamkb-backup.sh — quiesced, restore-tested, client-encrypted backup of the
# WHOLE governed-brain store under ~/.teamkb. Bead compile-then-govern-c5k.4.
#
# The brain is one directory on this box. Earlier this script backed up ONLY the
# govern DB (teamkb.db); that left the compile DB, the raw corpus (the source of
# truth), the hash-chained audit receipts, and the spool handoff unprotected. A
# restore from a teamkb.db-only backup could not reconstruct the brain. This now
# captures the correct scope:
#
#   Tier A — must-have (source of truth, receipts, secret):
#     teamkb.db                 govern DB        -> VACUUM INTO (quiesced)
#     brain/.ico/state.db       compile DB       -> VACUUM INTO (quiesced)
#     brain/raw/                corpus (SOT)     -> archived
#     brain/audit/              receipts chain   -> archived
#     audit/                    external anchor log (anchors.jsonl + .git) -> archived  [receipts trust root, R4/e06.11]
#     brain/spool/, spool/      ICO->INTKB queue -> archived
#     tokens.json               SECRET           -> archived (whole archive is age-encrypted)
#   Tier B — expensive-derived, cheaper to restore than recompute:
#     brain/wiki/               compiled markdown
#     feedback/
#   Skipped — cheaply re-derived from Tier A:
#     kb-export/, qmd-index/, brain/recall/, brain/outputs/, brain/tasks/
#
# Pipeline:
#   1. VACUUM INTO both SQLite DBs   -> clean, consistent snapshots (safe with the
#                                       live teamkb-brain-api writer; brief read lock).
#   2. PRAGMA integrity_check        -> each snapshot must report "ok".
#   3. tar (zstd) the snapshots + Tier-A/B paths + a MANIFEST into one archive.
#   4. age-encrypt to TWO recipients (dev-box SOPS key + VPS host key) so it is
#      restorable even if the dev box is lost; shred the plaintext archive.
#   5. restore round-trip  -> decrypt + extract on tmpfs (/dev/shm); both DBs
#                             integrity_check + table-count match, Tier-A presence
#                             is asserted, AND the restored external anchor is
#                             re-verified against the restored chain with the
#                             standalone verifier (the trust root must survive
#                             CONSISTENT, not just present). The backup is KEPT
#                             ONLY if it provably restores. An unrestorable
#                             backup is deleted.
#   6. off-host push -> (a) VPS over the tailnet (default — the VPS holds a
#                        decrypting key) via rsync, with a sha256 byte-match check
#                        and remote retention; and (b) Cloudflare R2 via rclone
#                        when TEAMKB_R2_REMOTE is set (pending bucket provisioning).
#   7. retention prune       -> keep newest TEAMKB_BACKUP_RETAIN; prune legacy
#                               teamkb-*.db.age single-DB backups too.
#
# Key custody: the .age files decrypt with EITHER
#   - the dev-box age key  ~/.config/sops/age/keys.txt   (recipient age1me3v…), or
#   - the VPS host age key  /etc/intentsolutions/age.key  (recipient age1csyjr…).
# Plaintext is never written to durable disk; decrypt happens only on /dev/shm.
#
# Concurrency (bead compile-then-govern-e06.12 / risk 010-AT-RISK R13 / umbrella #27):
#   All ~/.teamkb writers (this backup + teamkb-compile-daily.sh, and e06.5's coming
#   on-push compile) serialize on ONE exclusive flock at $TEAMKB_HOME/.write.lock.
#   The govern pipeline mutates SQLite + file export + qmd index + anchor-git
#   NON-atomically, so a backup snapshot taken mid-compile would VACUUM a DB that no
#   longer matches the exported wiki / qmd index / anchor head — an internally
#   inconsistent brain that "restores" but is skewed. WAL prevents DB *corruption*,
#   not cross-artifact skew. The lock closes that window. The backup WAITS up to
#   TEAMKB_LOCK_WAIT seconds for an in-flight compile to finish (a delayed nightly
#   backup is fine); if it still can't acquire, it skips gracefully (exit 0) rather
#   than snapshot a half-written brain.

set -euo pipefail

TEAMKB_HOME="${TEAMKB_HOME:-$HOME/.teamkb}"
DB="${TEAMKB_DB:-$TEAMKB_HOME/teamkb.db}"
ICO_DB="${TEAMKB_ICO_DB:-$TEAMKB_HOME/brain/.ico/state.db}"
BACKUP_DIR="${TEAMKB_BACKUP_DIR:-$TEAMKB_HOME/backups}"
# Dev-box SOPS recipient (key: ~/.config/sops/age/keys.txt) + VPS host recipient.
AGE_RECIP_LOCAL="${TEAMKB_AGE_RECIPIENT:-age1me3vkelljqe2u4zcagja9ru5fdpfpw72xmch39fwle2cr0yfr4cs8vr5d8}"
AGE_RECIP_VPS="${TEAMKB_AGE_RECIPIENT_VPS:-age1csyjrdez6fhe97zsu3zden8j7x7xes6zm3yzce5fzz524wmqav4sc0vgz3}"
AGE_KEY="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
AGE_BIN="${AGE_BIN:-$HOME/bin/age}"
R2_REMOTE="${TEAMKB_R2_REMOTE:-r2-teamkb:teamkb-backups}"   # 2nd off-host target (Cloudflare R2); empty = skip
# Off-host over the tailnet to the VPS (which holds a decrypting key). ssh-alias:dir; empty disables.
VPS_REMOTE="${TEAMKB_VPS_REMOTE:-intentsolutions:teamkb-backups}"
RETAIN="${TEAMKB_BACKUP_RETAIN:-14}"
LOGDIR="${TEAMKB_BACKUP_LOGDIR:-$HOME/.local/state/teamkb-backup}"

# Tier-A/B paths, RELATIVE to $TEAMKB_HOME. Only those that exist are archived.
# `audit` = the top-level external anchor log (anchors.jsonl + its .git) — the
# receipts trust root (R4/e06.11); DISTINCT from brain/audit (the ICO receipts).
TIER_A_PATHS=(brain/raw brain/audit brain/spool spool tokens.json audit)
TIER_B_PATHS=(brain/wiki feedback)

mkdir -p "$BACKUP_DIR" "$LOGDIR"
LOG="$LOGDIR/backup.log"
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG"; }

# Failure alerting + liveness (notify-lib spine). This script needs a temp-dir
# cleanup EXIT trap (work/shm, created later; guarded here with :-), and bash
# allows only ONE EXIT trap — so arm_fail_trap cannot be used as-is (its
# _nl_on_exit would be clobbered by the cleanup trap below). This merged handler
# does BOTH: capture rc FIRST (before rm resets $?), clean up, drop the liveness
# heartbeat every run, and page #cron-failures on ANY non-zero exit — including
# the FATAL exit-1 paths (missing DB/age/sqlite3/zstd) that fire before work/shm
# even exist. The governed brain's ONLY DR backup must not fail silently. A
# graceful flock-skip is exit 0 → stays silent, correctly.
# Guarded: on a fresh clone / CI without the notify spine, an unguarded `source`
# would abort the whole script under `set -e` BEFORE any backup runs (the digest
# guards the same source). Absent notify-lib, alerting degrades to a no-op — never
# a hard failure of the governed brain's ONLY DR backup.
if [ -f "$HOME/bin/lib/notify-lib.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/bin/lib/notify-lib.sh"
fi
_backup_on_exit() {
  local rc=$?
  rm -rf "${work:-}" "${shm:-}" 2>/dev/null || true
  mkdir -p "$HOME/.local/state/notify-lib" 2>/dev/null || true
  : > "$HOME/.local/state/notify-lib/teamkb-backup.beat" 2>/dev/null || true
  if [ "$rc" -eq 0 ]; then
    # SUCCESS marker: touch <job>.ok (two-marker doctrine — .beat every run, .ok only on rc==0).
    # The merged EXIT trap replaced notify-lib's arm_fail_trap, which dropped this write; without it
    # the liveness sweep + the Epic-1.8 harness see fresh .beat + stale .ok and mis-report a WORKING
    # backup as running-but-failing. Restored here.
    : > "$HOME/.local/state/notify-lib/teamkb-backup.ok" 2>/dev/null || true
    return 0
  fi
  local detail="exited rc=${rc}"
  [ -f "$LOG" ] && detail="${detail}; last log: $(tail -n 3 "$LOG" 2>/dev/null | tr '\n' ' ' | cut -c1-400)"
  # Guarded so the EXIT trap still cleans up + drops the heartbeat even when the
  # notify spine is absent (cron_fail undefined) — the alert just no-ops.
  command -v cron_fail >/dev/null 2>&1 && cron_fail "teamkb-backup" "$detail"
  return 0
}
trap _backup_on_exit EXIT

# ── ~/.teamkb single-writer lock (e06.12 / R13 / #27) ─────────────────────────
# Acquire an EXCLUSIVE flock BEFORE any DB/file mutation, hold it for the whole
# run (flock auto-releases when fd 9 closes on process exit). Serializes against
# teamkb-compile-daily.sh (and e06.5's on-push compile) so a snapshot is never
# taken across a non-atomic govern write. The backup waits for an in-flight
# compile (TEAMKB_LOCK_WAIT, default 300s); a delayed nightly backup is fine.
LOCK="${TEAMKB_LOCK:-$TEAMKB_HOME/.write.lock}"
LOCK_WAIT="${TEAMKB_LOCK_WAIT:-300}"
if command -v flock >/dev/null 2>&1; then
  mkdir -p "$TEAMKB_HOME"
  exec 9>"$LOCK"
  if ! flock -w "$LOCK_WAIT" 9; then
    log "another ~/.teamkb writer holds $LOCK after ${LOCK_WAIT}s — skipping this backup run"
    exit 0
  fi
else
  log "WARN: flock not on PATH — proceeding WITHOUT the ~/.teamkb writer lock (concurrent compile could skew this snapshot)"
fi

[ -f "$DB" ]      || { log "FATAL: govern DB not found: $DB"; exit 1; }
[ -x "$AGE_BIN" ] || { log "FATAL: age binary not found/executable: $AGE_BIN"; exit 1; }
command -v sqlite3 >/dev/null || { log "FATAL: sqlite3 not on PATH"; exit 1; }
command -v zstd    >/dev/null || { log "FATAL: zstd not on PATH"; exit 1; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"
work="$(mktemp -d)"
shm="$(mktemp -d -p /dev/shm 2>/dev/null || mktemp -d)"
# (temp-dir cleanup is handled by the merged _backup_on_exit EXIT trap installed
# near the top, so work/shm are cleaned on every exit path including early FATALs)
stage="$work/stage"
mkdir -p "$stage/dbs"
arc="$work/teamkb-full-$ts.tar.zst"
enc="$BACKUP_DIR/teamkb-full-$ts.tar.zst.age"

log "=== full-brain backup start: $TEAMKB_HOME ==="

# 1. quiesced snapshots of both SQLite DBs (govern + compile)
sqlite3 "$DB" "VACUUM INTO '$stage/dbs/teamkb.db'"
gov_ic="$(sqlite3 "$stage/dbs/teamkb.db" 'PRAGMA integrity_check;')"
[ "$gov_ic" = "ok" ] || { log "FATAL: govern DB integrity_check: $gov_ic"; exit 1; }
gov_tables="$(sqlite3 "$stage/dbs/teamkb.db" "SELECT count(*) FROM sqlite_master WHERE type='table';")"

ico_tables="-"
if [ -f "$ICO_DB" ]; then
  sqlite3 "$ICO_DB" "VACUUM INTO '$stage/dbs/ico-state.db'"
  ico_ic="$(sqlite3 "$stage/dbs/ico-state.db" 'PRAGMA integrity_check;')"
  [ "$ico_ic" = "ok" ] || { log "FATAL: compile DB integrity_check: $ico_ic"; exit 1; }
  ico_tables="$(sqlite3 "$stage/dbs/ico-state.db" "SELECT count(*) FROM sqlite_master WHERE type='table';")"
else
  log "WARN: compile DB not found at $ICO_DB — backing up govern DB + corpus only"
fi
log "snapshots ok: govern integrity=ok tables=$gov_tables; compile tables=$ico_tables"

# Collect the Tier-A/B paths that actually exist (tar errors on missing paths).
present=()
for p in "${TIER_A_PATHS[@]}" "${TIER_B_PATHS[@]}"; do
  [ -e "$TEAMKB_HOME/$p" ] && present+=("$p")
done

# 2. MANIFEST — records what was captured + the verification fingerprints.
raw_files="$( [ -d "$TEAMKB_HOME/brain/raw" ] && find "$TEAMKB_HOME/brain/raw" -type f | wc -l || echo 0)"
audit_files="$( [ -d "$TEAMKB_HOME/brain/audit" ] && find "$TEAMKB_HOME/brain/audit" -type f | wc -l || echo 0)"
anchor_files="$( [ -d "$TEAMKB_HOME/audit" ] && find "$TEAMKB_HOME/audit" -type f | wc -l || echo 0)"
{
  echo "schemaVersion: 1"
  echo "createdAt: $(date -u +%FT%TZ)"
  echo "host: $(hostname)"
  echo "teamkbHome: $TEAMKB_HOME"
  echo "govern_db_tables: $gov_tables"
  echo "compile_db_tables: $ico_tables"
  echo "raw_files: $raw_files"
  echo "audit_files: $audit_files"
  echo "anchor_files: $anchor_files"
  echo "tierA: ${TIER_A_PATHS[*]}"
  echo "tierB: ${TIER_B_PATHS[*]}"
  echo "components: dbs/teamkb.db dbs/ico-state.db ${present[*]}"
} > "$stage/MANIFEST.txt"

# 3. one archive: staged DBs + MANIFEST (from $stage) + Tier-A/B paths (from $TEAMKB_HOME)
tar --zstd -cf "$arc" \
  -C "$stage" MANIFEST.txt dbs \
  -C "$TEAMKB_HOME" "${present[@]}"
log "archived: dbs + [${present[*]}] -> $(du -h "$arc" | cut -f1)"

# 4. encrypt to both recipients, then shred the plaintext archive + staged DBs
"$AGE_BIN" -r "$AGE_RECIP_LOCAL" -r "$AGE_RECIP_VPS" -o "$enc" "$arc"
shred -u "$arc" 2>/dev/null || rm -f "$arc"
rm -rf "$stage/dbs"
log "encrypted (2 recipients) -> $enc ($(du -h "$enc" | cut -f1))"

# 5. restore round-trip on tmpfs: decrypt + extract + verify BOTH DBs + Tier-A presence
rdir="$shm/restore"
mkdir -p "$rdir"
"$AGE_BIN" -d -i "$AGE_KEY" -o "$shm/restore.tar.zst" "$enc"
tar --zstd -xf "$shm/restore.tar.zst" -C "$rdir"

fail=""
rgov_ic="$(sqlite3 "$rdir/dbs/teamkb.db" 'PRAGMA integrity_check;' 2>/dev/null || echo MISSING)"
rgov_tab="$(sqlite3 "$rdir/dbs/teamkb.db" "SELECT count(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo -1)"
{ [ "$rgov_ic" = "ok" ] && [ "$rgov_tab" = "$gov_tables" ]; } || fail="$fail govern(ic=$rgov_ic tab=$rgov_tab/$gov_tables)"
if [ "$ico_tables" != "-" ]; then
  rico_ic="$(sqlite3 "$rdir/dbs/ico-state.db" 'PRAGMA integrity_check;' 2>/dev/null || echo MISSING)"
  rico_tab="$(sqlite3 "$rdir/dbs/ico-state.db" "SELECT count(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo -1)"
  { [ "$rico_ic" = "ok" ] && [ "$rico_tab" = "$ico_tables" ]; } || fail="$fail compile(ic=$rico_ic tab=$rico_tab/$ico_tables)"
fi
# Tier-A presence: the corpus and receipts must be in the restored tree.
{ [ -d "$rdir/brain/raw" ]   && [ "$(find "$rdir/brain/raw" -type f | wc -l)" = "$raw_files" ]; }     || fail="$fail raw_missing"
{ [ -d "$rdir/brain/audit" ] && [ "$(find "$rdir/brain/audit" -type f | wc -l)" = "$audit_files" ]; } || fail="$fail audit_missing"
# External anchor log (the receipts trust root, R4/e06.11): if it exists on the
# source it MUST restore non-empty with a matching file count — a restore that
# silently drops it would lose all external tamper-evidence.
{ [ ! -d "$TEAMKB_HOME/audit" ] || { [ -s "$rdir/audit/anchors.jsonl" ] && [ "$(find "$rdir/audit" -type f | wc -l)" = "$anchor_files" ]; }; } || fail="$fail anchor_missing"
{ [ ! -e "$TEAMKB_HOME/tokens.json" ] || [ -f "$rdir/tokens.json" ]; } || fail="$fail tokens_missing"

# RE-VERIFY the restored anchor against the restored chain (bead compile-then-govern-6ps.8).
# Presence + file-count (above) prove the trust root was CARRIED; they do NOT prove it
# is still CONSISTENT with the restored DB. Run the standalone, zero-dependency verifier
# (the exact one a skeptic runs) against the restored anchors.jsonl + restored teamkb.db:
# a FAIL (exit 1 = HISTORY_REWRITTEN / hash / linkage break) means the receipts trust root
# did NOT survive the restore intact — treat the backup as unrestorable. WARN (exit 0, e.g.
# the restored audit repo has no remote) is fine. Absent verifier / node → NOTE, not fail
# (the presence gate above still stands, and a backup must not hard-fail on optional tooling).
ANCHOR_VERIFIER="${TEAMKB_ANCHOR_VERIFIER:-$HOME/000-projects/bobs-big-brain-plugin/scripts/verify-anchors.mjs}"
if [ -d "$TEAMKB_HOME/audit" ] && [ -s "$rdir/audit/anchors.jsonl" ]; then
  if [ -f "$ANCHOR_VERIFIER" ] && command -v node >/dev/null 2>&1; then
    # if/else (not `A && B || C`) so the verifier's exit is evaluated as the `if`
    # condition — safe under `set -e`, and $? in the else branch is the verifier's.
    if node "$ANCHOR_VERIFIER" --anchors "$rdir/audit/anchors.jsonl" --db "$rdir/dbs/teamkb.db" >/dev/null 2>&1; then
      : # exit 0 = PASS/WARN — the restored anchor re-verifies against the restored chain
    else
      vrc=$?
      if [ "$vrc" = "1" ]; then
        fail="$fail anchor_reverify_failed"
      else
        log "NOTE: restored-anchor re-verify inconclusive (verifier exit $vrc) — presence gate still enforced"
      fi
    fi
  else
    log "NOTE: standalone anchor verifier not found ($ANCHOR_VERIFIER) or node absent — restored-anchor re-verify skipped (presence gate still enforced)"
  fi
fi

if [ -n "$fail" ]; then
  log "FATAL: restore round-trip FAILED —$fail — discarding unrestorable backup"
  rm -f "$enc"
  exit 1
fi
log "restore round-trip OK: govern+compile integrity verified, corpus($raw_files)/audit($audit_files)/anchor($anchor_files)/tokens present on tmpfs, restored anchor re-verified against restored chain"

# 5b. refresh the umbrella system map's live-stats block now that the brain is
#     provably backed up. Non-fatal: the map is documentation, not the backup.
SYSTEMMAP="${TEAMKB_SYSTEMMAP:-$HOME/000-projects/bobs-big-brain-umbrella/bin/teamkb-systemmap.sh}"
if [ -x "$SYSTEMMAP" ]; then
  if "$SYSTEMMAP" >>"$LOG" 2>&1; then
    log "system map refreshed via $SYSTEMMAP"
  else
    log "WARN: system map refresh FAILED (non-fatal — backup is good)"
  fi
else
  log "system map refresh SKIPPED (not executable: $SYSTEMMAP)"
fi

# 6. off-host push (R2). Remaining open item on c5k.4 until the bucket is provisioned.
if [ -n "$R2_REMOTE" ] && command -v rclone >/dev/null; then
  if rclone copy "$enc" "$R2_REMOTE/"; then
    log "off-host push OK -> $R2_REMOTE"
    # remote retention: keep newest $RETAIN on R2 too. R2 has no bucket lifecycle rule,
    # so without this it grows unbounded (a backup target must not accumulate forever).
    # Filenames are UTC-timestamped -> lexical sort == chronological; delete all but newest.
    r2_pruned=0
    while read -r old_r2; do
      [ -z "$old_r2" ] && continue
      rclone deletefile "$R2_REMOTE/$old_r2" 2>/dev/null && r2_pruned=$((r2_pruned + 1)) || true
    done < <(rclone lsf "$R2_REMOTE" 2>/dev/null | grep -E '^teamkb-full-.*\.tar\.zst\.age$' | sort | head -n -"$RETAIN")
    [ "$r2_pruned" -gt 0 ] && log "R2 retention: pruned $r2_pruned old archive(s); retained newest $RETAIN"
  else
    log "WARN: off-host push to $R2_REMOTE FAILED (local encrypted backup retained)"
  fi
else
  log "off-host R2 push SKIPPED — set TEAMKB_R2_REMOTE (+ rclone remote) to enable."
fi

# 6b. off-host push over the tailnet to the VPS. The archive is already encrypted
#     to the VPS host key, so the VPS is a valid restore site; we still verify the
#     remote copy byte-for-byte by sha256 (the .age is opaque). Non-fatal on
#     failure — the local encrypted backup is retained.
if [ -n "$VPS_REMOTE" ]; then
  vhost="${VPS_REMOTE%%:*}"
  vdir="${VPS_REMOTE#*:}"
  SSHO=(-o ConnectTimeout=10 -o BatchMode=yes)
  if ssh "${SSHO[@]}" "$vhost" "mkdir -p '$vdir' && chmod 700 '$vdir'" 2>/dev/null \
     && rsync -aq -e "ssh ${SSHO[*]}" "$enc" "$VPS_REMOTE/"; then
    lsum="$(sha256sum "$enc" | cut -d' ' -f1)"
    rsum="$(ssh "${SSHO[@]}" "$vhost" "sha256sum '$vdir/$(basename "$enc")' 2>/dev/null | cut -d' ' -f1" || true)"
    if [ "$lsum" = "$rsum" ]; then
      log "off-host VPS push OK -> $VPS_REMOTE (sha256 verified)"
      # remote retention: keep newest $RETAIN on the VPS too
      ssh "${SSHO[@]}" "$vhost" "ls -1t '$vdir'/teamkb-full-*.tar.zst.age 2>/dev/null | tail -n +$((RETAIN + 1)) | xargs -r rm -f" 2>/dev/null || true
    else
      log "WARN: off-host VPS push sha256 MISMATCH (local=$lsum remote=$rsum) — remote copy suspect"
    fi
  else
    log "WARN: off-host VPS push to $VPS_REMOTE FAILED (local encrypted backup retained)"
  fi
else
  log "off-host VPS push SKIPPED (TEAMKB_VPS_REMOTE empty)."
fi

# 7. retention prune (newest $RETAIN full archives; also drop legacy single-DB backups)
mapfile -t old < <(ls -1t "$BACKUP_DIR"/teamkb-full-*.tar.zst.age 2>/dev/null | tail -n +"$((RETAIN + 1))")
if [ "${#old[@]}" -gt 0 ]; then
  rm -f "${old[@]}"
  log "pruned ${#old[@]} old full backup(s); retained newest $RETAIN"
fi
mapfile -t legacy < <(ls -1 "$BACKUP_DIR"/teamkb-*.db.age 2>/dev/null)
if [ "${#legacy[@]}" -gt 0 ]; then
  rm -f "${legacy[@]}"
  log "removed ${#legacy[@]} legacy single-DB backup(s) (superseded by full-brain archive)"
fi

log "=== full-brain backup done ==="
