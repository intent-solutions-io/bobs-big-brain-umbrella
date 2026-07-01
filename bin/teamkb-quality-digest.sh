#!/usr/bin/env bash
#
# teamkb-quality-digest.sh — nightly GOVERN-QUALITY drift canary for the governed
# brain (bead compile-then-govern-e06.7). The teamkb-compile skill already emits a
# candidate/promotion digest and runs `brain_audit_verify` (honest 3-state since
# e06.2 — "0 tamper signatures, N benign forks", NOT a false TAMPER klaxon). This
# adds the QUALITY-DRIFT half: a cheap, read-only snapshot of the governed store
# that flags day-over-day drift — a governance backlog, a promotion stall, a
# supersession/churn spike — pushed to ntfy so the un-babysat nightly loop is
# observable on QUALITY, not just liveness.
#
# Auto by default, ALERT on drift (not a raw dump) — consistent with the
# self-management doctrine. Standalone + idempotent; run it from cron or after the
# nightly compile. NEVER mutates ~/.teamkb (opens the DB read-only) and never fails
# loud — a broken canary must not take anything down.
#
# Usage:  teamkb-quality-digest.sh [--no-ntfy] [--json]
set -uo pipefail

TEAMKB_HOME="${TEAMKB_HOME:-$HOME/.teamkb}"
DB="${TEAMKB_DB:-$TEAMKB_HOME/teamkb.db}"
STATE="${TEAMKB_QUALITY_STATE:-$TEAMKB_HOME/.quality-digest.state}"
NTFY_TOPIC_FILE="${NTFY_TOPIC_FILE:-$HOME/.ntfy-topic}"
NTFY_TOPIC="${TEAMKB_NTFY_TOPIC:-$( [ -f "$NTFY_TOPIC_FILE" ] && head -n1 "$NTFY_TOPIC_FILE" 2>/dev/null )}"
# drift thresholds (env-overridable)
CANDIDATE_BACKLOG_WARN="${TEAMKB_CANDIDATE_BACKLOG_WARN:-200}"   # ungoverned inbox this large = a governance stall
SUPERSEDE_SPIKE_WARN="${TEAMKB_SUPERSEDE_SPIKE_WARN:-50}"        # >this many new supersessions overnight = churn

want_ntfy=1; want_json=0
for a in "$@"; do case "$a" in --no-ntfy) want_ntfy=0;; --json) want_json=1;; esac; done

command -v sqlite3 >/dev/null 2>&1 || { echo "teamkb-quality-digest: sqlite3 not on PATH — skipping" >&2; exit 0; }
[ -f "$DB" ] || { echo "teamkb-quality-digest: no brain DB at $DB — skipping" >&2; exit 0; }

# One read-only query for every count; lifecycle/category are the real columns.
q() { sqlite3 -readonly -batch -noheader "$DB" "$1" 2>/dev/null | tr -d '[:space:]'; }
active=$(q "SELECT count(*) FROM curated_memories WHERE lifecycle='active';"); active=${active:-0}
superseded=$(q "SELECT count(*) FROM curated_memories WHERE lifecycle='superseded';"); superseded=${superseded:-0}
total_mem=$(q "SELECT count(*) FROM curated_memories;"); total_mem=${total_mem:-0}
candidates=$(q "SELECT count(*) FROM candidates;"); candidates=${candidates:-0}
audit=$(q "SELECT count(*) FROM audit_events;"); audit=${audit:-0}
# governed but not yet promoted = the inbox backlog (candidates without a curated row)
promoted_ids=$(q "SELECT count(DISTINCT candidate_id) FROM curated_memories;"); promoted_ids=${promoted_ids:-0}
backlog=$(( candidates - promoted_ids )); [ "$backlog" -lt 0 ] && backlog=0
by_cat=$(sqlite3 -readonly -batch -noheader "$DB" \
  "SELECT category||'='||count(*) FROM curated_memories WHERE lifecycle='active' GROUP BY category ORDER BY count(*) DESC;" 2>/dev/null | paste -sd' ' -)

