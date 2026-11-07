#!/usr/bin/env bash
# ==============================================================================
# Script: setup-mango.sh
# Finalidade: Instalar o MangoWC, compilar o MangoBar e configurar todo o
#             ambiente de hardware (vídeo Intel, áudio PipeWire, bluetooth,
#             rede, terminal Alacritty e launcher) a partir de um Void Linux limpo.
#
# Hardware detectado e otimizado:
#   - CPU: Intel Core i3-2310M (Sandy Bridge)
#   - GPU: Intel HD Graphics 3000 (driver i915 / Mesa crocus)
#   - Áudio: PipeWire + WirePlumber
#   - Bluetooth: BlueZ + PipeWire SPA
#   - Terminal: Alacritty
#   - Launcher: Fuzzel (Wayland nativo leve para wlroots)
# ==============================================================================

set -Eeuo pipefail

# Cores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_err()  { echo -e "${RED}[ERRO]${NC} $1" >&2; }

# Verificação de segurança: não rodar diretamente como root
if [[ $EUID -eq 0 ]]; then
    log_err "Não execute este script como root! Execute como seu usuário comum (ele solicitará sudo quando necessário)."
    exit 1
fi

CURRENT_USER="$USER"
log_info "Iniciando provisionamento do Mango Desktop para o usuário: ${CURRENT_USER}"

# ------------------------------------------------------------------------------
# 1. Habilitar repositório nonfree e sincronizar base
# ------------------------------------------------------------------------------
log_info "1/7 Habilitando void-repo-nonfree e atualizando o sistema..."
sudo xbps-install -Sy void-repo-nonfree
sudo xbps-install -Syu

# ------------------------------------------------------------------------------
# 2. Drivers de Hardware da Máquina (Vídeo Intel Sandy Bridge + Energia)
# ------------------------------------------------------------------------------
log_info "2/7 Instalando drivers gráficos Intel e utilitários de hardware..."
sudo xbps-install -y \
    intel-ucode \
    mesa-dri \
    libva-intel-driver \
    libva-utils \
    brightnessctl

# ------------------------------------------------------------------------------
# 3. Áudio (PipeWire), Bluetooth e Rede
# ------------------------------------------------------------------------------
log_info "3/7 Instalando suporte a áudio PipeWire, Bluetooth e NetworkManager..."
sudo xbps-install -y \
    pipewire \
    wireplumber \
    alsa-pipewire \
    pulseaudio-utils \
    bluez \
    libspa-bluetooth \
    NetworkManager

# ------------------------------------------------------------------------------
# 4. Base do Wayland, Sessão, Terminal, Launcher e Fontes
# ------------------------------------------------------------------------------
log_info "4/7 Instalando base Wayland (dbus, elogind, polkit), Alacritty, Fuzzel e fontes..."
sudo xbps-install -y \
    dbus \
    elogind \
    polkit \
    udev \
    xorg-server-xwayland \
    alacritty \
    fuzzel \
    noto-fonts-ttf \
    dejavu-fonts-ttf

# Configuração de grupos do usuário
log_info "Adicionando ${CURRENT_USER} aos grupos de hardware e sessão..."
for grp in video audio input bluetooth network; do
    if getent group "$grp" >/dev/null; then
        sudo usermod -aG "$grp" "$CURRENT_USER"
    fi
done

# Habilitação de serviços runit essenciais
log_info "Habilitando serviços runit essenciais..."
SERVICES=(dbus elogind udevd NetworkManager bluetoothd)
for srv in "${SERVICES[@]}"; do
    if [[ -d "/etc/sv/$srv" ]] && [[ ! -L "/var/service/$srv" ]]; then
        sudo ln -s "/etc/sv/$srv" "/var/service/"
        log_ok "Serviço runit ativado: $srv"
    fi
done

# ------------------------------------------------------------------------------
# 5. Instalação do MangoWC
# ------------------------------------------------------------------------------
log_info "5/7 Instalando o MangoWC (pacote oficial do Void Linux)..."
sudo xbps-install -y mangowc

# ------------------------------------------------------------------------------
# 6. Compilação e Instalação do MangoBar
# ------------------------------------------------------------------------------
log_info "6/7 Instalando dependências de build e compilando o MangoBar..."
sudo xbps-install -y \
    meson \
    ninja \
    pkg-config \
    gcc \
    git \
    python3 \
    wayland-devel \
    wayland-protocols \
    fcft-devel \
    tllist \
    pixman-devel \
    cairo-devel \
    pango-devel \
    pulseaudio-devel \
    elogind-devel \
    eudev-libudev-devel \
    gdk-pixbuf-devel \
    libxkbcommon-devel \
    cJSON-devel

BUILD_DIR=$(mktemp -d /tmp/mangobar-build.XXXXXX)
log_info "Clonando repositório oficial do MangoBar em ${BUILD_DIR}..."
git clone --depth=1 https://github.com/mangowm/mangobar.git "${BUILD_DIR}/mangobar"

