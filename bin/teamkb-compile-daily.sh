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
#
# Concurrency (bead compile-then-govern-e06.12 / risk 010-AT-RISK R13 / umbrella #27):
#   TWO locks, deliberately distinct — see the lock section below before changing either.
#     $TEAMKB_HOME/.compile.lock — THIS wrapper's run-level lock. Serializes compile
#       vs compile (nightly vs e06.5 on-push). Held across the whole `claude -p` run.
#     $TEAMKB_HOME/.write.lock   — the brain's writer lock, taken by brain_govern
#       (src/write-lock.ts) and teamkb-backup.sh around their own writes.
#   govern's runGovern spans SQLite + file export + qmd index + anchor-git
#   NON-atomically, so a govern racing the backup snapshot can skew the brain across
#   artifacts — that is what .write.lock prevents, at the brain layer, without this
#   wrapper having to hold it. The wrapper must NOT take .write.lock: in auto mode it
#   would deadlock the brain_govern running inside its own claude child.
#   A wrapper that can't get .compile.lock SKIPS gracefully (log + exit 0) — a missed
#   nightly compile is fine, and a colliding on-push compile defers to the running one.

set -uo pipefail
# Scratch files (signal doc, transcripts, digest, candidates) can contain
# secret-bearing transcript material — keep everything we write owner-only.
umask 077

# ── Config ───────────────────────────────────────────────────────────────────
SKILL_DIR=$HOME/.claude/skills/teamkb-compile
MCP_CONFIG="$SKILL_DIR/scripts/brain-mcp-config.json"
DECISIONS="$SKILL_DIR/methodology/decisions.jsonl"
EMAIL_SCRIPT=$HOME/.claude/skills/email/scripts/send-email.cjs
EMAIL_TO=jeremy@intentsolutions.io
SCRATCH=/tmp/teamkb-compile
LOG_DIR=$HOME/.local/state/teamkb-compile-daily
NTFY_TOPIC_FILE=$HOME/.ntfy-topic

# ── Inbox review phase (jfv.8 / 014-AT-DECR) ──────────────────────────────────
# After compiling MY day, review the TEAM's quarantined proposals with the agent
# reviewer. Runs in the SAME flock (sequential — never overlaps the compile). Live
# vs dry-run is tied to the compile MODE: `auto` → live (brain_approve/reject),
# `digest` → --dry-run (print verdicts only). So the ONE self-graduation gates
# both — the review never writes until the compile is already trusted to. Skipped
# cleanly unless the dedicated teamkb-review-agent admin token is provisioned.
REVIEW_SKILL_DIR=$HOME/.claude/skills/teamkb-review
REVIEW_MCP_CONFIG="$REVIEW_SKILL_DIR/scripts/review-mcp-config.json"
REVIEW_TOKEN_FILE="${TEAMKB_REVIEW_TOKEN_FILE:-$HOME/.teamkb/.review-agent-token}"
REVIEW_API_URL="${TEAMKB_API_URL:-http://100.109.119.103:3847}"
REVIEW_TIMEOUT_SECS="${TEAMKB_REVIEW_TIMEOUT:-900}" # 15 min ceiling for the review pass

TIMEOUT_SECS="${TEAMKB_COMPILE_TIMEOUT:-1800}" # 30 min hard ceiling
TARGET="${TEAMKB_COMPILE_DATE:-$(date -d 'yesterday' +%Y-%m-%d)}"
NEXT="$(date -d "$TARGET +1 day" +%Y-%m-%d)"
MODE_STATE="$LOG_DIR/mode"                      # persisted, self-managed mode
SOAK_NIGHTS="${TEAMKB_COMPILE_SOAK_NIGHTS:-3}"  # clean digest nights before auto-graduation

mkdir -p "$LOG_DIR" "$SCRATCH"
chmod 700 "$SCRATCH" 2>/dev/null || true   # tighten even if it pre-existed loose
LOG="$LOG_DIR/run-${TARGET}.log"
DIGEST="$SCRATCH/digest-${TARGET}.md"

log() { echo "[$(date -Is)] $*" | tee -a "$LOG"; }

