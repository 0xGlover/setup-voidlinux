#!/usr/bin/env bash
# Recuperação conservadora do Niri Dux. Não altera rede, drivers nem configuração do usuário.
set -uo pipefail
umask 077
[[ ${EUID} -ne 0 ]] || { echo 'Execute como usuário comum.'; exit 2; }
[[ -f /etc/os-release ]] || exit 2
source /etc/os-release
[[ ${ID:-} == void ]] || { echo 'Somente Void Linux.'; exit 2; }
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/niri-dux"
mkdir -p "$STATE"
LOG="$STATE/recovery-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
APPLY=0
case ${1:---plan} in --plan) ;; --apply) APPLY=1;; *) echo 'Uso: bash recover.sh [--plan|--apply]'; exit 2;; esac
fail=0; warn=0
info(){ printf '[INFO] %s\n' "$*"; }
issue(){ printf '[PENDENTE] %s\n' "$*"; ((warn+=1)); }
error(){ printf '[FALHA] %s\n' "$*"; ((fail+=1)); }
if ((APPLY)); then
  command -v sudo >/dev/null || { error 'sudo ausente'; exit 2; }
  sudo -v || exit 2
fi
info 'Pacotes fundamentais'
for pkg in dbus elogind chrony socklog-void niri pipewire wireplumber dms quickshell; do
  if xbps-query -p pkgver "$pkg" >/dev/null 2>&1; then info "$pkg instalado"; else issue "$pkg ausente"; fi
done
info 'Serviços runit (somente serviços cujos pacotes já existem)'
for svc in dbus elogind chronyd socklog-unix nanoklogd; do
  if [[ ! -d /etc/sv/$svc ]]; then issue "$svc: diretório /etc/sv ausente"; continue; fi
  if [[ -L /var/service/$svc ]]; then
    if [[ $(readlink -f "/var/service/$svc") != $(readlink -f "/etc/sv/$svc") ]]; then error "$svc: link aponta para outro destino"; continue; fi
  elif [[ -e /var/service/$svc ]]; then error "$svc: destino ocupado, não alterado"; continue
  else
    issue "$svc: não habilitado"
    if ((APPLY)); then
      if sudo ln -s "/etc/sv/$svc" "/var/service/$svc"; then info "$svc: link criado"; else error "$svc: falha ao criar link"; continue; fi
    else continue; fi
  fi
  if ((APPLY)); then
    sudo sv -w 10 up "$svc" && info "$svc: ativo" || error "$svc: não iniciou em 10 segundos"
  else
    sv status "$svc" || issue "$svc: não está ativo"
  fi
done
info 'Sessão e configuração'
if [[ -n ${XDG_RUNTIME_DIR:-} && -d ${XDG_RUNTIME_DIR:-/nonexistent} ]]; then
  info "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
else issue 'Sessão elogind sem XDG_RUNTIME_DIR; sair e entrar novamente no TTY'; fi
if command -v niri >/dev/null; then
  if [[ -f $HOME/.config/niri/config.kdl ]]; then
    niri validate -c "$HOME/.config/niri/config.kdl" || error 'Configuração Niri inválida'
  else issue 'Configuração Niri ausente'; fi
fi
info 'Dispositivos DRM'
if [[ -d /dev/dri ]]; then ls -l /dev/dri; else issue '/dev/dri ausente'; fi
if command -v lspci >/dev/null; then lspci -nnk | grep -A 3 -Ei 'VGA|3D|Display' || :; fi
info "Relatório: $LOG"
printf 'Resumo: %d falhas, %d pendências/avisos\n' "$fail" "$warn"
info 'O erro DeviceMissing exige investigação separada; este script não modifica GPU nem inicia o Niri.'
((fail==0)) || exit 1
