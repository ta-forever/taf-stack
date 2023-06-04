#!/bin/env bash

folder=~/taf-stack/data/content/game_logs

inotifywait -m -q -e create -r --format '%w%f' $folder | while read fn; do
    echo "${fn}" | fgrep '.zip' && unzip -l "${fn}" | grep ErrorLog && unzip -p "${fn}" ErrorLog.txt | sendemail \
        -f "tac.taforever@gmail.com"  \
	-u "$(basename ${fn}):ErrorLog.txt"  \
	-t "${ERROR_EMAIL_DEST_ADDRESS}"  \
	-s "smtp.gmail.com:587"  \
	-o tls=yes  \
	-xu "tac.taforever@gmail.com"  \
	-xp "${ERROR_EMAIL_PASSWORD}"
done
