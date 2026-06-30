#!/usr/bin/env bash
# Nightly autonomous /teamkb-compile — compiles yesterday's work into the governed brain.
# Runs LOCALLY (cloud Routines can't reach the tailnet-bound brain / local ~/.teamkb).
# Scheduled ~03:30 via crontab, BEFORE the 04:30 teamkb-backup.timer, so the night's
# new memories land in that night's backup.
#
# Modeled on ~/000-projects/blog/startaitools/scripts/blog/blog-backfill-daily.sh
# (pty-wrapped headless claude -p, fail-loud trap, idempotency, ntfy+email, escalation),
# but self-contained (one wrapper, so the cron helpers are inlined rather than sourced
# from the blog repo).
#
# Mode: digest-first by default. Flip to auto-promote by setting TEAMKB_COMPILE_MODE=auto
# (here or in the crontab line) once the digests look right.

set -uo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
SKILL_DIR=/home/jeremy/.claude/skills/teamkb-compile
MCP_CONFIG="$SKILL_DIR/scripts/brain-mcp-config.json"
DECISIONS="$SKILL_DIR/methodology/decisions.jsonl"
EMAIL_SCRIPT=/home/jeremy/.claude/skills/email/scripts/send-email.cjs
EMAIL_TO=jeremy@intentsolutions.io
SCRATCH=/tmp/teamkb-compile
LOG_DIR=/home/jeremy/.local/state/teamkb-compile-daily
NTFY_TOPIC_FILE=/home/jeremy/.ntfy-topic

TIMEOUT_SECS="${TEAMKB_COMPILE_TIMEOUT:-1800}" # 30 min hard ceiling
TARGET="${TEAMKB_COMPILE_DATE:-$(date -d 'yesterday' +%Y-%m-%d)}"
NEXT="$(date -d "$TARGET +1 day" +%Y-%m-%d)"
MODE_STATE="$LOG_DIR/mode"                      # persisted, self-managed mode
SOAK_NIGHTS="${TEAMKB_COMPILE_SOAK_NIGHTS:-3}"  # clean digest nights before auto-graduation

mkdir -p "$LOG_DIR" "$SCRATCH"
LOG="$LOG_DIR/run-${TARGET}.log"
DIGEST="$SCRATCH/digest-${TARGET}.md"

log() { echo "[$(date -Is)] $*" | tee -a "$LOG"; }

# ── Mode: self-managing (digest-first, AUTO-GRADUATES — no human flip) ─────────
# "I don't want to manage anything, the computer and AI should." The wrapper owns
# its own rollout: it soaks in digest mode, then graduates ITSELF to auto after
# SOAK_NIGHTS clean digest runs, and persists that decision. Resolution order:
#   1. explicit env override (TEAMKB_COMPILE_MODE) — escape hatch for test/revert
#   2. persisted state file ($MODE_STATE)
#   3. default: digest (seeds the state file)
MODE_SRC="default"
if [ -n "${TEAMKB_COMPILE_MODE:-}" ]; then
  MODE="$TEAMKB_COMPILE_MODE"; MODE_SRC="env-override"
elif [ -s "$MODE_STATE" ]; then
  MODE="$(tr -dc 'a-z' < "$MODE_STATE")"; MODE_SRC="state-file"
else
  MODE="digest"; echo digest > "$MODE_STATE"; MODE_SRC="default(seeded)"
fi
[ "$MODE" = "auto" ] || MODE="digest"           # sanitize anything unexpected → digest

# Auto-graduation: once enough clean digest nights have banked, flip to auto and
# persist it (one-way). Skipped when the mode came from an explicit env override.
GRADUATED=0; CLEAN_DIGESTS="n/a"
if [ "$MODE" = "digest" ] && [ "$MODE_SRC" != "env-override" ]; then
  CLEAN_DIGESTS=$(grep -cE '"mode"[[:space:]]*:[[:space:]]*"digest"' "$DECISIONS" 2>/dev/null) || CLEAN_DIGESTS=0
  if [ "$CLEAN_DIGESTS" -ge "$SOAK_NIGHTS" ]; then
    MODE="auto"; GRADUATED=1; echo auto > "$MODE_STATE"
  fi
fi

log "=== teamkb-compile-daily start (target=$TARGET mode=$MODE src=$MODE_SRC soak=$CLEAN_DIGESTS/$SOAK_NIGHTS graduated=$GRADUATED) ==="
[ "$GRADUATED" -eq 1 ] && log "🎓 SELF-GRADUATED digest→auto after ${CLEAN_DIGESTS} clean digest nights (>= soak ${SOAK_NIGHTS}). Auto-promoting nightly from now on."

