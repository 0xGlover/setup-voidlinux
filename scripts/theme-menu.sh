#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
choice=$(printf '%s\n' nord gruvbox solarized | rofi -dmenu -i -p Tema) || exit 0
case "$choice" in nord|gruvbox|solarized) ;; *) exit 0;; esac
bash "$root/scripts/theme.sh" "$choice" --apply
bash "$root/scripts/reload-desktop.sh"
