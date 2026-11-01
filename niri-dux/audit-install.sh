#!/usr/bin/env bash
# Auditoria read-only para a instalacao Niri+DMS do setup-voidlinux.
set -uo pipefail
BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BASE/lib/hardware.sh"
detect_hardware
select_hardware_packages
PACKAGES=(bash-completion ca-certificates curl git pciutils usbutils util-linux procps-ng glibc-locales dbus elogind polkit NetworkManager chrony socklog-void pipewire wireplumber alsa-utils alsa-pipewire pavucontrol pulseaudio-utils niri xwayland-satellite xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk qt6-wayland qt6-multimedia alacritty Thunar gvfs udisks2 tumbler file-roller unzip zip xdg-utils xdg-user-dirs firefox mpv ffmpeg playerctl brightnessctl noto-fonts-ttf noto-fonts-emoji dejavu-fonts-ttf adwaita-icon-theme dms quickshell matugen "${HARDWARE_PACKAGES[@]}")
SERVICES=(dbus elogind chronyd socklog-unix nanoklogd)
(( BLUETOOTH == 0 )) || { PACKAGES+=(bluez libspa-bluetooth); SERVICES+=(bluetoothd); }
if (( RAM_MIB <= 16384 )); then PACKAGES+=(zramen); SERVICES+=(zramen); fi
if (( SSD )); then PACKAGES+=(cronie); SERVICES+=(cronie); fi
if [[ $CPU_VENDOR == GenuineIntel ]]; then PACKAGES+=(void-repo-nonfree intel-ucode); fi
mapfile -t PACKAGES < <(printf '%s\n' "${PACKAGES[@]}" | sort -u)
MISSING=() ISSUES=()
ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[ATENCAO] %s\n' "$*"; ISSUES+=("$*"); }
echo '=== AUDITORIA NIRI + DMS (SOMENTE LEITURA) ==='
echo 'Perfil comparado: install.sh --apply --network=keep, zram auto, power kernel, microcode Intel.'
echo 'Nao altera arquivos, pacotes, servicos ou rede.'
printf 'GPU: %s | RAM: %s MiB | usuario: %s\n' "${GPU_IDS[*]:-desconhecida}" "$RAM_MIB" "$(id -un)"
echo
echo '--- PACOTES ---'
for p in "${PACKAGES[@]}"; do
  if xbps-query -p pkgver "$p" >/dev/null 2>&1; then ok "$p"; else warn "Pacote ausente: $p"; MISSING+=("$p"); fi
done
echo
echo '--- SERVICOS ---'
for s in "${SERVICES[@]}"; do
  if [[ ! -d /etc/sv/$s ]]; then warn "Definicao de servico ausente: $s"; continue; fi
  if [[ ! -L /var/service/$s ]]; then warn "Servico nao habilitado: $s"; continue; fi
  if [[ $(readlink -f "/var/service/$s") != "$(readlink -f "/etc/sv/$s")" ]]; then warn "Link incorreto: $s"; continue; fi
  if sv status "$s" 2>&1 | grep -q '^run:'; then ok "Servico ativo: $s"; else warn "Servico nao ativo: $s"; fi
done
echo
echo '--- CONFIGURACAO E SESSAO ---'
if [[ -f $HOME/.config/niri/config.kdl ]]; then
  if niri validate -c "$HOME/.config/niri/config.kdl"; then ok 'Configuracao Niri valida'; else warn 'Configuracao Niri invalida'; fi
else warn 'Configuracao Niri ausente'; fi
for f in start-niri-dux niri-dux-autostart niri-dux-check; do
  if [[ -x $HOME/.local/bin/$f ]]; then ok "Executavel: $f"; else warn "Executavel ausente: $f"; fi
done
if [[ -n ${XDG_RUNTIME_DIR:-} && -d ${XDG_RUNTIME_DIR:-/nonexistent} ]]; then ok "Runtime: $XDG_RUNTIME_DIR"; else warn 'XDG_RUNTIME_DIR ausente'; fi
loginctl list-sessions 2>&1 || warn 'Falha ao consultar sessoes elogind'
echo
echo '--- GRAFICOS / DRM ---'
lspci -nnk 2>/dev/null | grep -A 4 -Ei 'VGA|3D|Display' || true
ls -l /dev/dri/ 2>&1 || warn 'Dispositivos /dev/dri ausentes'
if [[ -e /dev/dri/card0 ]]; then
  if [[ -r /dev/dri/card0 && -w /dev/dri/card0 ]]; then ok 'Acesso ao card0 nesta sessao'; else warn 'card0 sem acesso direto nesta sessao (ACL elogind deve ser verificada)'; fi
fi
if [[ -f $HOME/.local/state/niri-dux/session.log ]]; then
  echo '--- ERROS RECENTES DA SESSAO ---'
  grep -Ei 'DeviceMissing|ERROR|failed|permission denied' "$HOME/.local/state/niri-dux/session.log" | tail -n 25 || true
fi
echo
echo '--- RESUMO ---'
printf 'Pacotes ausentes: %s\n' "${#MISSING[@]}"
if (( ${#MISSING[@]} )); then printf '  %s\n' "${MISSING[@]}"; fi
printf 'Alertas totais: %s\n' "${#ISSUES[@]}"
printf 'Auditoria concluida. Nenhuma correcao foi aplicada.\n'
