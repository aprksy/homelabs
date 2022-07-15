#! /bin/bash
source path.sh

for f in $(find $IMPORTS/redis*); do
    cat $f | redis-cli 1>/dev/null
done