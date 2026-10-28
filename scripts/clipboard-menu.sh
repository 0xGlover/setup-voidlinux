#!/usr/bin/env bash
set -euo pipefail
if ! command -v clipmenu >/dev/null; then
 notify-send 'Clipboard' 'Instale o clipmenu com o script setup-desktop-extras.sh.' || true
 exit 1
fi
: "${XDG_RUNTIME_DIR:?Sessão sem diretório de runtime}"
export CM_DIR="$XDG_RUNTIME_DIR" CM_LAUNCHER=rofi
cache="$CM_DIR/clipmenu.6.$USER/line_cache"
if [[ ! -s "$cache" ]]; then
 notify-send 'Clipboard' 'Histórico vazio. Copie algum texto primeiro.' || true
 exit 0
fi
exec clipmenu -i -p 'Clipboard'
