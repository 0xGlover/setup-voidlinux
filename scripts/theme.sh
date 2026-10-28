#!/usr/bin/env bash
set -Eeuo pipefail
theme="${1:-nord}"
mode="${2:---plan}"
case "$theme" in nord|gruvbox|solarized) ;; *) echo "Tema inválido: $theme"; exit 2;; esac
case "$mode" in --plan|--apply) ;; *) echo "Use --plan ou --apply"; exit 2;; esac
[[ $EUID -ne 0 ]] || { echo "Execute como usuário comum"; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root/themes/$theme.palette"
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="$state/theme-backups/$stamp"
mkdir -p "$state"
log="$state/theme-$stamp.log"
exec > >(tee -a "$log") 2>&1
trap 'rc=$?; echo "[ERRO] linha $LINENO, status $rc"; exit "$rc"' ERR
declare -A names=([i3]=config [polybar]=config.ini [rofi]=config.rasi [dunst]=dunstrc [alacritty]=alacritty.toml)
for app in i3 polybar rofi dunst alacritty; do
 dest="$HOME/.config/$app/${names[$app]}"
 src="$state/generated/$theme/$app/${names[$app]}"
 if [[ -L "$dest" ]]; then
  echo "LINK $dest -> $src"
 elif [[ -e "$dest" ]]; then
  echo "BACKUP $dest -> $backup/$app/"
 else
  echo "CRIAR $dest"
 fi
done
echo "Tema: $theme; modo: $mode"
[[ "$mode" == --plan ]] && exit 0
mkdir -p "$state/generated/$theme"
for app in i3 polybar rofi dunst alacritty; do mkdir -p "$state/generated/$theme/$app"; done
cat > "$state/generated/$theme/i3/config" <<EOF
set \$mod Mod4
font pango:monospace 10
floating_modifier \$mod
default_border pixel 2
default_floating_border pixel 2
gaps inner 9
gaps outer 4
client.focused $ACCENT $SURFACE $FG $ACCENT $ACCENT
client.unfocused $MUTED $BG $FG $MUTED $MUTED
bindsym \$mod+Return exec alacritty
bindsym \$mod+d exec rofi -show drun
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+r restart
bindsym \$mod+Shift+e exec i3-nagbar -t warning -m 'Sair do i3?' -B 'Sair' 'i3-msg exit'
bindsym \$mod+h focus left
bindsym \$mod+j focus down
bindsym \$mod+k focus up
bindsym \$mod+l focus right
bindsym \$mod+Shift+h move left
bindsym \$mod+Shift+j move down
bindsym \$mod+Shift+k move up
bindsym \$mod+Shift+l move right
bindsym \$mod+v split v
bindsym \$mod+b split h
bindsym \$mod+f fullscreen toggle
bindsym \$mod+Shift+space floating toggle
bindsym \$mod+space focus mode_toggle
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2
bindsym \$mod+3 workspace number 3
bindsym \$mod+4 workspace number 4
bindsym \$mod+5 workspace number 5
bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4
bindsym \$mod+Shift+5 move container to workspace number 5
exec --no-startup-id dunst
exec --no-startup-id sh -c 'pkill -x polybar || true; polybar main'
EOF
cat > "$state/generated/$theme/polybar/config.ini" <<EOF
[colors]
background = $BG
foreground = $FG
primary = $ACCENT
[bar/main]
width = 100%
height = 28
background = \${colors.background}
foreground = \${colors.foreground}
font-0 = monospace:size=10;2
modules-left = i3
modules-right = cpu memory date
[module/i3]
type = internal/i3
label-focused = %index%
label-focused-foreground = \${colors.primary}
label-focused-padding = 2
label-unfocused = %index%
label-unfocused-padding = 2
[module/cpu]
type = internal/cpu
interval = 5
label = CPU %percentage%%
[module/memory]
type = internal/memory
interval = 5
label = RAM %percentage_used%%
[module/date]
type = internal/date
interval = 30
date = %d/%m %H:%M
label = %date%
EOF
cat > "$state/generated/$theme/rofi/config.rasi" <<EOF
configuration { modi: "drun,run,window"; show-icons: true; font: "monospace 11"; }
* { background: $BG; foreground: $FG; }
window { width: 40%; border: 2px; border-color: $ACCENT; }
element selected { background-color: $ACCENT; text-color: $BG; }
listview { lines: 8; }
element { padding: 8px; }
EOF
cat > "$state/generated/$theme/dunst/dunstrc" <<EOF
[global]
font = monospace 10
width = 330
height = 100
offset = 20x40
origin = top-right
frame_width = 2
frame_color = "$ACCENT"
[urgency_normal]
background = "$BG"
foreground = "$FG"
timeout = 7
[urgency_low]
background = "$BG"
foreground = "$FG"
timeout = 5
[urgency_critical]
background = "$RED"
foreground = "$FG"
timeout = 0
EOF
cat > "$state/generated/$theme/alacritty/alacritty.toml" <<EOF
[window]
padding = { x = 8, y = 8 }
opacity = 1.0
[font]
size = 10.0
[colors.primary]
background = "$BG"
foreground = "$FG"
[colors.normal]
black = "$SURFACE"
red = "$RED"
green = "$GREEN"
yellow = "$YELLOW"
blue = "$BLUE"
magenta = "$MAGENTA"
cyan = "$CYAN"
white = "$FG"
EOF
for app in i3 polybar rofi dunst alacritty; do
 dest="$HOME/.config/$app/${names[$app]}"
 src="$state/generated/$theme/$app/${names[$app]}"
 mkdir -p "$(dirname "$dest")"
 if [[ -L "$dest" ]]; then
  rm -- "$dest"
 elif [[ -e "$dest" ]]; then
  mkdir -p "$backup/$app"
  mv -- "$dest" "$backup/$app/"
 fi
 ln -s "$src" "$dest"
done
printf '%s\n' "$theme" > "$state/current-theme"
echo "[OK] Tema $theme aplicado. Backups: $backup"
echo "No i3: Super+Shift+C para recarregar. Para reiniciar Polybar: pkill -x polybar; polybar main &"
