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
USERNAME=$2
KEYNAME=$3

# validate input
if [ -z $CONTAINER_TARGET ]
then
    echo "target container cannot be empty"
    exit 1
fi

if [ -z $USERNAME ]
then
    echo "username container cannot be empty"
    exit 1
fi

if [ -z $KEYNAME ]
then
    echo "username container cannot be empty"
    exit 1
fi

# get ip address
IPADDRESS=$(incus ls | grep $CONTAINER_TARGET | cut -d"|" -f4 | cut -d" " -f2)

# inject ssh pub key into the container
incus exec $CONTAINER_TARGET -- mkdir -p /home/$USERNAME/.ssh && \
echo "create ssh dir in the container [OK]" && \
incus file push ~/.ssh/${KEYNAME}.pub $CONTAINER_TARGET/home/$USERNAME/.ssh/authorized_keys && \
echo "copy ssh pub key into the container [OK]" && \
incus exec $CONTAINER_TARGET -- chmod 600 /home/$USERNAME/.ssh/authorized_keys && \
echo "change permission to the ssh pub key in container to 600 [OK]" && \

# restart ssh service
incus exec $CONTAINER_TARGET -- systemctl restart sshd
echo "restarting sshd service in the container [OK]" && \

# add the container info into host's ssh config file 
SSHHOME="/home/aprksy/.ssh"
SSHCONFIG="$SSHHOME/hosts/local/incus/container/config"
echo "Host local-$CONTAINER_TARGET" >> $SSHCONFIG
echo "    Hostname $IPADDRESS" >> $SSHCONFIG
echo "    Port 22" >> $SSHCONFIG
echo "    User $USERNAME" >> $SSHCONFIG
echo "    IdentityFile $SSHHOME/$KEYNAME" >> $SSHCONFIG
echo "" >> $SSHCONFIG

echo "adding entry of the container in the host ssh config file [OK]"
