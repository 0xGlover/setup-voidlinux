#!/usr/bin/env bash
# User-session processes only. No runit, network or privileged changes.
set -u
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$state"
exec >> "$state/session.log" 2>&1
export XDG_CURRENT_DESKTOP=i3
export XDG_SESSION_DESKTOP=i3
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -d "$runtime" && ! -L "$runtime" && $(stat -c %u "$runtime") == "$(id -u)" && $(stat -c %a "$runtime") == 700 ]]; then
 export XDG_RUNTIME_DIR="$runtime"
 if command -v dbus-update-activation-environment >/dev/null; then
  dbus-update-activation-environment XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP
 fi
else
 unset XDG_RUNTIME_DIR
 printf '%s\n' 'Áudio adiado: sessão sem XDG_RUNTIME_DIR válido; faça novo login no TTY.'
fi
start_once() {
 local binary
 binary=$(command -v "$1") || { printf 'Ausente: %s\n' "$1"; return 0; }
 if ! pgrep -u "$(id -u)" -x "$(basename "$binary")" >/dev/null; then
  "$binary" "${@:2}" &
 fi
}
start_once xsettingsd
start_once dunst
# Keep clipboard history in the private session runtime directory.
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
 export CM_DIR="$XDG_RUNTIME_DIR" CM_SELECTIONS=clipboard CM_MAX_CLIPS=100
 start_once clipmenud
fi
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
 start_once pipewire
fi
agent=/usr/libexec/polkit-gnome-authentication-agent-1
if [[ -x "$agent" ]] && ! pgrep -u "$(id -u)" -f '^/usr/libexec/polkit-gnome-authentication-agent-1( |$)' >/dev/null; then
 "$agent" &
fi
# Automatic locking enabled by the user; X screensaver timeout is 10 minutes.
if [[ -f "$state/enable-sleep-lock" && -n "${XDG_RUNTIME_DIR:-}" ]]; then
 if command -v xset >/dev/null; then
  xset s 600 600 || printf '%s\n' 'Não foi possível configurar o tempo de bloqueio.'
 fi
 start_once xss-lock --transfer-sleep-lock -- i3lock --nofork --color=2e3440
fi
if command -v xdg-user-dirs-update >/dev/null; then xdg-user-dirs-update; fi
# Loading only our cursor resource avoids replacing other X resources.
if [[ -f "$HOME/.config/linux-autosetup/cursor.Xresources" ]]; then
 xrdb -merge "$HOME/.config/linux-autosetup/cursor.Xresources"
fi
