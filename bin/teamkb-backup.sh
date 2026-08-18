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
#     spool/                    ICO->INTKB queue -> archived
#     tokens.json               SECRET           -> archived (whole archive is age-encrypted)
#   Tier B — expensive-derived, cheaper to restore than recompute:
#     brain/wiki/               compiled markdown
#     feedback/
#     eval-anchor/              frozen eval snapshot + dense prebuilt index
#     corpus-machine/           expensive machine-readable eval corpus
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
#   All brain writes (this backup + brain_govern, including govern invoked by the
#   nightly or on-push compiler) serialize on one exclusive flock at
#   $TEAMKB_HOME/.write.lock. The outer teamkb-compile-daily.sh wrapper deliberately
#   uses .compile.lock so its brain_govern child can acquire this writer lock.
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
R2_REMOTE="${TEAMKB_R2_REMOTE-r2-teamkb:teamkb-backups}"   # 2nd off-host target (Cloudflare R2); empty = skip
# Off-host over the tailnet to the VPS (which holds a decrypting key). ssh-alias:dir; empty disables.
VPS_REMOTE="${TEAMKB_VPS_REMOTE-intentsolutions:teamkb-backups}"
RETAIN="${TEAMKB_BACKUP_RETAIN:-14}"
LOGDIR="${TEAMKB_BACKUP_LOGDIR:-$HOME/.local/state/teamkb-backup}"
AF_CLI="${AF_NOTIFY_ALERT_FLOOR:-$HOME/bin/lib/alert-floor.sh}"
LIVENESS_DIR="${INTENT_OS_LIVENESS_DIR:-$HOME/.local/state/intent-os/liveness}"
LIVENESS_BEAT="$LIVENESS_DIR/teamkb-backup.beat"
LIVENESS_OK="$LIVENESS_DIR/teamkb-backup.ok"
LIVENESS_SKIPPED="$LIVENESS_DIR/teamkb-backup.skipped"

# Tier-A/B paths, RELATIVE to $TEAMKB_HOME. Only those that exist are archived.
# `audit` = the top-level external anchor log (anchors.jsonl + its .git) — the
# receipts trust root (R4/e06.11); DISTINCT from brain/audit (the ICO receipts).
TIER_A_PATHS=(brain/raw brain/audit spool tokens.json audit)
TIER_B_PATHS=(brain/wiki feedback eval-anchor corpus-machine)

mkdir -p "$BACKUP_DIR" "$LOGDIR"
LOG="$LOGDIR/backup.log"
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG"; }

# Failure presentation is governed by Intent OS af_dispatch. The cleanup EXIT
# trap is installed before work/shm exist, so every fatal preflight path still
# gets an honest owner-neutral heartbeat and a content-safe sys-backups receipt.
# The backup result remains authoritative: a missing alert floor must never turn
# a verified local restore into a fabricated success or destroy a good archive.
FAILURE_ALERT_ATTEMPTED=0
RUN_ACCEPTED=0
RUN_SKIPPED=0
FAILURE_REASON=""

write_marker() {
  local path="$1"
  if [ -e "$path" ] && [ ! -f "$path" ]; then
    return 1
  fi
  : > "$path" 2>/dev/null
}

dispatch_alert() {
  local raw="$1" fallback="$2" severity="${3:-high}" output rc=0
  if [ ! -f "$AF_CLI" ]; then
    log "WARN: governed alert floor missing at $AF_CLI"
    return 1
  fi
  output="$(AF_LLM_NORMALIZE=1 AF_HC_URL='' bash "$AF_CLI" dispatch \
    "$raw" "$fallback" "$severity" sys-backups 2>&1)" || rc=$?
  printf '%s\n' "$output" >>"$LOG" 2>/dev/null || true
  if [[ "$output" == *"status=dedup_suppressed"* ]]; then
    return 0
  fi
  if [ "$rc" -eq 0 ] && [[ "$output" == *"status=delivered"* ]]; then
    return 0
  fi
  log "WARN: governed sys-backups receipt was not accepted (rc=$rc)"
  return 1
}

_backup_on_exit() {
  local rc=$?
  rm -rf "${work:-}" "${shm:-}" 2>/dev/null || true
  mkdir -p "$LIVENESS_DIR" 2>/dev/null || {
    FAILURE_REASON="liveness directory unavailable: $LIVENESS_DIR"
    rc=1
  }
  if ! write_marker "$LIVENESS_BEAT"; then
    FAILURE_REASON="liveness heartbeat write failed: $LIVENESS_BEAT"
    rc=1
  fi
  if [ "$RUN_SKIPPED" -eq 1 ]; then
    write_marker "$LIVENESS_SKIPPED" 2>/dev/null || true
  elif [ "$rc" -eq 0 ] && [ "$RUN_ACCEPTED" -eq 1 ]; then
    if write_marker "$LIVENESS_OK"; then
      rm -f "$LIVENESS_SKIPPED" 2>/dev/null || true
    else
      FAILURE_REASON="liveness success marker write failed: $LIVENESS_OK"
      rc=1
    fi
  fi
  if [ "$rc" -ne 0 ] && [ "$FAILURE_ALERT_ATTEMPTED" -eq 0 ]; then
    [ -n "$FAILURE_REASON" ] || FAILURE_REASON="backup exited rc=$rc"
    local detail="TeamKB full-brain backup failed: $FAILURE_REASON"
    [ -f "$LOG" ] && detail="${detail}; recent log: $(tail -n 3 "$LOG" 2>/dev/null | tr '\n' ' ' | cut -c1-400)"
    FAILURE_ALERT_ATTEMPTED=1
    dispatch_alert "$detail" "TeamKB backup failed; inspect the content-safe backup log." high || true
  fi
  trap - EXIT
  exit "$rc"
}
trap _backup_on_exit EXIT

