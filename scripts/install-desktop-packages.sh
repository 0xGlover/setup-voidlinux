#!/usr/bin/env bash
# Package installation only; does not enable runit services or change networking.
set -euo pipefail
umask 077
mode="${1:---plan}"
[[ "$mode" == --plan || "$mode" == --apply ]] || exit 2
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mapfile -t packages < "$root/packages/desktop-essential.txt"
if [[ "$mode" == --plan ]]; then
 exec xbps-install -n "${packages[@]}"
fi
[[ $EUID != 0 ]] || { echo 'Execute como usuário comum; o script solicita sudo.'; exit 2; }
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
backup="$state/package-records/$(date -u +%Y%m%dT%H%M%S)-$$"
mkdir -p "$backup"
xbps-query -l > "$backup/installed-before.txt"
xbps-install -n "${packages[@]}" > "$backup/transaction-plan.txt"
sudo xbps-install -y "${packages[@]}"
xbps-query -l > "$backup/installed-after.txt"
echo "Registro de pacotes: $backup"
