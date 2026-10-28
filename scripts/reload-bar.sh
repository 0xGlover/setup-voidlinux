#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if pgrep -u "$(id -u)" -x polybar >/dev/null; then
 pkill -u "$(id -u)" -x polybar
 for ((i=0; i<40; i++)); do
  pgrep -u "$(id -u)" -x polybar >/dev/null || break
  sleep 0.1
 done
fi
exec i3-msg -q "exec --no-startup-id bash \"$root/scripts/bar-start.sh\""
