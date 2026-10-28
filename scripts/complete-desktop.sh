#!/usr/bin/env bash
# Apply the approved user configuration, after packages are installed separately.
set -euo pipefail
umask 077
mode="${1:---plan}"
[[ "$mode" == --plan || "$mode" == --apply ]] || exit 2
[[ $EUID != 0 ]] || { echo 'Execute como usuário comum.'; exit 2; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
missing=()
while IFS= read -r pkg; do
 if ! xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then missing+=("$pkg"); fi
done < "$root/packages/desktop-essential.txt"
if ((${#missing[@]})); then
 printf 'Pacotes pendentes: %s\n' "${missing[*]}"
 [[ "$mode" == --plan ]] && exit 0
 exit 3
fi
echo 'Plano: backup, tema atual + GTK escuro, interface PulseAudio, ambiente i3 e associações de mídia.'
[[ "$mode" == --plan ]] && exit 0
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
backup="$state/completion-backups/$(date -u +%Y%m%dT%H%M%S)-$$"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$backup"
for item in .xinitrc .config/mimeapps.list .local/share/applications/mimeapps.list; do
 if [[ -e "$HOME/$item" || -L "$HOME/$item" ]]; then
  mkdir -p "$backup/$(dirname "$item")"
  cp -a -- "$HOME/$item" "$backup/$item.link"
  cp -L -- "$HOME/$item" "$backup/$item"
 else
  mkdir -p "$backup/$(dirname "$item")"
  touch "$backup/$item.absent"
 fi
done
mkdir -p "$config/pipewire/pipewire.conf.d"
link="$config/pipewire/pipewire.conf.d/20-pipewire-pulse.conf"
if [[ -e "$link" || -L "$link" ]]; then
 cp -a -- "$link" "$backup/20-pipewire-pulse.conf.link"
 cp -L -- "$link" "$backup/20-pipewire-pulse.conf"
else
 ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf "$link"
fi
# Existing custom xinitrc is preserved; only the original installer form is edited.
python3 - <<'PY'
from pathlib import Path
p=Path.home()/'.xinitrc'
if p.exists() and p.read_text().strip() == 'exec dbus-run-session i3':
    p.write_text('export XDG_CURRENT_DESKTOP=i3\nexport XDG_SESSION_DESKTOP=i3\nexec dbus-run-session i3\n')
else:
    print('Preservado .xinitrc personalizado; confira XDG_CURRENT_DESKTOP=i3 manualmente.')
PY
theme=nord
[[ ! -f "$state/current-theme" ]] || read -r theme < "$state/current-theme"
bash "$root/scripts/theme.sh" "$theme" --apply
for mime in video/mp4 video/x-matroska video/webm audio/mpeg audio/flac audio/ogg audio/x-wav; do
 xdg-mime default mpv.desktop "$mime"
done
echo "Backup adicional: $backup"
echo 'Configuração concluída. Faça novo login no TTY para registrar a sessão no elogind.'
echo 'Após iniciar i3, teste wpctl status e pactl info; teste o bloqueio manual antes de habilitar xss-lock.'
