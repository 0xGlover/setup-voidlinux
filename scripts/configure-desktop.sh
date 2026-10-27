#!/usr/bin/env bash
set -Eeuo pipefail
mode="${1:---plan}"
[[ "$mode" == --plan || "$mode" == --apply ]] || { echo "Use --plan ou --apply"; exit 2; }
[[ $EUID -ne 0 ]] || { echo "Execute como usuário normal"; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for app in i3 polybar rofi dunst alacritty; do
  source_file="$root/config/$app/$(case "$app" in i3) echo config;; polybar) echo config.ini;; rofi) echo config.rasi;; dunst) echo dunstrc;; alacritty) echo alacritty.toml;; esac)"
  target="$HOME/.config/$app/$(basename "$source_file")"
  if [[ -e "$target" || -L "$target" ]]; then
    echo "PRESERVAR $target"
  else
    echo "CRIAR $target"
    if [[ "$mode" == --apply ]]; then
      mkdir -p "$(dirname "$target")"
      ln -s "$source_file" "$target"
    fi
  fi
done
if [[ "$mode" == --apply ]]; then
  sudo mkdir -p /usr/share/backgrounds
  if [[ ! -e /usr/share/backgrounds/nord-solid.png ]]; then
    echo "Aviso: wallpaper não incluído; configure feh manualmente."
  fi
fi
