#!/usr/bin/env bash
# Run inside the user's graphical terminal. Does not enable system services.
set -euo pipefail
[[ $EUID != 0 ]] || { echo 'Execute como usuário comum.'; exit 2; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
record="$state/package-records/extras-$(date -u +%Y%m%dT%H%M%S)-$$"
mkdir -p "$record"
xbps-query -l > "$record/installed-before.txt"
xbps-install -n flameshot clipmenu > "$record/transaction-plan.txt"
cat "$record/transaction-plan.txt"
sudo xbps-install -y flameshot clipmenu
xbps-query -l > "$record/installed-after.txt"
i3 -C -c "${XDG_CONFIG_HOME:-$HOME/.config}/i3/config"
setxkbmap -layout us -variant intl
i3-msg reload
i3-msg -q "exec --no-startup-id bash \"$root/scripts/session-start.sh\""
printf '%s\n' 'Ativado: Print ou Super+Shift+S; clipboard Super+Shift+V; energia Super+Shift+P; teclado US intl.'