# ── Fail-loud guard ──────────────────────────────────────────────────────────
# Any non-zero exit that bypassed the normal notify path must still alert.
NOTIFIED=0
notify_unexpected_exit() {
  local rc=$?
  [ "$rc" -eq 0 ] && return
  [ "$NOTIFIED" -eq 1 ] && return
  log "ABNORMAL EXIT (rc=$rc) before normal notification — sending fail-loud alert"
  local topic; topic=$(cat "$NTFY_TOPIC_FILE" 2>/dev/null)
  [ -n "$topic" ] && curl -s -H "Title: 🚨 teamkb-compile aborted early" -H "Priority: max" -H "Tags: rotating_light" \
    -d "${TARGET}: early exit rc=${rc} — brain may not be updated. Check ${LOG}" \
    "https://ntfy.sh/$topic" >/dev/null 2>&1 || true
  if command -v node >/dev/null 2>&1 && [ -f "$EMAIL_SCRIPT" ]; then
    node "$EMAIL_SCRIPT" --to "$EMAIL_TO" \
      --subject "🚨 teamkb-compile aborted early: ${TARGET} (rc=${rc})" \
      --body "$(printf 'teamkb-compile exited abnormally (rc=%s) BEFORE its normal summary.\nTarget: %s  Mode: %s\n\nLast 30 log lines:\n%s\n' \
        "$rc" "$TARGET" "$MODE" "$(tail -30 "$LOG" 2>/dev/null)")" >/dev/null 2>&1 || true
  fi
}
trap notify_unexpected_exit EXIT

# ── Idempotency ──────────────────────────────────────────────────────────────
# If an audit record for this date already exists, this night already ran — no-op.
if [ -f "$DECISIONS" ] && grep -qE "\"date\"[[:space:]]*:[[:space:]]*\"${TARGET}\"" "$DECISIONS" 2>/dev/null; then
  log "Audit record already exists for ${TARGET} — skipping (no-op)."
  NOTIFIED=1
  exit 0
fi

# ── Preflight: brain reachable? ──────────────────────────────────────────────
if [ ! -f "$MCP_CONFIG" ]; then
  log "FATAL: MCP config missing at $MCP_CONFIG"; exit 1
fi

# ── Dry run: resolve mode + graduation, then stop (no claude, no writes) ──────
# For testing the self-management logic without a full ~9-min compile.
if [ -n "${TEAMKB_COMPILE_DRYRUN:-}" ]; then
  log "DRYRUN: would invoke /teamkb-compile $TARGET $NEXT --$MODE (src=$MODE_SRC, graduated=$GRADUATED). No claude, no writes."
  NOTIFIED=1; exit 0
fi

# ── Run /teamkb-compile headlessly ───────────────────────────────────────────
# pty-wrap (script -e -q -a -c) so claude's CLI flushes incrementally instead of
# buffering until SIGKILL — keeps the log diagnosable on timeout. --strict-mcp-config
# loads ONLY the governed-brain server (local mode, in-process ~/.teamkb); the plugin
# is not in enabledPlugins so headless claude needs it passed explicitly.
log "Invoking: claude -p /teamkb-compile $TARGET $NEXT --$MODE (timeout ${TIMEOUT_SECS}s, pty-wrapped)"
T0=$(date +%s)
if /usr/bin/timeout "$TIMEOUT_SECS" script -e -q -a \
     -c "claude -p '/teamkb-compile $TARGET $NEXT --$MODE' --mcp-config '$MCP_CONFIG' --strict-mcp-config --dangerously-skip-permissions" \
     "$LOG" >/dev/null 2>&1; then
  WALL=$(( $(date +%s) - T0 )); STATUS="OK"
  log "claude -p exited cleanly after ${WALL}s ($((WALL/60))m $((WALL%60))s)"
else
  EXIT=$?; WALL=$(( $(date +%s) - T0 ))
  if [ "$EXIT" = "124" ]; then STATUS="FAILED (timeout ${TIMEOUT_SECS}s)"; log "claude -p TIMED OUT after ${WALL}s"
  else STATUS="FAILED (exit $EXIT)"; log "claude -p exited non-zero ($EXIT) after ${WALL}s"; fi
fi

