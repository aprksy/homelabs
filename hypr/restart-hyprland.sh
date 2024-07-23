#!/usr/bin/env sh

# Terminate already running bar instances
killall -q Hyprland

# Wait until the processes have been shut down
while pgrep -x Hyprland >/dev/null; do sleep 1; done

# Launch main
Hyprland
