#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$state"
i3-msg reload
if pgrep -u "$(id -u)" -x xsettingsd >/dev/null; then
 pkill -HUP -u "$(id -u)" -x xsettingsd
fi
if command -v dunstctl >/dev/null; then dunstctl reload || true; fi
# Stop only this user's bar; wait for tray ownership to be released.
if pgrep -u "$(id -u)" -x polybar >/dev/null; then
 pkill -u "$(id -u)" -x polybar
 for ((i=0; i<40; i++)); do
  pgrep -u "$(id -u)" -x polybar >/dev/null || break
  sleep 0.1
 done
fi
# Launch through i3 so processes belong to the graphical session.
i3-msg -q "exec --no-startup-id bash \"$root/scripts/bar-start.sh\""
i3-msg -q "exec --no-startup-id bash \"$root/scripts/session-start.sh\""
