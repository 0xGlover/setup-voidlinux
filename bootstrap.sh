#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
MODE="${1:---plan}"
[[ "$MODE" == --plan || "$MODE" == --apply ]] || { echo "Uso: bash bootstrap.sh --plan|--apply"; exit 2; }
. /etc/os-release
[[ "${ID:-}" == void ]] || { echo "Apenas Void Linux"; exit 2; }
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$STATE"
LOG="$STATE/run-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG") 2>&1
trap 'rc=$?; echo "[ERRO] Linha $LINENO; status $rc; log $LOG"; exit "$rc"' ERR
packages=(xorg xfce4 xfce4-terminal lightdm lightdm-gtk3-greeter dbus elogind polkit NetworkManager network-manager-applet pipewire wireplumber alsa-utils pavucontrol git curl pciutils usbutils)
echo "Modo: $MODE | log: $LOG"
printf 'Pacotes: %s\n' "${packages[*]}"
echo "Serviços: dbus, elogind, NetworkManager; LightDM somente após teste."
for s in dbus elogind NetworkManager lightdm dhcpcd wpa_supplicant wicd acpid; do
  [[ -L /var/service/$s ]] && echo "Já habilitado: $s" || true
done
[[ "$MODE" == --plan ]] && exit 0
[[ $EUID -ne 0 ]] || { echo "Execute como usuário normal com sudo"; exit 2; }
command -v sudo >/dev/null || { echo "sudo ausente"; exit 2; }
read -r -p "Digite APLICAR para instalar: " answer
[[ "$answer" == APLICAR ]] || { echo "Cancelado"; exit 0; }
sudo xbps-install -Sy "${packages[@]}"
for s in dhcpcd wpa_supplicant wicd acpid; do
  if [[ -e /var/service/$s || -L /var/service/$s ]]; then
    echo "[BLOQUEIO] Serviço concorrente: $s. Nenhum symlink novo será criado."
    exit 4
  fi
done
for s in dbus elogind NetworkManager; do
  [[ -d /etc/sv/$s ]] || { echo "[ERRO] Serviço não existe: $s"; exit 5; }
  if [[ -L /var/service/$s ]]; then
    [[ "$(readlink -f /var/service/$s)" == "$(readlink -f /etc/sv/$s)" ]] || { echo "Link conflitante: $s"; exit 6; }
    echo "Preservado: $s"
  elif [[ -e /var/service/$s ]]; then
    echo "Destino ocupado: $s"; exit 6
  else
    sudo ln -s "/etc/sv/$s" "/var/service/$s"
    echo "Habilitado: $s"
  fi
done
if [[ -f /usr/share/examples/wireplumber/10-wireplumber.conf ]]; then
  mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
  target="$HOME/.config/pipewire/pipewire.conf.d/10-wireplumber.conf"
  [[ -e "$target" || -L "$target" ]] || ln -s /usr/share/examples/wireplumber/10-wireplumber.conf "$target"
fi
for s in dbus elogind NetworkManager; do sudo sv status "$s" || true; done
echo "[OK] Serviços base configurados. LightDM ainda não habilitado; valide Xorg antes."
echo "Habilitação posterior: sudo ln -s /etc/sv/lightdm /var/service/lightdm"
