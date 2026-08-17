#!/usr/bin/env bash
# Daily Tier-A proof from a separate tailnet node through the published plugin.
set -euo pipefail
umask 077

STATE_DIR="${TEAMKB_CANARY_STATE_DIR:-$HOME/.local/state/teamkb-tailnet-canary}"
SECRETS_FILE="${TEAMKB_CANARY_SECRETS_FILE:-$HOME/.config/intentsolutions/secrets.prod.sops.yaml}"
PROBE="${TEAMKB_CANARY_PROBE:-$HOME/.local/lib/bbb-canary/teamkb-tailnet-probe.mjs}"
CJS="${TEAMKB_PROBE_CJS:-$HOME/.local/opt/bbb-tailnet-canary/current/node_modules/governed-second-brain/plugin-runtime/governed-brain.cjs}"
SOPS_BIN="${TEAMKB_CANARY_SOPS:-/usr/local/bin/sops}"
NODE_BIN="${TEAMKB_CANARY_NODE:-$(command -v node || true)}"
AF_LIB="${AF_NOTIFY_ALERT_FLOOR:-$HOME/bin/lib/alert-floor.sh}"
API_URL="${TEAMKB_API_URL:-http://100.109.119.103:3847}"
TENANT_ID="${TEAMKB_TENANT_ID:-synthetic-probe}"

mkdir -p "$STATE_DIR"
run_id="$(date -u +%Y%m%dT%H%M%SZ)"
receipt="$STATE_DIR/run-$run_id.json"
stderr_file="$STATE_DIR/run-$run_id.stderr"
tmp_receipt="$(mktemp "$STATE_DIR/.receipt.XXXXXX")"
trap 'unset TEAMKB_API_TOKEN token 2>/dev/null || true; rm -f "$tmp_receipt"' EXIT

record_failure() {
  local reason="$1"
  jq -n --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg reason "$reason" \
    --arg apiUrl "$API_URL" \
    '{ok:false,tier:"a",at:$at,apiUrl:$apiUrl,error:$reason}' > "$tmp_receipt"
  install -m 0600 "$tmp_receipt" "$receipt"
  ln -sfn "$(basename "$receipt")" "$STATE_DIR/latest.json"

  local alert_output=""
  if [ -r "$AF_LIB" ]; then
    # shellcheck source=/dev/null
    source "$AF_LIB"
    set +e
    alert_output="$(AF_SOURCE=teamkb-tailnet-canary af_dispatch \
      "Bob's Big Brain Tier-A tailnet canary failed: $reason" \
      "A synthetic teammate on the VPS could not prove the published plugin-to-brain path. Receipt: $receipt" \
      high sys-incidents 2>&1)"
    local alert_code=$?
    set -e
    printf '%s\n' "$alert_output" > "$STATE_DIR/last.alert"
    if [ "$alert_code" -ne 0 ]; then
      printf 'teamkb-tailnet-canary: alert-floor rejected failure receipt\n' >&2
    fi
  else
    printf 'teamkb-tailnet-canary: alert-floor missing at %s\n' "$AF_LIB" >&2
  fi
  printf 'teamkb-tailnet-canary: FAIL — %s; receipt=%s\n' "$reason" "$receipt" >&2
  exit 1
}

[ -x "$SOPS_BIN" ] || record_failure "sops is unavailable"
if [ -z "$NODE_BIN" ] || [ ! -x "$NODE_BIN" ]; then
  record_failure "node is unavailable"
fi
[ -r "$SECRETS_FILE" ] || record_failure "encrypted canary secret is unavailable"
[ -r "$PROBE" ] || record_failure "probe runtime is unavailable"
[ -r "$CJS" ] || record_failure "published plugin runtime is unavailable"

token="$($SOPS_BIN -d --output-type json "$SECRETS_FILE" 2>/dev/null \
  | jq -er '.teamkb_synthetic_probe_token | strings | select(length > 0)' 2>/dev/null)" \
  || record_failure "synthetic probe token could not be decrypted"
export TEAMKB_API_TOKEN="$token" TEAMKB_API_URL="$API_URL" TEAMKB_TENANT_ID="$TENANT_ID"

set +e
"$NODE_BIN" "$PROBE" --tier a --json --cjs "$CJS" > "$tmp_receipt" 2> "$stderr_file"
probe_code=$?
set -e
unset TEAMKB_API_TOKEN token

if [ "$probe_code" -ne 0 ] || ! jq -e '.ok == true and .tier == "a"' "$tmp_receipt" >/dev/null 2>&1; then
  detail="probe exit=$probe_code"
  if jq -e . "$tmp_receipt" >/dev/null 2>&1; then
    detail="$(jq -r '[.checks[]? | select(.pass == false) | .name] | if length == 0 then "probe receipt rejected" else join(",") end' "$tmp_receipt")"
  fi
  record_failure "$detail"
fi

jq --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {at:$at}' "$tmp_receipt" > "$receipt"
chmod 0600 "$receipt"
ln -sfn "$(basename "$receipt")" "$STATE_DIR/latest.json"
jq -n --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg receipt "$receipt" \
  '{at:$at,status:"pass",receipt:$receipt}' > "$STATE_DIR/last.ok"
rm -f "$stderr_file"
printf 'teamkb-tailnet-canary: PASS; receipt=%s\n' "$receipt"
