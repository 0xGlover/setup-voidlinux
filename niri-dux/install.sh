#!/usr/bin/env bash
# Void post-install for a normal user on a freshly installed, booted system.
set -Eeuo pipefail
umask 077
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib/hardware.sh
source "$BASE/lib/hardware.sh"
MODE=plan KEYBOARD=br LOCALE=pt_BR.UTF-8 TIMEZONE=America/Sao_Paulo
NETWORK=manager ZRAM=auto POWER=kernel ALLOW_NOUVEAU=0 MICROCODE=1
usage() {
    cat <<'EOF'
Uso: bash install.sh [--plan|--apply] [opções]
  --plan                  Apenas inventário/plano (padrão; não grava arquivos)
  --apply                 Instalar/configurar, como usuário comum com sudo
  --keyboard=br|us|...     Layout XKB (padrão br)
  --locale=pt_BR.UTF-8     Locale glibc
  --timezone=America/Sao_Paulo
  --network=manager|keep   NetworkManager ou preservar serviços de rede atuais
  --no-zram               Não preparar zram (auto: RAM até 16 GiB)
  --power=kernel|tlp      Padrões do kernel ou TLP se houver bateria
  --no-microcode          Não adicionar nonfree/intel-ucode em CPU Intel
  --allow-nouveau         Aceitar Mesa/Nouveau em NVIDIA (não escolhe driver proprietário)
  --help
EOF
}
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }
note() { printf '[INFO] %s\n' "$*"; }
for arg in "$@"; do
    case $arg in
        --plan) MODE=plan;; --apply) MODE=apply;;
        --keyboard=*) KEYBOARD=${arg#*=};; --locale=*) LOCALE=${arg#*=};;
        --timezone=*) TIMEZONE=${arg#*=};;
        --network=manager|--network=keep) NETWORK=${arg#*=};;
        --no-zram) ZRAM=no;; --power=kernel|--power=tlp) POWER=${arg#*=};;
        --no-microcode) MICROCODE=0;; --allow-nouveau) ALLOW_NOUVEAU=1;;
        --help|-h) usage; exit 0;; *) usage; die "Opção desconhecida: $arg";;
    esac