# ── drift vs the previous snapshot ──────────────────────────────────────────────
# First run (no prior snapshot) establishes the BASELINE — never alert on it, or
# every metric reads as a spike-from-zero.
first_run=0; [ -f "$STATE" ] || first_run=1
p_active=0; p_superseded=0; p_audit=0
if [ -f "$STATE" ]; then
  # shellcheck disable=SC1090
  . "$STATE" 2>/dev/null || true
  p_active="${SNAP_ACTIVE:-0}"; p_superseded="${SNAP_SUPERSEDED:-0}"; p_audit="${SNAP_AUDIT:-0}"
fi
d_active=$(( active - p_active ))
d_superseded=$(( superseded - p_superseded ))
d_audit=$(( audit - p_audit ))

alerts=()
# Backlog is an absolute-state alert (fine on the first run); the Δ-based ones are
# suppressed on the baseline run.
[ "$backlog" -ge "$CANDIDATE_BACKLOG_WARN" ] && alerts+=("governance backlog: $backlog candidates ungoverned (>= $CANDIDATE_BACKLOG_WARN)")
if [ "$first_run" -eq 0 ]; then
  [ "$d_superseded" -ge "$SUPERSEDE_SPIKE_WARN" ] && alerts+=("supersession spike: +$d_superseded overnight (>= $SUPERSEDE_SPIKE_WARN churn)")
  [ "$d_active" -lt 0 ] && alerts+=("active memories SHRANK by $((-d_active)) overnight — unexpected for an append-mostly store")
  [ "$d_audit" -lt 0 ] && alerts+=("audit_events count DROPPED by $((-d_audit)) — the append-only chain must never shrink; investigate")
fi

status="OK"; [ "${#alerts[@]}" -gt 0 ] && status="DRIFT"
[ "$first_run" -eq 1 ] && status="${status} (baseline)"

# persist this snapshot for next run's diff
{ echo "SNAP_ACTIVE=$active"; echo "SNAP_SUPERSEDED=$superseded"; echo "SNAP_AUDIT=$audit"; } > "$STATE" 2>/dev/null || true

if [ "$want_json" -eq 1 ]; then
  printf '{"status":"%s","active":%s,"superseded":%s,"total":%s,"candidates":%s,"backlog":%s,"audit_events":%s,"delta":{"active":%s,"superseded":%s,"audit":%s},"alerts":%s}\n' \
    "$status" "$active" "$superseded" "$total_mem" "$candidates" "$backlog" "$audit" "$d_active" "$d_superseded" "$d_audit" \
    "$(printf '%s\n' "${alerts[@]:-}" | sed '/^$/d' | sed 's/"/\\"/g;s/.*/"&"/' | paste -sd, - | sed 's/^/[/;s/$/]/')"
else
  echo "## Govern quality — ${status}"
  echo "curated: ${active} active (${d_active:+Δ$d_active}), ${superseded} superseded (${d_superseded:+Δ$d_superseded}); inbox backlog: ${backlog}; audit_events: ${audit} (${d_audit:+Δ$d_audit})"
  echo "active by category: ${by_cat:-none}"
  echo "audit chain status: run brain_audit_verify (honest 3-state since e06.2 — benign forks are not tamper)."
  if [ "${#alerts[@]}" -gt 0 ]; then printf '⚠ DRIFT:\n'; printf '  - %s\n' "${alerts[@]}"; fi
fi

# ── best-effort ntfy: push a one-liner on DRIFT (or always, if --no-ntfy absent and OK) ──
if [ "$want_ntfy" -eq 1 ] && [ -n "$NTFY_TOPIC" ]; then
  if [ "$status" = "DRIFT" ]; then
    curl -s -H "Title: ⚠ teamkb govern-quality DRIFT" -H "Priority: high" -H "Tags: warning,brain" \
      -d "$(printf '%s\n' "${alerts[@]}")" "https://ntfy.sh/${NTFY_TOPIC}" >/dev/null 2>&1 || true
  else
    curl -s -H "Title: teamkb govern-quality OK" -H "Priority: min" -H "Tags: brain" \
      -d "active=${active} superseded=${superseded} backlog=${backlog} audit=${audit}" "https://ntfy.sh/${NTFY_TOPIC}" >/dev/null 2>&1 || true
  fi
fi

exit 0