# ── Classify result ──────────────────────────────────────────────────────────
HAS_RECORD=0
grep -qE "\"date\"[[:space:]]*:[[:space:]]*\"${TARGET}\"" "$DECISIONS" 2>/dev/null && HAS_RECORD=1
if [ "$STATUS" = "OK" ] && [ "$HAS_RECORD" -eq 0 ]; then
  # Clean exit but no audit record → almost always a no-activity no-op.
  STATUS="OK (no activity — nothing to compile)"
fi

# ── Consecutive-failure escalation ───────────────────────────────────────────
CONSEC=0
while IFS= read -r f; do
  if grep -qE "FAILED|TIMED OUT|FATAL" "$f" 2>/dev/null; then CONSEC=$((CONSEC+1)); else break; fi
done < <(find "$LOG_DIR" -maxdepth 1 -name 'run-*.log' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -10 | awk '{print $2}')
ESC_PREFIX=""; ESC_PRIO="default"
case "$STATUS" in FAILED*) [ "$CONSEC" -ge 3 ] && { ESC_PREFIX="🚨 ${CONSEC}-DAY STREAK: "; ESC_PRIO="max"; } ;; esac

# Self-management footer: graduation banner, or soak progress (no manual flip).
GRAD_NOTE=""; SOAK_NOTE=""
if [ "$GRADUATED" -eq 1 ]; then
  GRAD_NOTE="🎓 Self-graduated to AUTO-PROMOTE this run (soak met). Nothing to do — the brain updates itself nightly from here."
elif [ "$MODE" = "digest" ] && [ "$MODE_SRC" != "env-override" ] && [ "$CLEAN_DIGESTS" != "n/a" ]; then
  SOAK_NOTE="Self-managed rollout: ${CLEAN_DIGESTS}/${SOAK_NIGHTS} clean digest nights banked. It auto-promotes on its own once the soak is met — nothing for you to flip."
fi

# ── Email: the digest (preferred) or the log tail ────────────────────────────
if [ -f "$DIGEST" ]; then
  BODY="$(cat "$DIGEST")

--------------------------------------------------------------------------------
Run: ${STATUS} · ${WALL}s · mode=${MODE} · full log: ${LOG}
${GRAD_NOTE}${SOAK_NOTE}"
  SUBJECT="${ESC_PREFIX}teamkb-compile ${TARGET} (${MODE}) — ${STATUS}"
else
  BODY="teamkb-compile ${TARGET} (mode=${MODE}) — ${STATUS}
No digest file was written ($DIGEST). Likely no activity, or the run failed before Phase 5.

Last 50 log lines (full log: ${LOG}):
================================================================================
$(tail -50 "$LOG" 2>/dev/null)"
  SUBJECT="${ESC_PREFIX}teamkb-compile ${TARGET} (${MODE}) — ${STATUS}"
fi

if command -v node >/dev/null 2>&1 && [ -f "$EMAIL_SCRIPT" ]; then
  node "$EMAIL_SCRIPT" --to "$EMAIL_TO" --subject "$SUBJECT" --body "$BODY" >> "$LOG" 2>&1 \
    || log "Email send failed — see log"
fi

# ── ntfy status push (content stays in the email) ────────────────────────────
NTFY_TOPIC=$(cat "$NTFY_TOPIC_FILE" 2>/dev/null)
if [ -n "$NTFY_TOPIC" ]; then
  case "$STATUS" in
    OK*) _t="teamkb-compile ${MODE} OK"; [ "$GRADUATED" -eq 1 ] && _t="🎓 teamkb-compile graduated → AUTO"
         curl -s -H "Title: ${_t}" -H "Priority: default" -H "Tags: brain" \
           -d "${TARGET}: ${STATUS}${GRAD_NOTE:+ — ${GRAD_NOTE}}" "https://ntfy.sh/$NTFY_TOPIC" >> "$LOG" 2>&1 || true ;;
    *)   _p="high"; [ "$ESC_PRIO" = "max" ] && _p="max"
         curl -s -H "Title: ${ESC_PREFIX}teamkb-compile FAILED" -H "Priority: ${_p}" -H "Tags: rotating_light" \
           -d "${TARGET}: ${STATUS} (${CONSEC}-day streak). Log: $LOG" "https://ntfy.sh/$NTFY_TOPIC" >> "$LOG" 2>&1 || true ;;
  esac
fi

NOTIFIED=1
log "=== teamkb-compile-daily end (${STATUS}) ==="
case "$STATUS" in OK*) exit 0 ;; *) exit 1 ;; esac
