#! /bin/bash

# this script is intended to run on the host
# objective: to enable the container as ssh node
# requirements: 
# - running incus installation 
# - existing target container (running)
# how it works:
# - inject ssh pub key into the container (key name provided by user)
# - restarts ssh service in the container
# - add the container into ssh node in the ssh config file along with the user name (provided by user), ip address and key

CONTAINER_TARGET=$1
CONTAINER_USERNAME=$2
KEYNAME=$3

# validate input
if [ -z $CONTAINER_TARGET ]
then
    echo "target container cannot be empty"
    exit 1
fi

if [ -z $CONTAINER_USERNAME ]
then
    echo "username container cannot be empty"
    exit 1
fi

if [ -z $KEYNAME ]
then
    echo "username container cannot be empty"
    exit 1
fi

# load base
source base.sh

# get ip address
CONTAINER_IPADDRESS=$( { incus ls | grep $CONTAINER_TARGET | cut -d"|" -f4 | cut -d" " -f2; } 2>&1 )
wait
echo "retrieve container '$CONTAINER_TARGET' IP address ['$CONTAINER_IPADDRESS']"

# inject ssh pub key into the container
incus exec $CONTAINER_TARGET -- mkdir -p /home/$CONTAINER_USERNAME/.ssh && \
echo "create ssh dir in the container [OK]" && \
incus file push ~/.ssh/${KEYNAME}.pub $CONTAINER_TARGET/home/$CONTAINER_USERNAME/.ssh/authorized_keys && \
echo "copy ssh pub key into the container [OK]" && \
incus exec $CONTAINER_TARGET -- chmod 600 /home/$CONTAINER_USERNAME/.ssh/authorized_keys && \
echo "change permission to the ssh pub key in container to 600 [OK]" && \

# restart ssh service
incus exec $CONTAINER_TARGET -- systemctl restart sshd
echo "restarting sshd service in the container [OK]" && \

# add the container info into host's ssh config file 
SSH_DIR="/home/aprksy/.ssh"
SSH_CONFIG="$SSH_DIR/hosts/local/incus/container/config"
echo "Host local-$CONTAINER_TARGET" >> $SSH_CONFIG
echo "    Hostname $CONTAINER_IPADDRESS" >> $SSH_CONFIG
echo "    Port 22" >> $SSH_CONFIG
echo "    User $CONTAINER_USERNAME" >> $SSH_CONFIG
echo "    IdentityFile $SSH_DIR/$KEYNAME" >> $SSH_CONFIG
echo "" >> $SSH_CONFIG

echo "adding entry of the container in the host ssh config file [OK]"
