#!/usr/bin/env bash
# Diagnostico seguro do backend grafico Niri no Void Linux
set -u
umask 077
OUT="${HOME}/niri-gpu-diagnostico-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$OUT") 2>&1
section() { printf '\n========== %s ==========\n' "$1"; }
run() { printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@" 2>&1 || printf '[AVISO] comando retornou codigo %s\n' "$?"; }
section 'SISTEMA'
run uname -a
run id
run niri --version
run xbps-query -p pkgver mesa
run xbps-query -p pkgver mesa-dri
run xbps-query -p pkgver niri
section 'SESSAO E ELOGIND'
printf 'XDG_RUNTIME_DIR=%s\nXDG_SESSION_ID=%s\nXDG_SESSION_TYPE=%s\n' "${XDG_RUNTIME_DIR:-<vazio>}" "${XDG_SESSION_ID:-<vazio>}" "${XDG_SESSION_TYPE:-<vazio>}"
run loginctl list-sessions
if [[ -n "${XDG_SESSION_ID:-}" ]]; then run loginctl show-session "$XDG_SESSION_ID" -p Active -p State -p Type -p Seat -p Remote; fi
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then run stat -c '%a %U %G %n' "$XDG_RUNTIME_DIR"; fi
section 'GPU / DRM'
if command -v lspci >/dev/null; then run lspci -nnk; else echo '[AVISO] lspci ausente'; fi
if [[ -d /dev/dri ]]; then run ls -la /dev/dri; for f in /dev/dri/card* /dev/dri/renderD*; do [[ -e "$f" ]] || continue; run stat -c '%n %a %U %G' "$f"; if [[ -r "$f" && -w "$f" ]]; then echo "[OK] leitura/escrita: $f"; else echo "[AVISO] sem acesso direto: $f"; fi; done; else echo '[ALERTA] /dev/dri nao existe'; fi
run lsmod
section 'OPENGL / EGL / VULKAN'
if command -v glxinfo >/dev/null; then glxinfo -B 2>&1 || echo '[AVISO] glxinfo requer DISPLAY/X11; falha no TTY nao prova ausencia de OpenGL'; else echo '[INFO] glxinfo nao instalado (pacote mesa-demos, se disponivel)'; fi
if command -v eglinfo >/dev/null; then eglinfo -B 2>&1 | head -n 110 || true; else echo '[INFO] eglinfo nao instalado'; fi
if command -v vulkaninfo >/dev/null; then vulkaninfo --summary 2>&1 | head -n 90 || true; else echo '[INFO] vulkaninfo nao instalado; Vulkan nao e requisito universal para este diagnostico'; fi
section 'LOG DO NIRI'
LOG="$HOME/.local/state/niri-dux/session.log"
if [[ -r "$LOG" ]]; then tail -n 100 "$LOG"; else echo "[INFO] log nao encontrado: $LOG"; fi
section 'KERNEL (SEM SUDO)'
if dmesg >/dev/null 2>&1; then dmesg | grep -Ei 'i915|drm|gpu|firmware|hang|fault' | tail -n 100 || true; else echo '[INFO] dmesg restrito; rode separadamente: sudo dmesg | grep -Ei "i915|drm|gpu|firmware" | tail -n 80'; fi
section 'RESUMO'
echo 'ATENCAO: glxinfo falhando em TTY e normal; nao classifique como defeito da GPU.'
echo 'DeviceMissing isoladamente nao identifica causa: correlacione DRM, sessao, EGL e kernel.'
echo "Relatorio salvo em: $OUT"
echo 'Revise o arquivo antes de compartilhar: pode conter nome de usuario, caminhos e identificadores do hardware.'
