#! /bin/bash
source path.sh

# check date
DATE=$(date +%Y%m%d)
if [ ! -z "$1" ]; then
    DATE="$1"
fi

# generate target file name
PREFIX="pu*_lte_call_"
SUFFIX="*.csv_p*.txt.gz"
FILENAME=$PUFILES_RAW/$PREFIX$DATE$SUFFIX

# delete existing events file
# rm $PREPARED_DIR/r*_events.csv
rm $PREPARED_DIR/*

# generate new events file
for reg in $(seq -f "%02g" 1 12); do
    echo "collecting data for region $reg..."
    i=0
    for f in $(ls -1 $PUFILES_RAW | grep -f $PU_REG/pu_regional_$reg.txt); do
        grep $f $PREPARED_DIR/cf-r$reg.txt || 
            { 
                echo "processing file $PUFILES_RAW/$f"; 
                zcat $PUFILES_RAW/$f \
                    | cut -d'|' -f1,60,61,62,73,74,76,77 \
                    | grep -v '\N' \
                    | tr -s '|' , \
                    >> $PREPARED_DIR/r${reg}_events.csv; 
                echo $f >> $PREPARED_DIR/cf-r$reg.txt 
            } 
        i=$(($i+1))
    done
    echo "total files: $i"
    echo "-------------------------------------------------------------------"
done

# generate import files
for reg in $(seq -f "%02g" 1 12); do
    ls -1 $PREPARED_DIR/r${reg}_events.csv && {
        echo "generating data for region $reg...";
        cat $PREPARED_DIR/r${reg}_events.csv \
            | awk -F, -v DATE=$DATE -v REG=$reg 'BEGIN{}{
                print "SET "DATE"_R"REG"_EVENTS "$1" FIELD rsrp "$6" FIELD clat "$8" FIELD clng "$7" POINT "$3" "$2; 
            }' \
            > $IMPORTS/tile38_r${reg}_events.txt;

        cat $PREPARED_DIR/r${reg}_events.csv \
            | awk -F, -v DATE=$DATE -v REG=$reg 'BEGIN{ORS=" "; print "HSET "DATE"_R"REG"_EVENT_CELL_TILE"}{
                print $1" \""$5","$4"\""; 
            }' \
            > $IMPORTS/redis_r${reg}_event_cell_tile.txt;
    }
done