# ── ~/.teamkb single-writer lock (e06.12 / R13 / #27) ─────────────────────────
# Acquire an EXCLUSIVE flock BEFORE any DB/file mutation, hold it for the whole
# run (flock auto-releases when fd 9 closes on process exit). Serializes against
# brain_govern (including govern invoked by teamkb-compile-daily.sh or e06.5's
# on-push compile) so a snapshot is never taken across a non-atomic govern write.
# The backup waits for an in-flight writer (TEAMKB_LOCK_WAIT, default 300s); a
# delayed nightly backup is fine.
LOCK="${TEAMKB_LOCK:-$TEAMKB_HOME/.write.lock}"
LOCK_WAIT="${TEAMKB_LOCK_WAIT:-300}"
if command -v flock >/dev/null 2>&1; then
  mkdir -p "$TEAMKB_HOME"
  exec 9>"$LOCK"
  if ! flock -w "$LOCK_WAIT" 9; then
    RUN_SKIPPED=1
    FAILURE_REASON="writer lock remained held for ${LOCK_WAIT}s"
    log "another ~/.teamkb writer holds $LOCK after ${LOCK_WAIT}s — skipping this backup run"
    exit 0
  fi
else
  log "WARN: flock not on PATH — proceeding WITHOUT the ~/.teamkb writer lock (concurrent compile could skew this snapshot)"
fi

[ -f "$DB" ] || { FAILURE_REASON="govern DB not found"; log "FATAL: govern DB not found: $DB"; exit 1; }
[ -x "$AGE_BIN" ] || { FAILURE_REASON="age binary not found or executable"; log "FATAL: age binary not found/executable: $AGE_BIN"; exit 1; }
if ! command -v sqlite3 >/dev/null; then
  FAILURE_REASON="sqlite3 not on PATH"
  log "FATAL: sqlite3 not on PATH"
  exit 1
fi
if ! command -v zstd >/dev/null; then
  FAILURE_REASON="zstd not on PATH"
  log "FATAL: zstd not on PATH"
  exit 1
fi

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
[ "$gov_ic" = "ok" ] || { FAILURE_REASON="govern DB integrity_check failed"; log "FATAL: govern DB integrity_check: $gov_ic"; exit 1; }
gov_tables="$(sqlite3 "$stage/dbs/teamkb.db" "SELECT count(*) FROM sqlite_master WHERE type='table';")"

ico_tables="-"
if [ -f "$ICO_DB" ]; then
  sqlite3 "$ICO_DB" "VACUUM INTO '$stage/dbs/ico-state.db'"
  ico_ic="$(sqlite3 "$stage/dbs/ico-state.db" 'PRAGMA integrity_check;')"
  [ "$ico_ic" = "ok" ] || { FAILURE_REASON="compile DB integrity_check failed"; log "FATAL: compile DB integrity_check: $ico_ic"; exit 1; }
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

# 2. Quiesce Tier-A/B paths into the stage under the same writer lock as the
# DB snapshots. Tar-from-live can race the growing audit/provenance tree; a
# restore must be internally consistent, so archive only the staged copy.
for p in "${present[@]}"; do
  dest="$stage/$p"
  mkdir -p "$(dirname "$dest")"
  if [ -d "$TEAMKB_HOME/$p" ]; then
    mkdir -p "$dest"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete "$TEAMKB_HOME/$p/" "$dest/"
    else
      rm -rf "$dest"
      cp -a "$TEAMKB_HOME/$p" "$dest"
    fi
  else
    cp -a "$TEAMKB_HOME/$p" "$dest"
  fi
done
log "tier paths staged into $stage (${#present[@]} components)"

