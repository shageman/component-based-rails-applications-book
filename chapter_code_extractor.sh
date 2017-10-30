#!/usr/bin/env bash

extractChapter () {
    SRC=$1
    OUT=$2

    if [ -z $SRC ];
        then echo "ERROR: call extractChapter as extractChapter(SRC[, OUT])"
        exit 1
    fi

    echo "extractChapter for SRC $SRC"

    if [ -z $OUT ]; then
        echo "extractChapter called without OUT. Setting OUT to SRC ($SRC)"
        OUT=$SRC
    fi

    rm -rf $OUT
    mkdir $OUT
    FILE=$(find docker/minio/data/releases/$SRC* | sort | tail -1)
    tar -xzf $FILE -C $OUT
}

extractChapter "c2s01"
extractChapter "c2s02"
extractChapter "c2s03"
extractChapter "c3s01"
extractChapter "c3s02"
extractChapter "c3s03"
extractChapter "c3s04"
extractChapter "c3s07"
extractChapter "c4s02"
extractChapter "c4s04_1" "c4s04_book"
extractChapter "c4s04_2" "c4s04_continued_1"
extractChapter "c4s04_3" "c4s04_continued_2"
extractChapter "c4s04_4" "c4s04_finished"
extractChapter "c4s05_1" "c4s05_book"
extractChapter "c4s05_2" "c4s05_finished"
extractChapter "c4s06"
extractChapter "c6s01"
extractChapter "c6s02"
