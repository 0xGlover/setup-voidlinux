#!/usr/bin/env bash
set -euo pipefail
if ! command -v flameshot >/dev/null; then
 notify-send 'Captura de tela' 'Instale o Flameshot com o script setup-desktop-extras.sh.' || true
 exit 1
fi
exec flameshot gui
