#!/usr/bin/env bash
# Only Rofi/Polybar: no services, network, i3 reload or display changes.
set -euo pipefail
umask 077
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
backup="$state/desktop-fix-backups/$(date -u +%Y%m%dT%H%M%S)-$$"
mkdir -p "$backup"
for item in rofi/config.rasi polybar/config.ini; do
 dest="${XDG_CONFIG_HOME:-$HOME/.config}/$item"
 mkdir -p "$backup/$(dirname "$item")"
 if [[ -e "$dest" || -L "$dest" ]]; then
  cp -a -- "$dest" "$backup/$item.link"
  cp -L -- "$dest" "$backup/$item"
 fi
 # Replace the existing target, preserving the installed symlink.
 mkdir -p "$(dirname "$dest")"
 cp -- "$root/config/$item" "$dest"
done
printf 'Backup: %s\n' "$backup"
