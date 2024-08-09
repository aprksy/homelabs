#! /bin/bash

# this script is intended to run on the host
# objective: to install apps on the container
# requirements: 
# - running incus installation 
# - existing target container (running)
# how it works:
# - execute application install through pkg manager

CONTAINER_TARGET=$1
APPS=$2

# validate input
if [ -z $CONTAINER_TARGET ]
then
    echo "target container cannot be empty"
    exit 1
fi

if [ -z $APPS ]
then
    echo "apps cannot be empty"
    exit 1
fi

# install app in non-interactive mode
incus exec $CONTAINER_TARGET -- zsh -c "echo y | LANG=C yay -S --noconfirm $APPS"