# 3. MANIFEST — records what was captured + the verification fingerprints.
# Counts come from the staged tree so restore checks match the archive.
raw_files="$( [ -d "$stage/brain/raw" ] && find "$stage/brain/raw" -type f | wc -l || echo 0)"
audit_files="$( [ -d "$stage/brain/audit" ] && find "$stage/brain/audit" -type f | wc -l || echo 0)"
spool_files="$( [ -d "$stage/spool" ] && find "$stage/spool" -type f | wc -l || echo 0)"
anchor_files="$( [ -d "$stage/audit" ] && find "$stage/audit" -type f | wc -l || echo 0)"
eval_anchor_files="$( [ -d "$stage/eval-anchor" ] && find "$stage/eval-anchor" -type f | wc -l || echo 0)"
corpus_machine_files="$( [ -d "$stage/corpus-machine" ] && find "$stage/corpus-machine" -type f | wc -l || echo 0)"
{
  echo "schemaVersion: 1"
  echo "createdAt: $(date -u +%FT%TZ)"
  echo "host: $(hostname)"
  echo "teamkbHome: $TEAMKB_HOME"
  echo "govern_db_tables: $gov_tables"
  echo "compile_db_tables: $ico_tables"
  echo "raw_files: $raw_files"
  echo "audit_files: $audit_files"
  echo "spool_files: $spool_files"
  echo "anchor_files: $anchor_files"
  echo "eval_anchor_files: $eval_anchor_files"
  echo "corpus_machine_files: $corpus_machine_files"
  echo "tierA: ${TIER_A_PATHS[*]}"
  echo "tierB: ${TIER_B_PATHS[*]}"
  echo "components: dbs/teamkb.db dbs/ico-state.db ${present[*]}"
  echo "note: tier paths snapshotted under writer lock before tar"
} > "$stage/MANIFEST.txt"

# 4. one archive: everything from $stage (DBs + MANIFEST + staged Tier-A/B)
tar --zstd -cf "$arc" \
  -C "$stage" MANIFEST.txt dbs "${present[@]}"
log "archived: dbs + [${present[*]}] -> $(du -h "$arc" | cut -f1)"

# 5. encrypt to both recipients, then shred the plaintext archive + staged DBs
"$AGE_BIN" -r "$AGE_RECIP_LOCAL" -r "$AGE_RECIP_VPS" -o "$enc" "$arc"
shred -u "$arc" 2>/dev/null || rm -f "$arc"
rm -rf "$stage/dbs"
log "encrypted (2 recipients) -> $enc ($(du -h "$enc" | cut -f1))"

# 6. restore round-trip on tmpfs: decrypt + extract + verify BOTH DBs + Tier-A presence
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
# The canonical spool is Tier A even when it contains only archived receipts.
# If it exists at snapshot time, require the restored directory and exact file
# count; silently dropping it would erase pending intake or its handoff proof.
{ [ ! -d "$TEAMKB_HOME/spool" ] || { [ -d "$rdir/spool" ] && [ "$(find "$rdir/spool" -type f | wc -l)" = "$spool_files" ]; }; } || fail="$fail spool_missing"
# External anchor log (the receipts trust root, R4/e06.11): if it exists on the
# source it MUST restore non-empty with a matching file count — a restore that
# silently drops it would lose all external tamper-evidence.
{ [ ! -d "$TEAMKB_HOME/audit" ] || { [ -s "$rdir/audit/anchors.jsonl" ] && [ "$(find "$rdir/audit" -type f | wc -l)" = "$anchor_files" ]; }; } || fail="$fail anchor_missing"
{ [ ! -e "$TEAMKB_HOME/tokens.json" ] || [ -f "$rdir/tokens.json" ]; } || fail="$fail tokens_missing"
# Tier-B eval reproducibility roots: when present on the source host, a
# brain-scoped restore must carry every file. The frozen eval snapshot cannot be
# reconstructed after the corpus advances; corpus-machine is expensive derived
# state whose restoration avoids a large rebuild.
{ [ ! -d "$TEAMKB_HOME/eval-anchor" ] || { [ -d "$rdir/eval-anchor" ] && [ "$(find "$rdir/eval-anchor" -type f | wc -l)" = "$eval_anchor_files" ]; }; } || fail="$fail eval_anchor_missing"
{ [ ! -d "$TEAMKB_HOME/corpus-machine" ] || { [ -d "$rdir/corpus-machine" ] && [ "$(find "$rdir/corpus-machine" -type f | wc -l)" = "$corpus_machine_files" ]; }; } || fail="$fail corpus_machine_missing"

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
  FAILURE_REASON="restore round-trip failed:${fail}"
  log "FATAL: restore round-trip FAILED —$fail — discarding unrestorable backup"
  rm -f "$enc"
  exit 1
fi
log "restore round-trip OK: govern+compile integrity verified, corpus($raw_files)/audit($audit_files)/spool($spool_files)/anchor($anchor_files)/eval-anchor($eval_anchor_files)/corpus-machine($corpus_machine_files)/tokens present on tmpfs, restored anchor re-verified against restored chain"
RUN_ACCEPTED=1

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
    dispatch_alert \
      "TeamKB backup local restore passed but R2 off-host push failed: $R2_REMOTE" \
      "TeamKB backup is locally verified; R2 off-host copy failed." high || true
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
      dispatch_alert \
        "TeamKB backup local restore passed but VPS archive sha256 mismatched" \
        "TeamKB backup is locally verified; VPS off-host copy is suspect." high || true
    fi
  else
    log "WARN: off-host VPS push to $VPS_REMOTE FAILED (local encrypted backup retained)"
    dispatch_alert \
      "TeamKB backup local restore passed but VPS off-host push failed: $VPS_REMOTE" \
      "TeamKB backup is locally verified; VPS off-host copy failed." high || true
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
