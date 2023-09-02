#! /bin/bash
param=$1

# define monitor layout
declare -A layout=( ["eDP-1_left"]="HDMI-A-1" ["eDP-1_right"]="HDMI-A-1" ["HDMI-A-1_left"]="eDP-1" ["HDMI-A-1_right"]="eDP-1")

# variable to store workspace numbers
workspaces=()

# get focused output (monitor name)
focused_output=$(swaymsg -rt get_outputs | jq '.[] | select(.focused == true)' | jq '.name')

# get list of workspace in the focused output
temp=$(swaymsg -rt get_workspaces | jq ".[] | select(.output == $focused_output)" | jq '.num')

# get the right-most workspace in the output left of the focused output (current monitor)
leftOut=\"${layout["$(echo $focused_output | tr -d \")_left"]}\"
additionalLeft=$(swaymsg -rt get_workspaces | jq "[.[] | select(.output == $leftOut)] | last" | jq '.num')

# get the left-most workspace in the output right of the focused output (current monitor)
rightOut=\"${layout["$(echo $focused_output | tr -d \")_right"]}\"
additionalRight=$(swaymsg -rt get_workspaces | jq "[.[] | select(.output == "$rightOut")] | first" | jq '.num')

i=0
workspaces[$i]=$additionalLeft
((i++))
for el in $temp; do
    workspaces[$i]=$el
    ((i++))
done
workspaces[$i]=$additionalRight

# get current workspace
element=$(swaymsg -rt get_workspaces | jq ".[] | select(.output == $focused_output) | select(.focused == true)" | jq '.num')

# find indexes of current workspace
index=-1
found=false
for i in ${!workspaces[@]}; do
    ((index++))
    if [[ "${workspaces[$i]}" = "$element" ]];
    then
        found=true
        break
    fi
done

# do something if found or not-found
if [ $found == true ];
then
    if [ $param == "next" ]; then
        swaymsg workspace number ${workspaces[$index+1]} 
    elif [ $param == "prev" ]; then
        swaymsg workspace number ${workspaces[$index-1]}
    fi
else
    echo "Element is not in Array"
fi