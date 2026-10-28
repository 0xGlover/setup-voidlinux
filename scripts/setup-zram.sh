#!/usr/bin/env bash
# Install and enable Void's packaged zram service. No disk/boot/sysctl changes.
set -euo pipefail
if [[ ${1:-} != --root ]]; then
 [[ $EUID != 0 ]] || { echo 'Execute como usuário comum.'; exit 2; }
 xbps-install -n zramen
 exec sudo bash "$(readlink -f -- "$0")" --root
fi
[[ $EUID == 0 ]] || { echo 'A etapa de sistema exige root.'; exit 2; }
if awk 'NR>1 && $1 ~ /zram/ {found=1} END {exit !found}' /proc/swaps; then
 echo 'Já existe zram ativa; configuração preservada.'
 swapon --show
 exit 0
fi
if [[ -e /var/service/zramen || -L /var/service/zramen ]]; then
 echo 'O serviço zramen já está habilitado; configuração preservada. Verifique sudo sv status zramen.'
 exit 1
fi
xbps-install -y zramen
backup="/var/backups/linux-autosetup/zram-$(date -u +%Y%m%dT%H%M%S)-$$"
install -d -m 700 "$backup"
cp -a /etc/sv/zramen/conf "$backup/conf"
cat > /etc/sv/zramen/conf <<'CONF'
# Zram swap: 25% of RAM, capped at 2 GiB. Allocated as pages are used.
export ZRAM_COMP_ALGORITHM=lz4
export ZRAM_PRIORITY=100
export ZRAM_SIZE=25
export ZRAM_MAX_SIZE=2048
CONF
ln -s /etc/sv/zramen /var/service/zramen
sv -w 15 up /var/service/zramen
for ((i=0; i<20; i++)); do
 if awk 'NR>1 && $1 ~ /zram/ {found=1} END {exit !found}' /proc/swaps; then
  zramctl
  swapon --show
  echo "Zram ativada. Backup: $backup"
  exit 0
 fi
 sleep 0.5
done
echo "Zram não foi confirmada. Verifique sudo sv status zramen. Backup: $backup" >&2
exit 1
