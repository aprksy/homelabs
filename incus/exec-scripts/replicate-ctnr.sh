#! /bin/bash

# this script is intended to run on the host
# objective: to produce a container from an existing container template
# requirements: 
# - a running incus installation
# - an existing container (stopped)
# what it does:
# - copy the template container into a new container (name supplied by user)
# - run the new container
# - set ip address (last byte set by user)
# - replace all the host ssh keys with a new one
# - restart the container

CONTAINER_TEMPLATE=$1
CONTAINER_TARGET=$2
IPADDR=$3

# validate input
if [ -z $CONTAINER_TEMPLATE ]
then
    echo "ERR: template container cannot be empty"
    exit 1 
fi

if [ -z $CONTAINER_TARGET ]
then
    echo "ERR: target container cannot be empty"
    exit 1 
fi

if [ -z $IPADDR ]
then
    echo "ERR: ip address last byte cannot be empty"
    exit 1 
fi

# copy template container
incus cp $CONTAINER_TEMPLATE $CONTAINER_TARGET && \
echo "copying container from '$CONTAINER_TEMPLATE' [OK]" \

# run the target container
incus start $CONTAINER_TARGET && \
echo "starting '$CONTAINER_TARGET' container [OK]" \

# replace ip address
incus exec $CONTAINER_TARGET -- sed -i s/3/$IPADDR/g /etc/systemd/network/eth0.network && \
echo "change ip addres to '192.168.200.$IPADDR' on '$CONTAINER_TARGET' [OK]" \

# remove all host's ssh keys
incus exec $CONTAINER_TARGET -- sh -c "rm /etc/ssh/ssh_host*" && \
echo "remove all ssh_host keys on '$CONTAINER_TARGET' [OK]" \

# generate new host ssk keys
incus exec $CONTAINER_TARGET -- ssh-keygen -A && \
echo "generate new ssh host keys for '$CONTAINER_TARGET' [OK]" \

# restart the new container
incus restart $CONTAINER_TARGET \

echo "restarting '$CONTAINER_TARGET' [OK]" \
echo "finished replicating '$CONTAINER_TEMPLATE' to '$CONTAINER_TARGET' [OK]" 