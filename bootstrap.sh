#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
mkdir -p "$STATE"
LOG="$STATE/run-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG") 2>&1
fail() { local rc=$?; echo "[ERRO] Linha $1, status $rc. Log: $LOG"; exit "$rc"; }
trap 'fail "$LINENO"' ERR
MODE="${1:---plan}"
[[ "$MODE" == --plan || "$MODE" == --apply ]] || { echo "Uso: bash bootstrap.sh [--plan|--apply]"; exit 2; }
[[ -f /etc/os-release ]] && . /etc/os-release
[[ "${ID:-}" == void ]] || { echo "Somente Void Linux."; exit 2; }
command -v xbps-install >/dev/null || { echo "XBPS ausente"; exit 2; }
echo "[INFO] Modo $MODE; usuário $(id -un); log $LOG"
echo "[INFO] Hardware:"
uname -a
for cmd in lscpu lsblk lspci lsusb free; do if command -v "$cmd" >/dev/null; then "$cmd" || echo "[AVISO] $cmd falhou"; else echo "[AVISO] $cmd indisponível"; fi; done
echo "[INFO] Plano: instalar base gráfica XFCE/LightDM, rede, áudio e utilitários; nenhum serviço será habilitado automaticamente."
pkgs=(xfce4 xfce4-terminal lightdm lightdm-gtk3-greeter dbus elogind NetworkManager pipewire wireplumber alsa-utils git curl pciutils usbutils)
if [[ "$MODE" == --plan ]]; then printf 'Pacotes: %s\n' "${pkgs[*]}"; exit 0; fi
[[ $EUID -ne 0 ]] || { echo "Execute com usuário normal e sudo disponível."; exit 2; }
command -v sudo >/dev/null || { echo "sudo é necessário no modo apply."; exit 2; }
read -r -p "Instalar os pacotes listados? Digite INSTALAR: " answer
[[ "$answer" == INSTALAR ]] || { echo "Cancelado, sem alterações."; exit 0; }
echo "[INFO] Verificando disponibilidade dos pacotes..."
for pkg in "${pkgs[@]}"; do xbps-query -Rs "^$pkg$" >/dev/null || { echo "[ERRO] Pacote não encontrado no índice: $pkg"; exit 3; }; done
echo "[INFO] Atualizando índices e instalando pacotes..."
sudo xbps-install -Sy "${pkgs[@]}"
echo "[INFO] Pacotes instalados. Serviços não foram ativados. Verifique dependências e habilite runit após auditoria."
echo "[OK] Log $LOG"
