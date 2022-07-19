#! /bin/bash
source path.sh

# check date
DATE=$(date +%Y%m%d)
if [ ! -z "$1" ]; then
    DATE="$1"
fi

# generate target file name
PREFIX="sitedb_lte_"
SUFFIX=".csv.gz"
FILENAME=$SITEDB_RAW/$PREFIX$DATE$SUFFIX

# check file existence
FILEEXISTS="NO"
if [ $(find $FILENAME | wc -l) -eq 1 ]; then
    FILEEXISTS="YES"
fi

echo "using data from $DATE."
echo "  filename: $FILENAME"
echo "  file exists: $FILEEXISTS"

# decide to continue or abort process
if [ $FILEEXISTS == "NO" ]; then
    echo "aborting..."
    exit 1
fi

# continue processing
ALL_COLUMNS=$(zcat $FILENAME | head -1 | sed 's/"//g' | sed 's/,/\n/g')
SELECTED_COLUMNS=[]

# generate 'redis importable' site_data; only include the following fields:
# SITENAME
# LATITUDE
# LONGITUDE
# SITETYPE
zcat $FILENAME \
    | sed 's/"//g' \
    | tail +2 \
    | awk -F, -v date=$DATE 'BEGIN{OFS=" "; siteName=""; siteData[$2]="";}
    {
        split($21, arr, " ");
        reg[$2]=arr[2]
        siteData[$2] = $3","$10","$9","$13
    }
    END {
        for (s in siteData) {
            if (s != "") {
                print "HSET "date"_R"reg[s]"_SITE_DATA",s" \""siteData[s]"\""
            }
        }
    }' > $IMPORTS/redis_site_data.txt

# generate 'redis importable' site_cells
zcat $FILENAME \
    | sed 's/"//g' \
    | tail +2 \
    | awk -F, -v date=$DATE 'BEGIN{OFS=" "; siteName=""; siteCells[$2]=""; reg[$2]="";}
    {
        split($21, arr, " ");
        reg[$2]=arr[2]
        if ($2 != siteName) {
            if (siteCells[$2] == "") {
                siteCells[$2] = $4
            } else {
                siteCells[$2] = siteCells[$2]","$4
            }
            siteName = $2
        } else {
            siteCells[$2] = siteCells[$2]","$4
        }
    } 
    END {
        for (s in siteCells) {
            if (s != "") {
                print "HSET "date"_R"reg[s]"_SITE_CELLS",s" \""siteCells[s]"\""
            }
        }
    }' > $IMPORTS/redis_site_cells.txt


# generate 'tile38 importable' site_pos
zcat $FILENAME \
    | sed 's/"//g' \
    | tail +2 \
    | awk -F, -v date=$DATE 'BEGIN{OFS=" "; siteName=""; sitePos[$2]=""; reg[$2]="";}
    {
        if ($9 != "\\N" && $10 != "\\N") {
            split($21, arr, " ");
            sitePos[$2] = $10" "$9
            reg[$2]=arr[2]
        }
    }
    END {
        for (s in sitePos) {
            if (s != "") {
                print "SET "date"_R"reg[s]"_SITE_POS "s" POINT "sitePos[s]
            }
        }
    }' > $IMPORTS/tile38_site_pos.txt

# generate 'redis importable' cell_data; only include the following fields:
# TECH
# BAND
# HEIGHT
# AZIMUTH
# MT
# ET
# MODEL
# HBW
# VENDOR
zcat $FILENAME \
    | sed 's/"//g' \
    | tail +2 \
    | awk -F, -v date=$DATE 'BEGIN{OFS=" "}{
        split($21, arr, " ");
        print "HSET "date"_R"arr[2]"_CELL_DATA",$4" \""$11","$12","$14","$15","$16","$17","$18","$19","$20"\""
    }' > $IMPORTS/redis_cell_data.txt

# generate 'redis importable' cell to site mappings
zcat $FILENAME \
    | sed 's/"//g' \
    | tail +2 \
    | awk -F, -v date=$DATE 'BEGIN{OFS=" "}{
        split($21, arr, " ");
        print "HSET "date"_R"arr[2]"_CELL_SITE",$4" \""$2"\""
    }' > $IMPORTS/redis_cell_site.txt