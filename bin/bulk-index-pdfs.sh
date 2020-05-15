#!/bin/bash

IFS=$'\n'; set -f
for f in $(find /media/myCloudDrive/ncdata/ncp/files/ -name '*.pdf');
do
        # ((i=i+1))
        i=$(date +%s)
        echo $i, $f
        content=$(pdf2txt $f | sed 's/\x27/ /g');
        insert="INSERT INTO testrt (id, gid, title, content) VALUES ($i, $i, '$f', '$content');"
        echo $insert | mysql -h 127.0.0.1 -P 9306
done
unset IFS; set +f