done
[[ $KEYBOARD =~ ^[a-z][a-z0-9_-]*$ ]] || die 'Layout XKB inválido.'
[[ $LOCALE =~ ^[a-z]{2}_[A-Z]{2}\.UTF-8$ ]] || die 'Use um locale como pt_BR.UTF-8.'
[[ $TIMEZONE != /* && $TIMEZONE != *..* && -f /usr/share/zoneinfo/$TIMEZONE ]] || die 'Fuso horário inválido.'
source /etc/os-release
[[ ${ID:-} == void ]] || die 'Este script é apenas para Void Linux.'
command -v xbps-query >/dev/null || die 'XBPS ausente.'
ARCH=$(xbps-uhelper arch)
[[ $ARCH == x86_64 ]] || die "Validado para Void x86_64 glibc. Arquitetura atual: $ARCH."
[[ $EUID != 0 ]] || die 'Execute com usuário comum; use sudo apenas quando o script pedir.'
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/niri-dux
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/niri-dux
detect_hardware
select_hardware_packages
PACKAGES=(bash-completion ca-certificates curl git pciutils usbutils util-linux procps-ng glibc-locales
    dbus elogind polkit NetworkManager chrony socklog-void
    pipewire wireplumber alsa-utils alsa-pipewire pavucontrol pulseaudio-utils
    niri xwayland-satellite xdg-desktop-portal xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk qt6-wayland qt6-multimedia
    alacritty Thunar gvfs udisks2 tumbler file-roller unzip zip
    xdg-utils xdg-user-dirs firefox mpv ffmpeg playerctl brightnessctl
    noto-fonts-ttf noto-fonts-emoji dejavu-fonts-ttf adwaita-icon-theme
    dms quickshell matugen "${HARDWARE_PACKAGES[@]}")
SERVICES=(dbus elogind chronyd socklog-unix nanoklogd)
(( ! BLUETOOTH )) || SERVICES+=(bluetoothd)
if [[ $ZRAM == auto && $RAM_MIB -le 16384 ]]; then
    PACKAGES+=(zramen); SERVICES+=(zramen)
else ZRAM=no; fi
if [[ $POWER == tlp && $BATTERY == 1 ]]; then
    PACKAGES+=(tlp); SERVICES+=(tlp)
fi
if (( SSD )); then PACKAGES+=(cronie); SERVICES+=(cronie); fi
# Remove duplicate packages while retaining stable order.
mapfile -t PACKAGES < <(printf '%s\n' "${PACKAGES[@]}" | awk '!seen[$0]++')
printf 'Modo: %s | Void: %s | usuário: %s\n' "$MODE" "$ARCH" "$(id -un)"
printf 'CPU: %s (%s)\nRAM: %s MiB | GPUs: %s\n' "$CPU_MODEL" "$CPU_VENDOR" "$RAM_MIB" "${GPU_IDS[*]:-não detectada}"
printf 'Intel legado: %s | bateria: %s | Bluetooth: %s | disco não rotacional: %s\n' "$INTEL_LEGACY" "$BATTERY" "$BLUETOOTH" "$SSD"
printf 'Locale: %s | fuso: %s | teclado gráfico: %s\n' "$LOCALE" "$TIMEZONE" "$KEYBOARD"
printf 'Rede: %s | zram: %s | energia: %s\n' "$NETWORK" "$ZRAM" "$POWER"
printf 'Pacotes:\n  %s\nServiços runit:\n  %s\n' "${PACKAGES[*]}" "${SERVICES[*]}"
if [[ $CPU_VENDOR == GenuineIntel && $MICROCODE == 1 ]]; then
    note 'Inclui void-repo-nonfree + intel-ucode e reconstrução do initramfs.'
fi
note 'Repositórios externos: https://void.duxlabs.dev/{dms,dux-repo}/current (canal estável).'
note 'XBPS solicitará confiança nas chaves dos repositórios; assinaturas não serão desativadas.'
note 'Links: serviços /etc/sv -> /var/service; PipeWire/ALSA e comandos locais de sessão.'
note 'Configuração Niri sem animações no Intel legado; monitores usam seleção automática de modo.'
note 'Não altera partições, não remove pacotes e não inicia sessão gráfica automaticamente.'
if [[ $NETWORK == manager ]]; then
    note 'Ao final, substitui serviços dhcpcd/wpa_supplicant/iwd/ConnMan por NetworkManager.'
    note 'A rede pode cair; Wi-Fi poderá exigir reconexão com nmtui.'
fi
if (( GPU_NVIDIA && ! ALLOW_NOUVEAU )); then
    note 'NVIDIA: aplicação bloqueada até escolher o driver; --allow-nouveau aceita a opção aberta.'
fi
for service in /var/service/*; do
    [[ -e $service || -L $service ]] || continue
    printf 'Já habilitado: %s\n' "${service##*/}"
done
[[ $MODE == apply ]] || exit 0

# Preconditions run before the first write or sudo command.
[[ -t 0 && -z ${SSH_CONNECTION:-} && -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || die 'Aplique em TTY local, fora de SSH e da sessão gráfica.'
(( ! GPU_NVIDIA || ALLOW_NOUVEAU )) || die 'NVIDIA exige escolha explícita; consulte README.md.'
command -v sudo >/dev/null || die 'Instale sudo e autorize seu usuário primeiro (README.md).'
# acpid is common on stock Void; its presence alone does not prove a conflict.
if [[ -e /var/service/acpid || -L /var/service/acpid ]]; then
    note 'acpid habilitado: preservado. Revise possíveis eventos ACPI duplicados após iniciar elogind.'
fi
for service in seatd turnstiled lightdm gdm sddm greetd; do
    [[ ! -e /var/service/$service && ! -L /var/service/$service ]] || die "Serviço conflitante: $service. Use uma instalação limpa ou revise manualmente."
done
if [[ ! -f $STATE/managed ]]; then
    for path in "$CONFIG/niri/config.kdl" "$CONFIG/i3/config" "$HOME/.xinitrc"; do
        [[ ! -e $path && ! -L $path ]] || die "Configuração gráfica existente: $path. Este instalador é para uma base limpa."
    done
    if [[ -f $HOME/.bash_profile ]]; then
        if grep -Eq 'startx|niri|Hyprland|sway|XDG_CURRENT_DESKTOP' "$HOME/.bash_profile"; then
            die 'Inicialização gráfica encontrada em .bash_profile; use uma instalação limpa.'
        fi
    fi
fi
if xbps-query -p pkgver pulseaudio >/dev/null 2>&1; then die 'Servidor PulseAudio instalado; este perfil usa PipeWire.'; fi
for service in ntpd openntpd ntp; do
    [[ ! -e /var/service/$service && ! -L /var/service/$service ]] || die "Sincronizador concorrente: $service."
done
if [[ $POWER == tlp ]]; then
    for service in power-profiles-daemon auto-cpufreq laptop-mode; do
        [[ ! -e /var/service/$service && ! -L /var/service/$service ]] || die "Gerenciador de energia concorrente: $service."
    done
fi
sudo -v
mkdir -p "$STATE" "$DATA" "$CONFIG"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)-$$
BACKUP=$STATE/backups/$STAMP
mkdir -p "$BACKUP"
exec > >(tee -a "$STATE/install-$STAMP.log") 2>&1
trap 'rc=$?; printf "[ERRO] Linha %s, código %s. Consulte %s/install-%s.log e backup %s\n" "$LINENO" "$rc" "$STATE" "$STAMP" "$BACKUP" >&2; exit "$rc"' ERR
xbps-query -l > "$BACKUP/packages-before.txt"
ls -l /var/service/ > "$BACKUP/services-before.txt"
printf '%s\n' "$*" > "$BACKUP/options.txt"
ROOT_BACKUP=/var/backups/niri-dux/$STAMP
sudo install -d -m 700 "$ROOT_BACKUP"
backup_root() {
    local target=$1
    if [[ -e $target || -L $target ]]; then
        sudo cp -a --parents -- "$target" "$ROOT_BACKUP/"
    fi
}
root_file() {
    local source=$1 target=$2 mode=${3:-644}
    if sudo test -f "$target" && sudo cmp -s -- "$source" "$target"; then return; fi
    backup_root "$target"
    sudo install -D -m "$mode" -- "$source" "$target.niri-dux-new"
    sudo mv -fT -- "$target.niri-dux-new" "$target"
}
user_file() {
    local source=$1 target=$2 mode=${3:-600}
    if [[ -f $target ]] && cmp -s -- "$source" "$target"; then return; fi
    if [[ -e $target || -L $target ]]; then cp -a --parents -- "$target" "$BACKUP/"; fi
    mkdir -p -- "$(dirname -- "$target")"
    # Replace a symlink itself, never write through it.
    rm -f -- "$target"
    install -m "$mode" -- "$source" "$target"
}
user_link() {
    local source=$1 target=$2
    [[ -e $source ]] || die "Origem do link ausente: $source"
    [[ ! -L $target || $(readlink -- "$target") != "$source" ]] || return 0
    if [[ -e $target || -L $target ]]; then cp -a --parents -- "$target" "$BACKUP/"; fi
    mkdir -p -- "$(dirname -- "$target")"
    rm -f -- "$target"
    ln -s -- "$source" "$target"
}
enable_service() {
    local service=$1 target=/var/service/$1
    [[ -d /etc/sv/$service ]] || { note "Serviço ausente: $service"; return 1; }
    if [[ -L $target ]]; then
        [[ $(readlink -f -- "$target") == "$(readlink -f -- "/etc/sv/$service")" ]] || { note "Link conflitante: $target"; return 1; }
    elif [[ -e $target ]]; then note "Destino ocupado: $target"; return 1
    else sudo ln -s "/etc/sv/$service" "$target" || return 1; fi
    sudo sv -w 20 up "$target"
}

note 'Atualizando Void; XBPS pode pedir uma primeira transação para atualizar a si próprio.'
sudo xbps-install -Suv
sudo xbps-install -uv
if [[ $CPU_VENDOR == GenuineIntel && $MICROCODE == 1 ]]; then
    sudo xbps-install void-repo-nonfree
    sudo xbps-install -S
    sudo xbps-install intel-ucode
fi
mkdir -p "$STATE/staging"
printf 'repository=https://void.duxlabs.dev/dms/current\n' > "$STATE/staging/dms.conf"
printf 'repository=https://void.duxlabs.dev/dux-repo/current\n' > "$STATE/staging/dux.conf"
root_file "$STATE/staging/dms.conf" /etc/xbps.d/dms.conf
root_file "$STATE/staging/dux.conf" /etc/xbps.d/dux.conf
# Interactive key import: never use -y here, or bypass signature verification.
sudo xbps-install -S
missing=()
for pkg in "${PACKAGES[@]}"; do
    xbps-query -R -p pkgver "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
(( ${#missing[@]} == 0 )) || die "Pacotes indisponíveis nos repositórios: ${missing[*]}. Nenhum nome alternativo foi adivinhado."
sudo xbps-install -n "${PACKAGES[@]}"
sudo xbps-install "${PACKAGES[@]}"

note 'Configurando locale, fuso, áudio e sessão.'
[[ -f /etc/default/libc-locales ]] || die 'Arquivo de locales glibc ausente.'
grep -Eq "^#?${LOCALE//./\\.}[[:space:]]+UTF-8" /etc/default/libc-locales || die 'Locale ausente em libc-locales.'
backup_root /etc/default/libc-locales
sudo sed -i -E "s/^#(${LOCALE//./\\.}[[:space:]]+UTF-8)/\1/" /etc/default/libc-locales
sudo xbps-reconfigure -f glibc-locales
printf 'LANG=%s\n' "$LOCALE" > "$STATE/staging/locale.conf"
root_file "$STATE/staging/locale.conf" /etc/locale.conf
backup_root /etc/localtime
sudo ln -sfn "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
[[ -r /etc/pam.d/system-login ]] && grep -q pam_elogind.so /etc/pam.d/system-login || die 'PAM sem integração elogind. Reveja o pacote pambase antes de continuar.'
user_link /usr/share/examples/wireplumber/10-wireplumber.conf "$CONFIG/pipewire/pipewire.conf.d/10-wireplumber.conf"
user_link /usr/share/examples/pipewire/20-pipewire-pulse.conf "$CONFIG/pipewire/pipewire.conf.d/20-pipewire-pulse.conf"
# The packaged ALSA examples choose PipeWire for direct ALSA clients too.
for name in 50-pipewire.conf 99-pipewire-default.conf; do
    source=/usr/share/alsa/alsa.conf.d/$name
    [[ -f $source ]] || die "Exemplo ALSA ausente: $source"
    target=/etc/alsa/conf.d/$name
    if [[ ! -L $target || $(readlink "$target") != "$source" ]]; then
        backup_root "$target"
        [[ ! -d $target ]] || die "Diretório inesperado: $target"
        sudo mkdir -p /etc/alsa/conf.d
        sudo ln -sfn "$source" "$target"
    fi
done

# Copy assets into the home before linking: the source USB/checkout can be removed.
for name in start-niri-dux niri-dux-autostart niri-dux-check; do
    user_file "$BASE/bin/$name" "$DATA/bin/$name" 700
    user_link "$DATA/bin/$name" "$HOME/.local/bin/$name"
done
sed "s/@KEYBOARD@/$KEYBOARD/g" "$BASE/config/niri.kdl" > "$STATE/staging/config.kdl"
if [[ ! -f $STATE/managed ]]; then
    mkdir -p "$CONFIG/niri/dms"
    user_file "$STATE/staging/config.kdl" "$CONFIG/niri/config.kdl"
    user_file "$BASE/config/binds.kdl" "$CONFIG/niri/dms/binds.kdl"
    user_file "$BASE/config/input.kdl" "$CONFIG/niri/dms/input.kdl"
    sed -i "s/@KEYBOARD@/$KEYBOARD/g" "$CONFIG/niri/dms/input.kdl"
    for name in colors layout alttab outputs cursor; do
        [[ -e $CONFIG/niri/dms/$name.kdl ]] || : > "$CONFIG/niri/dms/$name.kdl"
    done
    if (( INTEL_LEGACY )); then printf '\nanimations { off; }\n' >> "$CONFIG/niri/config.kdl"; fi
    # Record ownership before validation; a failed run can be resumed after repair.
    printf 'Managed initial setup: %s\n' "$STAMP" > "$STATE/managed"
    niri validate -c "$CONFIG/niri/config.kdl"
else
    note 'Configuração Niri existente preservada; validando.'
    niri validate -c "$CONFIG/niri/config.kdl"
fi
XDG_CURRENT_DESKTOP=niri xdg-user-dirs-update
if [[ $ZRAM == auto ]]; then
    if ! awk 'NR>1 && $1 ~ /zram/ {found=1} END {exit !found}' /proc/swaps; then
        cat > "$STATE/staging/zram.conf" <<'EOF'
export ZRAM_COMP_ALGORITHM=lz4
export ZRAM_PRIORITY=100
export ZRAM_SIZE=25
export ZRAM_MAX_SIZE=2048
EOF
        root_file "$STATE/staging/zram.conf" /etc/sv/zramen/conf
    else note 'Zram já ativa; parâmetros existentes preservados.'; fi
fi
if (( SSD )); then
    cat > "$STATE/staging/trim" <<'EOF'
#!/bin/sh
# fstrim -a skips filesystems/devices without discard support.
exec /usr/bin/fstrim -av
EOF
    root_file "$STATE/staging/trim" /etc/cron.weekly/niri-dux-trim 755
fi
if [[ $CPU_VENDOR == GenuineIntel && $MICROCODE == 1 ]]; then
    # Includes the newly installed microcode in every installed kernel initramfs.
    for modules in /usr/lib/modules/*; do
        [[ -d $modules ]] || continue
        version=${modules##*/}
        [[ -f /boot/vmlinuz-$version ]] || continue
        sudo dracut --force "/boot/initramfs-$version.img" "$version"
    done
fi

note 'Ativando serviços runit.'
for service in "${SERVICES[@]}"; do enable_service "$service"; done
if [[ $NETWORK == manager ]]; then
    # This is the final stage: all downloads and configuration are complete.
    # Restore old symlinks if NetworkManager cannot be started.
    network_links=()
    nm_existed=0
    [[ ! -L /var/service/NetworkManager ]] || nm_existed=1
    restore_network() {
        sudo sv down /var/service/NetworkManager || true
        if (( ! nm_existed )); then sudo rm -f /var/service/NetworkManager; fi
        for old in "${network_links[@]}"; do
            sudo cp -aT -- "$BACKUP/network/${old##*/}" "$old"
            sudo sv up "$old" || true
        done
    }
    mkdir -p "$BACKUP/network"
    for old in /var/service/*; do
        [[ -e $old || -L $old ]] || continue
        case ${old##*/} in dhcpcd*|wpa_supplicant*|iwd|connmand)
            [[ -L $old ]] || die "Serviço de rede não é link: $old"
            cp -a -- "$old" "$BACKUP/network/"
            network_links+=("$old")
            ;;
        esac
    done
    switch_network() {
        for old in "${network_links[@]}"; do
            sudo sv -w 15 down "$old" || return 1
            sudo rm -- "$old" || return 1
        done
        enable_service NetworkManager
    }
    if ! switch_network; then restore_network; die 'Falha na troca de rede; restauração dos links antigos solicitada.'; fi
    note 'NetworkManager iniciado. Se necessário, reconecte o Wi-Fi usando nmtui.'
fi
printf '\nPronto. Reinicie, entre no TTY com seu usuário e execute:\n  ~/.local/bin/start-niri-dux\n'
printf 'Dentro do Niri: Super+Space launcher; Super+Enter terminal; Super+, configurações.\n'
printf 'Diagnóstico: ~/.local/bin/niri-dux-check\nLogs/backup do usuário: %s\nBackup do sistema: %s\n' "$STATE" "$ROOT_BACKUP"
