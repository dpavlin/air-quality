#!/bin/sh

while true ; do

arecord -d 1 -r 96000 /dev/shm/tmp.wav
time=`date +'%s%N'`
info=`sox /dev/shm/tmp.wav -n stat 2>&1 | grep '[0-9][0-9][0-9]*$' | sed -e 's/[()]//g' -e 's/: */=/' -e 's/  */_/g' | tr '\n' ',' | sed 's/[, ]*$//'`
curl --silent -XPOST http://10.60.0.92:8086/write?db=rot13 --data-binary "fan,dc=trnjanska $info $time"

done
