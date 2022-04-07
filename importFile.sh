#!/bin/bash

y=$(/bin/date +%Y)
m=$(/bin/date +%m)
dir=`dirname "$1"`
fil=`basename "$1"`


if [[ "$fil" == *pdf ]]
then
    # add to ELDOAR Index
    TARGETPATH="$ELDOAR_HOME/data/files/$y/$m"
    /bin/mkdir -p $TARGETPATH
    TARGETFILE="$TARGETPATH/$fil"
    if [ ! -f "$TARGETFILE" ]; then
        /bin/cp $1 $TARGETFILE
        $ELDOAR_HOME/indexFile.pl $TARGETFILE
        rm -f $1
    fi
else
    # convert images to pdf
    img2pdf -o "$1.pdf" "$1"
    rm -f $1
fi

