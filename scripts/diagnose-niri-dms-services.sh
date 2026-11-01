#!/usr/bin/env bash
set -Eeuo pipefail
# Diagnóstico não destrutivo para Void Linux/runit antes de instalar Niri + DMS.
[[ -r /etc/os-release ]] || { echo "Não foi possível identificar o sistema."; exit 2; }
. /etc/os-release
[[ "${ID:-}" == "void" ]] || { echo "Este diagnóstico exige Void Linux."; exit 2; }
echo "== Serviços runit relevantes =="
for s in acpid elogind dbus seatd NetworkManager dhcpcd wpa_supplicant; do
  if [[ -L "/var/service/$s" ]]; then
    echo "[HABILITADO] $s -> $(readlink -f "/var/service/$s")"
    if command -v sv >/dev/null 2>&1; then sv status "$s" || true; fi
  elif [[ -e "/var/service/$s" ]]; then
    echo "[ATENÇÃO] $s: caminho ocupado (não é link simbólico)"
  else
    echo "[DESABILITADO] $s"
  fi
done
echo "== Pacotes presentes =="
for p in niri elogind acpid seatd dbus quickshell; do
  if xbps-query -p pkgver "$p" 2>/dev/null; then :; else echo "[AUSENTE] $p"; fi
done
echo "== Sessão =="
printf 'XDG_SESSION_TYPE=%s\nXDG_CURRENT_DESKTOP=%s\n' "${XDG_SESSION_TYPE:-}" "${XDG_CURRENT_DESKTOP:-}"
echo "== Recomendação =="
if [[ -L /var/service/acpid && -L /var/service/elogind ]]; then
  echo "[REVISAR] acpid e elogind habilitados. Verifique eventos ACPI e duplicidade antes de alterar serviços."
elif [[ -L /var/service/acpid ]]; then
  echo "[REVISAR] acpid habilitado. Não será desativado automaticamente."
else
  echo "[OK] Nenhum acpid habilitado via /var/service foi detectado."
fi
echo "Nenhum pacote, configuração ou serviço foi modificado."
