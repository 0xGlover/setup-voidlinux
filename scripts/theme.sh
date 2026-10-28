#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
theme="${1:-nord}"
mode="${2:---plan}"
case "$theme" in nord|gruvbox|solarized) ;; *) echo "Tema inválido: $theme"; exit 2;; esac
case "$mode" in --plan|--apply) ;; *) echo "Use --plan ou --apply"; exit 2;; esac
[[ $EUID -ne 0 ]] || { echo "Execute como usuário comum"; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root/themes/$theme.palette"
state="${XDG_STATE_HOME:-$HOME/.local/state}/linux-autosetup"
stamp="$(date -u +%Y%m%dT%H%M%S)-$$"
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
echo "GTK: Arc-Dark; ícones: Papirus-Dark; cursor: Adwaita; fonte: DejaVu Sans 10 (backups e preferências visuais incluídos)"
echo "Tema: $theme; modo: $mode"
[[ "$mode" == --plan ]] && exit 0
# Preserve generated targets BEFORE rewriting them, including symlink destinations.
mkdir -p "$backup"
if [[ -d "$state/generated/$theme" ]]; then
 cp -a -- "$state/generated/$theme" "$backup/generated"
fi
for app in i3 polybar rofi dunst alacritty; do
 dest="$HOME/.config/$app/${names[$app]}"
 if [[ -e "$dest" || -L "$dest" ]]; then
  mkdir -p "$backup/links/$app"
  cp -a -- "$dest" "$backup/links/$app/"
  if [[ -f "$dest" ]]; then
   mkdir -p "$backup/content/$app"
   cp -L -- "$dest" "$backup/content/$app/${names[$app]}"
  fi
 fi
done
bash "$root/scripts/apply-visual.sh" "$backup"
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
bindsym --release Print exec bash "$root/scripts/screenshot.sh"
bindsym \$mod+Shift+s exec bash "$root/scripts/screenshot.sh"
bindsym \$mod+Shift+v exec bash "$root/scripts/clipboard-menu.sh"
bindsym \$mod+Shift+p exec bash "$root/scripts/power-menu.sh"
exec_always --no-startup-id setxkbmap -layout us -variant intl
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
bindsym \$mod+e exec thunar
bindsym \$mod+Shift+t exec bash "$root/scripts/theme-menu.sh"
bindsym \$mod+Ctrl+l exec i3lock --color=2e3440
bindsym XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym \$mod+r mode "resize"
mode "resize" {
 bindsym h resize shrink width 10 px or 10 ppt
 bindsym j resize grow height 10 px or 10 ppt
 bindsym k resize shrink height 10 px or 10 ppt
 bindsym l resize grow width 10 px or 10 ppt
 bindsym Return mode "default"
 bindsym Escape mode "default"
}
exec --no-startup-id bash "$root/scripts/session-start.sh"
exec --no-startup-id sh -c 'bash "$root/scripts/monitor-external.sh" --apply; exec bash "$root/scripts/bar-start.sh"'
EOF
cat > "$state/generated/$theme/polybar/config.ini" <<EOF
[colors]
background = $BG
surface = $SURFACE
foreground = $FG
muted = $FG
primary = $ACCENT
blue = $BLUE
green = $GREEN
purple = $MAGENTA
red = $RED

[bar/main]
width = 100%
height = 34
background = \${colors.background}
foreground = \${colors.foreground}
font-0 = DejaVu Sans:size=10;3
font-1 = FontAwesome:size=12;3
modules-left = launcher i3
modules-center = date
modules-right = pulseaudio cpu memory tray power
padding-left = 1
padding-right = 1
module-margin = 1
line-size = 2
border-bottom-size = 1
border-bottom-color = \${colors.surface}
monitor = \${env:MONITOR:}
monitor-fallback = LVDS-1
screenchange-reload = true
cursor-click = pointer
cursor-scroll = ns-resize
enable-ipc = true

[module/launcher]
type = custom/text
format = %{T2}%{T-}
format-foreground = \${colors.primary}
format-padding = 1
click-left = rofi -show drun

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
wrapping-scroll = false
label-mode = %mode%
label-mode-background = \${colors.surface}
label-mode-padding = 1
label-focused = %index%
label-focused-foreground = \${colors.primary}
label-focused-background = \${colors.surface}
label-focused-underline = \${colors.primary}
label-focused-padding = 2
label-unfocused = %index%
label-unfocused-foreground = \${colors.muted}
label-unfocused-padding = 2
label-visible = %index%
label-visible-foreground = \${colors.blue}
label-visible-padding = 2
label-urgent = %index%
label-urgent-background = \${colors.red}
label-urgent-padding = 2

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
ramp-volume-0 = %{T2}%{T-}
ramp-volume-1 = %{T2}%{T-}
ramp-volume-2 = %{T2}%{T-}
ramp-volume-foreground = \${colors.primary}
label-muted = %{T2}%{T-} mudo
label-muted-foreground = \${colors.muted}
click-right = pavucontrol

[module/cpu]
type = internal/cpu
interval = 5
format-prefix = "%{T2}%{T-} "
format-prefix-foreground = \${colors.blue}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 5
format-prefix = "%{T2}%{T-} "
format-prefix-foreground = \${colors.purple}
label = %percentage_used:2%%

[module/date]
type = internal/date
interval = 1
date = %d/%m
time = %H:%M
label = %{T2}%{T-} %date%  %{F$ACCENT}·%{F-}  %{T2}%{T-} %time%
label-foreground = \${colors.foreground}

[module/tray]
type = internal/tray
tray-spacing = 8px
tray-size = 18px

[module/power]
type = custom/text
format = %{T2}%{T-}
format-foreground = \${colors.red}
format-padding = 1
click-left = bash "$root/scripts/power-menu.sh"
EOF
cat > "$state/generated/$theme/rofi/config.rasi" <<EOF
configuration {
 modi: "drun,run,window";
 show-icons: true;
 font: "monospace 11";
}
* {
 background: $BG;
 foreground: $FG;
 lightbg: $BG;
 lightfg: $FG;
 selected-normal-background: $ACCENT;
 selected-normal-foreground: $BG;
 selected-active-background: $ACCENT;
 selected-active-foreground: $BG;
 alternate-active-background: $BG;
 background-color: $BG;
 text-color: $FG;
}
window {
 background-color: $BG;
 padding: 8px;
 width: 40%;
 border: 2px;
 border-color: $ACCENT;
}
element normal.normal, element alternate.normal {
 background-color: $BG;
 text-color: $FG;
}
element selected {
 background-color: $ACCENT;
 text-color: $BG;
}
element-text, element-icon {
 background-color: transparent;
 text-color: inherit;
}
listview {
 lines: 8;
}
element {
 padding: 8px;
}
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
echo "Para recarregar o desktop: bash \"$root/scripts/reload-desktop.sh\""