pushd "${BUILD_DIR}/mangobar" > /dev/null
meson setup build -Dprefix=/usr/local --buildtype=release
ninja -C build
log_info "Instalando mangobar em /usr/local/bin..."
sudo ninja -C build install
popd > /dev/null
rm -rf "${BUILD_DIR}"
log_ok "MangoBar compilado e instalado com sucesso!"

# ------------------------------------------------------------------------------
# 7. Configurações de Sessão e MangoWC
# ------------------------------------------------------------------------------
log_info "7/7 Configurando MangoWC e inicializador de sessão..."
mkdir -p "$HOME/.config/mango"
mkdir -p "$HOME/.config/mangobar"
mkdir -p "$HOME/.local/bin"

# Gerar arquivo de configuração otimizado para o hardware
cat << 'EOF' > "$HOME/.config/mango/config.conf"
# ==============================================================================
# MangoWC Config - Otimizado para Intel Core i3 (Sandy Bridge HD Graphics 3000)
# ==============================================================================

# Desempenho Gráfico: sem blur pesado para manter 60 FPS estáveis na GPU Intel
blur=0
blur_layer=0
blur_optimized=1
shadows=0
layer_shadows=0
border_radius=6
no_radius_when_single=0
focused_opacity=1.0
unfocused_opacity=1.0

# Animações sutis
animations=1
layer_animations=1
animation_type_open=slide
animation_type_close=slide
animation_fade_in=1
animation_fade_out=1
tag_animation_direction=1
animation_duration_move=300
animation_duration_open=250
animation_duration_tag=200
animation_duration_close=300

# Gaps e Bordas
gap_inner_horizontal=5
gap_inner_vertical=5
gap_outer_horizontal=10
gap_outer_vertical=10
border_px=3
border_color=0x444444ff
focus_color=0x5e81acff

# Layout de Teclado e Touchpad
repeat_rate=25
repeat_delay=600
numlock_on=0
xkb_rules_layout=br

disable_trackpad=0
tap_to_click=1
tap_and_drag=1
trackpad_natural_scrolling=0

# Autostart do Ambiente
exec_once=mangobar
exec_once=pipewire
exec_once=wireplumber

# Atalhos Gerais
bind=SUPER,r,reload_config
bind=SUPER,m,quit
bind=ALT,q,killclient,

# Terminal (Alacritty) e Launcher (Fuzzel)
bind=Alt,Return,spawn,alacritty
bind=Alt,space,spawn,fuzzel

# Navegação entre janelas
bind=SUPER,Tab,focusstack,next
bind=ALT,Left,focusdir,left
bind=ALT,Right,focusdir,right
bind=ALT,Up,focusdir,up
bind=ALT,Down,focusdir,down

# Janelas: Tela cheia, Flutuante e Scratchpad
bind=ALT,f,togglefullscreen,
bind=ALT,backslash,togglefloating,
bind=ALT,z,toggle_scratchpad

# Alternância de Tags (1 a 5)
bind=Ctrl,1,view,1,0
bind=Ctrl,2,view,2,0
bind=Ctrl,3,view,3,0
bind=Ctrl,4,view,4,0
bind=Ctrl,5,view,5,0

bind=Alt,1,tag,1,0
bind=Alt,2,tag,2,0
bind=Alt,3,tag,3,0
bind=Alt,4,tag,4,0
bind=Alt,5,tag,5,0

# Controle do Mouse
mousebind=SUPER,btn_left,moveresize,curmove
mousebind=SUPER,btn_right,moveresize,curresize
EOF
log_ok "Configuração gerada em ~/.config/mango/config.conf"

# Gerar script inicializador de sessão para o TTY
cat << 'EOF' > "$HOME/.local/bin/start-mango"
#!/usr/bin/env bash
set -Eeuo pipefail

[[ $EUID != 0 ]] || { echo 'Inicie com seu usuário comum a partir do TTY.' >&2; exit 1; }
[[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || { echo 'Já existe uma sessão gráfica ativa.' >&2; exit 1; }

export XDG_CURRENT_DESKTOP=mango
export XDG_SESSION_DESKTOP=mango
export XDG_SESSION_TYPE=wayland
export LIBSEAT_BACKEND=logind
export PATH="$HOME/.local/bin:$PATH"

mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/mango"
exec dbus-run-session -- mango >> "${XDG_STATE_HOME:-$HOME/.local/state}/mango/session.log" 2>&1
EOF
chmod +x "$HOME/.local/bin/start-mango"
log_ok "Inicializador criado em ~/.local/bin/start-mango"

echo ""
log_ok "=========================================================================="
log_ok " Setup do MangoWC, MangoBar e hardware concluído com sucesso!"
log_ok " Para iniciar o ambiente gráfico a partir de um TTY limpo, execute:"
log_ok "     start-mango"
log_ok "=========================================================================="
