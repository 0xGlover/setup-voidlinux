#!/usr/bin/env bash
set -euo pipefail
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$state"
# Lock startup to prevent simultaneous launches from reload and session startup.
exec 9> "$state/polybar-start.lock"
flock -n 9 || exit 0
pgrep -u "$(id -u)" -x polybar >/dev/null && exit 0
# i3 starts audio asynchronously; give its PulseAudio interface time to appear.
if [[ -n "${XDG_RUNTIME_DIR:-}" ]] && command -v pactl >/dev/null; then
 for ((i=0; i<50; i++)); do
  pactl info >/dev/null 2>&1 && break
  sleep 0.1
 done
fi
exec polybar main >> "$state/polybar.log" 2>&1
