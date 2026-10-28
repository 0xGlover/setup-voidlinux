#!/usr/bin/env bash
set -euo pipefail
[[ $EUID != 0 ]] || { echo 'Execute como usuário comum.'; exit 2; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if ! xbps-query font-awesome >/dev/null 2>&1; then
 sudo xbps-install -y font-awesome
fi
fc-cache -f
family=$(fc-match -f '%{family}' FontAwesome)
[[ "$family" == *FontAwesome* ]] || { echo 'Fonte FontAwesome não encontrada.'; exit 1; }
exec bash "$root/scripts/reload-bar.sh"
