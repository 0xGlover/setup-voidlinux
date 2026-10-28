#!/usr/bin/env bash
set -euo pipefail

if (( EUID == 0 )); then
    echo 'Execute como seu usuário normal, sem sudo antes do script.' >&2
    exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
    sudo xbps-install -S flatpak
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub md.obsidian.Obsidian net.ankiweb.Anki

flatpak info --user md.obsidian.Obsidian
flatpak info --user net.ankiweb.Anki
echo 'Instalação concluída. Para abrir:'
echo 'flatpak run md.obsidian.Obsidian'
echo 'flatpak run net.ankiweb.Anki'
echo 'Se os aplicativos não aparecerem no menu, encerre a sessão e entre novamente.'
