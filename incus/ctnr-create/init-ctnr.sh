# TODO: add some description
# TODO: validate input
CONTAINER_TEMPLATE=$1
CONTAINER_TARGET=$2
CONTAINER_IPADDR=$3
CONTAINER_USERNAME=$4
KEYNAME=$5
APPS=$6

./replicate-ctnr.sh $CONTAINER_TEMPLATE $CONTAINER_TARGET $CONTAINER_IPADDR

# wait 5 seconds until container obtains IP address from configuration
sleep 5s
./add-sshnode.sh $CONTAINER_TARGET $CONTAINER_USERNAME $KEYNAME
./install-apps.sh $CONTAINER_TARGET "$APPS"