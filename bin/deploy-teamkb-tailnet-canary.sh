#!/usr/bin/env bash
# Deploy the published team-mode plugin and Tier-A canary to a separate tailnet node.
set -euo pipefail
umask 077

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="${TEAMKB_CANARY_HOST:-${1:-intentsolutions}}"
PLUGIN_VERSION="${TEAMKB_CANARY_PLUGIN_VERSION:-1.2.0}"
SECRETS_SRC="${TEAMKB_CANARY_SECRETS_SRC:-$HOME/.config/intentsolutions/secrets.prod.sops.yaml}"
INTENT_OS_DIR="${INTENT_OS_DIR:-$HOME/000-projects/intent-os}"
ALERT_FLOOR_SRC="${AF_NOTIFY_ALERT_FLOOR_SRC:-$INTENT_OS_DIR/ops/alert-floor/alert-floor.sh}"
BUZZ_NOTIFY_SRC="${BUZZ_NOTIFY_SRC:-$INTENT_OS_DIR/ops/buzz/notify/buzz-notify.sh}"

for required in \
  "$REPO_DIR/bin/teamkb-tailnet-probe.mjs" \
  "$REPO_DIR/bin/teamkb-tailnet-canary.sh" \
  "$REPO_DIR/systemd/user/teamkb-tailnet-canary.service" \
  "$REPO_DIR/systemd/user/teamkb-tailnet-canary.timer" \
  "$SECRETS_SRC" "$ALERT_FLOOR_SRC" "$BUZZ_NOTIFY_SRC"; do
  [ -r "$required" ] || { printf 'deploy-teamkb-tailnet-canary: missing %s\n' "$required" >&2; exit 1; }
done

remote_stage="$(ssh -o BatchMode=yes "$REMOTE_HOST" 'mktemp -d /tmp/bbb-tailnet-canary.XXXXXX')"
case "$remote_stage" in
  /tmp/bbb-tailnet-canary.*) ;;
  *) printf 'deploy-teamkb-tailnet-canary: unsafe remote staging path: %s\n' "$remote_stage" >&2; exit 1 ;;
esac

cleanup() {
  ssh -o BatchMode=yes "$REMOTE_HOST" "find '$remote_stage' -mindepth 1 -delete && rmdir '$remote_stage'" >/dev/null 2>&1 || true
}
trap cleanup EXIT

rsync -a \
  "$REPO_DIR/bin/teamkb-tailnet-probe.mjs" \
  "$REPO_DIR/bin/teamkb-tailnet-canary.sh" \
  "$REPO_DIR/systemd/user/teamkb-tailnet-canary.service" \
  "$REPO_DIR/systemd/user/teamkb-tailnet-canary.timer" \
  "$SECRETS_SRC" \
  "$ALERT_FLOOR_SRC" \
  "$BUZZ_NOTIFY_SRC" \
  "$REMOTE_HOST:$remote_stage/"

ssh -o BatchMode=yes "$REMOTE_HOST" bash -s -- "$remote_stage" "$PLUGIN_VERSION" <<'REMOTE'
set -euo pipefail
umask 077
stage="$1"
version="$2"
release="$HOME/.local/opt/bbb-tailnet-canary/releases/governed-second-brain-$version"
current="$HOME/.local/opt/bbb-tailnet-canary/current"

mkdir -p "$HOME/.local/lib/bbb-canary" "$HOME/.local/opt/bbb-tailnet-canary/releases" \
  "$HOME/.config/systemd/user" "$HOME/.config/intentsolutions" "$HOME/bin/lib" "$HOME/bin"

if [ ! -r "$release/node_modules/governed-second-brain/plugin-runtime/governed-brain.cjs" ]; then
  mkdir -p "$release"
  npm install --prefix "$release" --omit=dev --ignore-scripts --no-audit --no-fund \
    "governed-second-brain@$version"
fi

ln -sfn "$release" "$current.next"
mv -Tf "$current.next" "$current"
install -m 0755 "$stage/teamkb-tailnet-probe.mjs" "$HOME/.local/lib/bbb-canary/teamkb-tailnet-probe.mjs"
install -m 0755 "$stage/teamkb-tailnet-canary.sh" "$HOME/.local/lib/bbb-canary/teamkb-tailnet-canary.sh"
install -m 0644 "$stage/teamkb-tailnet-canary.service" "$HOME/.config/systemd/user/teamkb-tailnet-canary.service"
install -m 0644 "$stage/teamkb-tailnet-canary.timer" "$HOME/.config/systemd/user/teamkb-tailnet-canary.timer"
install -m 0600 "$stage/secrets.prod.sops.yaml" "$HOME/.config/intentsolutions/secrets.prod.sops.yaml"
install -m 0755 "$stage/alert-floor.sh" "$HOME/bin/lib/alert-floor.sh"
install -m 0755 "$stage/buzz-notify.sh" "$HOME/bin/buzz-notify.sh"

# The host already owns the canonical notifier identity under /etc. Give the
# unprivileged user service a mode-0600 copy; never print or transmit its value.
sudo -n install -m 0600 -o "$(id -un)" -g "$(id -gn)" \
  /etc/intentsolutions/buzz-notify.env "$HOME/.config/intentsolutions/buzz-notify.env"

systemctl --user daemon-reload
systemctl --user enable teamkb-tailnet-canary.timer >/dev/null
REMOTE

printf 'Deployed Bob\047s Big Brain Tier-A canary to %s (plugin %s).\n' "$REMOTE_HOST" "$PLUGIN_VERSION"
printf 'Run proof: ssh %s systemctl --user start teamkb-tailnet-canary.service\n' "$REMOTE_HOST"
