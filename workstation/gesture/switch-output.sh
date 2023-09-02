#! /bin/bash

param=$1

if [ $param == "up" ]; then
    swaymsg workspace number $(swaymsg -rt get_workspaces | jq '.[] | select (.output == "HDMI-A-1" and .visible == true)' | jq '.num')
elif [ $param == "down" ]; then
    swaymsg workspace number $(swaymsg -rt get_workspaces | jq '.[] | select (.output == "eDP-1" and .visible == true)' | jq '.num')
fi