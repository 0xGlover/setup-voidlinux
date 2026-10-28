#!/usr/bin/env bash
set -euo pipefail
choose() { rofi -dmenu -i -no-custom -p "$1"; }
confirm() {
 local answer
 answer=$(printf 'Cancelar\nConfirmar\n' | choose "$1") || return 1
 [[ "$answer" == Confirmar ]]
}
action=$(printf 'Bloquear\nSuspender\nSair do i3\nReiniciar\nDesligar\n' | choose 'Energia') || exit 0
case "$action" in
 Bloquear) exec i3lock --color=2e3440 ;;
 Suspender)
  # Use the session sleep inhibitor when available; otherwise lock first.
  if pgrep -u "$(id -u)" -x xss-lock >/dev/null; then
   loginctl suspend
  else
   i3lock --color=2e3440 && loginctl suspend
  fi ;;
 'Sair do i3') if confirm 'Encerrar sessão?'; then i3-msg exit; fi ;;
 Reiniciar) if confirm 'Reiniciar?'; then loginctl reboot; fi ;;
 Desligar) if confirm 'Desligar?'; then loginctl poweroff; fi ;;
esac
