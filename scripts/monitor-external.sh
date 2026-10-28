#!/usr/bin/env bash
# Approved external-only layout; called once at i3 session startup.
set -euo pipefail
mode="${1:---plan}"
[[ "$mode" == --plan || "$mode" == --apply ]] || exit 2
outputs=$(xrandr --query)
if awk '$1 == "HDMI-1" && $2 == "connected" {found=1} END {exit !found}' <<< "$outputs"; then
 args=(--output HDMI-1 --mode 1920x1080 --rate 60 --primary --pos 0x0 --output LVDS-1 --off --output VGA-1 --off --output DP-1 --off)
else
 args=(--output LVDS-1 --auto --primary --pos 0x0)
fi
printf 'xrandr '; printf '%q ' "${args[@]}"; printf '\n'
[[ "$mode" == --plan ]] || xrandr "${args[@]}"
