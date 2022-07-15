#! /bin/bash
source path.sh

for f in $(find $IMPORTS/tile38*); do
    cat $f | $TOOLS/tile38-cli 1>/dev/null
done