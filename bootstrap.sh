#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
MODE=--plan
DESKTOP=i3
for arg in "$@"; do
 case "$arg" in
 --plan|--apply) MODE="$arg";;
 --desktop=i3) DESKTOP=i3;;
 --desktop=xfce) DESKTOP=xfce;;
 *) echo "Uso: bash bootstrap.sh [--plan|--apply] [--desktop=i3|xfce]"; exit 2;;
 esac
done
. /etc/os-release
[[ "${ID:-}" == void ]] || { echo "Apenas Void Linux"; exit 2; }
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$STATE"
LOG="$STATE/run-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG") 2>&1
trap 'rc=$?; echo "[ERRO] Linha $LINENO; status $rc; log $LOG"; exit "$rc"' ERR
common=(xorg dbus elogind polkit NetworkManager network-manager-applet pipewire wireplumber alsa-utils pavucontrol git curl pciutils usbutils)
if [[ "$DESKTOP" == i3 ]]; then
 desktop_packages=(i3 i3status polybar rofi dunst alacritty feh xinit thunar)
else
 desktop_packages=(xfce4 xfce4-terminal lightdm lightdm-gtk3-greeter)
fi
packages=("${common[@]}" "${desktop_packages[@]}")
echo "Modo: $MODE | desktop: $DESKTOP | log: $LOG"
printf 'Pacotes: %s\n' "${packages[*]}"
echo "Serviços previstos: dbus elogind NetworkManager (somente se sem conflitos)"
for s in dbus elogind NetworkManager lightdm dhcpcd wpa_supplicant wicd acpid; do
 [[ -L /var/service/$s ]] && echo "Já habilitado: $s" || true
done
if [[ "$DESKTOP" == i3 ]]; then bash "$(dirname "$0")/scripts/configure-desktop.sh" --plan; fi
[[ "$MODE" == --plan ]] && exit 0
[[ $EUID -ne 0 ]] || { echo "Execute como usuário normal com sudo"; exit 2; }
command -v sudo >/dev/null || { echo "sudo ausente"; exit 2; }
read -r -p "Digite APLICAR para instalar $DESKTOP: " answer
[[ "$answer" == APLICAR ]] || { echo "Cancelado"; exit 0; }
sudo xbps-install -Sy "${packages[@]}"
for s in dhcpcd wpa_supplicant wicd acpid; do
 if [[ -e /var/service/$s || -L /var/service/$s ]]; then
  echo "[BLOQUEIO] $s habilitado; preserve sua rede. Nenhum symlink runit novo será criado."
  exit 4
 fi
done
for s in dbus elogind NetworkManager; do
 [[ -d /etc/sv/$s ]] || { echo "Serviço ausente: $s"; exit 5; }
 if [[ -L /var/service/$s ]]; then
  [[ "$(readlink -f /var/service/$s)" == "$(readlink -f /etc/sv/$s)" ]] || { echo "Link conflitante: $s"; exit 6; }
  echo "Preservado: $s"
 elif [[ -e /var/service/$s ]]; then echo "Destino ocupado: $s"; exit 6
 else sudo ln -s "/etc/sv/$s" "/var/service/$s"; echo "Habilitado: $s"
 fi
done
if [[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ]]; then
 mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
 target="$HOME/.config/pipewire/pipewire.conf.d/10-wireplumber.conf"
 [[ -e "$target" || -L "$target" ]] || ln -s /usr/share/examples/wireplumber/10-wireplumber.conf "$target"
fi
if [[ "$DESKTOP" == i3 ]]; then
 bash "$(dirname "$0")/scripts/configure-desktop.sh" --apply
 if [[ ! -e "$HOME/.xinitrc" && ! -L "$HOME/.xinitrc" ]]; then
  printf '%s\n' 'exec dbus-run-session i3' > "$HOME/.xinitrc"
  echo "Criado ~/.xinitrc"
 else echo "Preservado ~/.xinitrc; configure startx manualmente se necessário"; fi
fi
for s in dbus elogind NetworkManager; do sudo sv status "$s" || true; done
echo "[OK] Concluído. i3: execute startx no TTY; XFCE: LightDM permanece desabilitado até validação."
