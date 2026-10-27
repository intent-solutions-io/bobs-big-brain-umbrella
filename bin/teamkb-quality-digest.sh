#!/usr/bin/env bash
#
# Public bootstrap observer. The deploy helper seeds this only when the runtime
# path is absent; an existing observer may have a separate operating owner.
# This file is not the update source for the private company-host observer.
#
# teamkb-quality-digest.sh — nightly GOVERN-QUALITY drift canary for the governed
# brain (bead compile-then-govern-e06.7). The teamkb-compile skill already emits a
# candidate/promotion digest and runs `brain_audit_verify` (honest 3-state since
# e06.2 — "0 tamper signatures, N benign forks", NOT a false TAMPER klaxon). This
# adds the QUALITY-DRIFT half: a cheap, read-only snapshot of the governed store
# that flags day-over-day drift — a governance backlog, a promotion stall, a
# supersession/churn spike — pushed to Slack #cron-failures on DRIFT (ntfy
# retired 2026-06-13) so the un-babysat loop is observable on QUALITY, not just
# liveness.
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
# Shared notify spine — cron_fail routes a DRIFT alert (normalized to plain
# English) to #cron-failures. ntfy retired 2026-06-13. Guarded for fresh clones.
if [ -f "$HOME/bin/lib/notify-lib.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/bin/lib/notify-lib.sh"
fi
# drift thresholds (env-overridable)
CANDIDATE_BACKLOG_WARN="${TEAMKB_CANDIDATE_BACKLOG_WARN:-200}"   # ungoverned inbox this large = a governance stall
SUPERSEDE_SPIKE_WARN="${TEAMKB_SUPERSEDE_SPIKE_WARN:-50}"        # >this many new supersessions overnight = churn
QUARANTINE_REVIEW_WARN="${TEAMKB_QUARANTINE_REVIEW_WARN:-25}"    # this many member proposals awaiting review = go look (jfv.8)
REVIEW_AGENT_ACTOR="${TEAMKB_REVIEW_AGENT_ACTOR:-teamkb-review-agent}"  # the audited review-agent actor id

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

# ── Agent-review queue + last-night decisions (jfv.8 / 014-AT-DECR) ───────────
# quarantined = member proposals HELD for review (the exit the review agent drains);
# a subset of the backlog, broken out so "you have proposals to review" is visible.
quarantined=$(q "SELECT count(*) FROM candidates WHERE status='quarantined';"); quarantined=${quarantined:-0}
# The review agent's decisions in the last 24h — filterable BECAUSE every decision
# is a receipt naming the actor (014-AT-DECR #2). ISO-format threshold so the
# lexical timestamp comparison is correct against the stored 'YYYY-MM-DDTHH:MM:SS.sssZ'.
since=$(q "SELECT strftime('%Y-%m-%dT%H:%M:%fZ','now','-1 day');")
agent_promoted=$(q "SELECT count(*) FROM audit_events WHERE action='promoted' AND json_extract(actor_json,'\$.id')='${REVIEW_AGENT_ACTOR}' AND timestamp >= '${since}';"); agent_promoted=${agent_promoted:-0}
# A candidate rejection is written as an action='deleted' event (the curator's
# reject() convention) carrying details.disposition='rejected'. Scope on BOTH so a
# hypothetical non-rejection 'deleted' by the same actor can't inflate the count.
agent_rejected=$(q "SELECT count(*) FROM audit_events WHERE action='deleted' AND json_extract(actor_json,'\$.id')='${REVIEW_AGENT_ACTOR}' AND json_extract(details_json,'\$.disposition')='rejected' AND timestamp >= '${since}';"); agent_rejected=${agent_rejected:-0}
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
# Absolute-state: a pile of member proposals held for review means "go look" — the
# review agent should be draining these (jfv.8). Fine on the first run.
[ "$quarantined" -ge "$QUARANTINE_REVIEW_WARN" ] && alerts+=("$quarantined member proposals awaiting review (>= $QUARANTINE_REVIEW_WARN) — run /teamkb-review or inspect brain_inbox")
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
  printf '{"status":"%s","active":%s,"superseded":%s,"total":%s,"candidates":%s,"backlog":%s,"quarantined_awaiting_review":%s,"review_agent_24h":{"promoted":%s,"rejected":%s},"audit_events":%s,"delta":{"active":%s,"superseded":%s,"audit":%s},"alerts":%s}\n' \
    "$status" "$active" "$superseded" "$total_mem" "$candidates" "$backlog" "$quarantined" "$agent_promoted" "$agent_rejected" "$audit" "$d_active" "$d_superseded" "$d_audit" \
    "$(printf '%s\n' "${alerts[@]:-}" | sed '/^$/d' | sed 's/"/\\"/g;s/.*/"&"/' | paste -sd, - | sed 's/^/[/;s/$/]/')"
else
  echo "## Govern quality — ${status}"
  echo "curated: ${active} active (${d_active:+Δ$d_active}), ${superseded} superseded (${d_superseded:+Δ$d_superseded}); inbox backlog: ${backlog}; audit_events: ${audit} (${d_audit:+Δ$d_audit})"
  echo "review queue: ${quarantined} member proposals awaiting review; review agent last 24h: promoted ${agent_promoted}, rejected ${agent_rejected} (spot-check + override via brain_transition)"
  echo "active by category: ${by_cat:-none}"
  echo "audit chain status: run brain_audit_verify (honest 3-state since e06.2 — benign forks are not tamper)."
  if [ "${#alerts[@]}" -gt 0 ]; then printf '⚠ DRIFT:\n'; printf '  - %s\n' "${alerts[@]}"; fi
fi

# ── best-effort Slack: push a normalized one-liner on DRIFT ONLY (ntfy retired) ──
# Success is silent — the OK metrics are already on stdout for whoever ran this.
# The --no-ntfy flag is kept as the legacy opt-out (now suppresses the Slack push).
if [ "$want_ntfy" -eq 1 ] && [ "$status" = "DRIFT" ] && command -v cron_fail >/dev/null 2>&1; then
  cron_fail "teamkb-quality-digest" "govern-quality DRIFT: $(printf '%s; ' "${alerts[@]}")"
fi

exit 0