# ── Inbox review (jfv.8 / 014-AT-DECR) ────────────────────────────────────────
# Sets the global REVIEW_SUMMARY (folded into the digest email). No-op + clear log
# line when the teamkb-review-agent token is not provisioned — that absence IS the
# deliberate activation gate (per the self-managing-rollout doctrine, nobody flips
# a switch; provisioning the token is the one deliberate step).
REVIEW_SUMMARY=""
run_inbox_review() {
  local tok=""
  if [ -n "${TEAMKB_REVIEW_AGENT_TOKEN:-}" ]; then
    tok="$TEAMKB_REVIEW_AGENT_TOKEN"
  elif [ -r "$REVIEW_TOKEN_FILE" ]; then
    tok="$(head -n1 "$REVIEW_TOKEN_FILE" 2>/dev/null)"
  fi
  if [ -z "$tok" ]; then
    log "inbox review SKIPPED — no teamkb-review-agent token ($REVIEW_TOKEN_FILE). Provision it to activate (see teamkb-review SKILL.md)."
    REVIEW_SUMMARY="Inbox review: skipped (no teamkb-review-agent token provisioned — the deliberate activation gate)."
    return 0
  fi
  if [ ! -f "$REVIEW_MCP_CONFIG" ]; then
    log "inbox review SKIPPED — review MCP config missing at $REVIEW_MCP_CONFIG"
    REVIEW_SUMMARY="Inbox review: skipped (review MCP config missing — run deploy-teamkb-compile.sh)."
    return 0
  fi
  # Live iff the compile is in auto (the single self-graduation gates both); digest → dry-run.
  local review_flag="--dry-run"; [ "$MODE" = "auto" ] && review_flag=""
  local rlog="$SCRATCH/review-${TARGET}.log"
  log "Invoking: claude -p /teamkb-review ${review_flag:-（live）} (timeout ${REVIEW_TIMEOUT_SECS}s)"
  # The token is exported ONLY into this invocation's environment via the command
  # prefix below — it is NEVER interpolated into the `script -c` shell string (that
  # would both duplicate it and risk shell-injection if a token held metacharacters).
  # `timeout` and `script -c` inherit the environment, so TEAMKB_API_URL +
  # TEAMKB_REVIEW_AGENT_TOKEN reach `claude` (and review-mcp-config's ${VAR} expansion)
  # without ever appearing in the shell string. The token is also never logged.
  if TEAMKB_API_URL="$REVIEW_API_URL" TEAMKB_REVIEW_AGENT_TOKEN="$tok" \
     /usr/bin/timeout "$REVIEW_TIMEOUT_SECS" script -e -q -a \
       -c "claude -p '/teamkb-review $review_flag' --mcp-config '$REVIEW_MCP_CONFIG' --strict-mcp-config --dangerously-skip-permissions" \
       "$rlog" >/dev/null 2>&1; then
    # Pull the agent's one-line tallies out of the transcript for the digest.
    local tally
    tally="$(grep -oE 'reviewed [0-9]+ · promoted [0-9]+ · held [0-9]+ · rejected [0-9]+( · refused-by-rules [0-9]+)?' "$rlog" 2>/dev/null | tail -1)"
    REVIEW_SUMMARY="Inbox review (${review_flag:-live}): ${tally:-completed (see $rlog)}."
    log "inbox review OK — ${REVIEW_SUMMARY}"
  else
    local rc=$?
    REVIEW_SUMMARY="Inbox review: FAILED (rc=$rc, ${review_flag:-live}) — see $rlog. (The compile still succeeded; review is best-effort.)"
    log "inbox review FAILED (rc=$rc) — see $rlog"
  fi
  return 0
}

# ── compile run-level lock (e06.12 / R13 / #27) ───────────────────────────────
# Acquire an EXCLUSIVE flock BEFORE resolving mode / invoking claude, hold it for
# the whole run (fd 9 auto-releases on process exit). A compile that can't get the
# lock SKIPS gracefully (exit 0) — it must never block forever nor snapshot/write a
# half-written brain. Short wait: a colliding compile defers to the running one.
#
# This MUST be .compile.lock, NOT .write.lock. The wrapper holds this lock across
# the whole `claude -p` invocation, and in auto mode that child calls brain_govern,
# whose src/write-lock.ts takes an flock on .write.lock. Sharing one file makes the
# wrapper deadlock its own child: capture (spool-only) succeeds, govern returns
# "brain busy", and the night's candidates strand in the spool. Serialization is
# still correct because compile-vs-backup is enforced at the brain layer — govern
# and teamkb-backup.sh both take .write.lock themselves, and more tightly than a
# whole-run hold. Do not "simplify" these back to one lock.
# Deadlocked 2026-07-12/13, fixed via .compile.lock, regressed 2026-08-16, cost the
# 08-17 and 08-18 nights. Claimed local brain receipt (queryable only where the
# brain endpoint is available): qmd://kb-guides/4ff153f8-afd8-5110-8d7d-f5c34ed8f691.md
TEAMKB_HOME="${TEAMKB_HOME:-$HOME/.teamkb}"
LOCK="${TEAMKB_LOCK:-$TEAMKB_HOME/.compile.lock}"
LOCK_WAIT="${TEAMKB_LOCK_WAIT:-10}"
if command -v flock >/dev/null 2>&1; then
  mkdir -p "$TEAMKB_HOME"
  exec 9>"$LOCK"
  if ! flock -w "$LOCK_WAIT" 9; then
    # exit 0 BEFORE the fail-loud EXIT trap is installed, so a lock-skip is silent
    # (a deferred compile is expected, not an incident).
    log "another ~/.teamkb writer holds $LOCK — skipping this compile run (will retry next trigger)"
    exit 0
  fi
else
  log "WARN: flock not on PATH — proceeding WITHOUT the ~/.teamkb writer lock (concurrent backup/compile could skew the brain)"
fi

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
    MODE="auto"; GRADUATED=1
    # Persist the one-way graduation — but never as a side effect of a dry run.
    [ -z "${TEAMKB_COMPILE_DRYRUN:-}" ] && echo auto > "$MODE_STATE"
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

# ── Review the team's quarantined inbox (jfv.8 / 014-AT-DECR) ─────────────────
# After compiling my own day, review the team's held proposals. Best-effort — a
# review failure never changes the compile STATUS (the brain is already updated).
run_inbox_review

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
${REVIEW_SUMMARY}
${GRAD_NOTE}${SOAK_NOTE}"
  SUBJECT="${ESC_PREFIX}teamkb-compile ${TARGET} (${MODE}) — ${STATUS}"
else
  BODY="teamkb-compile ${TARGET} (mode=${MODE}) — ${STATUS}
No digest file was written ($DIGEST). Likely no activity, or the run failed before Phase 5.
${REVIEW_SUMMARY}

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
