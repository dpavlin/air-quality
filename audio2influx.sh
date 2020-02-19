#!/bin/sh

while true ; do

arecord -d 1 -r 96000 /dev/shm/tmp.wav 2>/dev/null
time=`date +'%s%N'`
info=`sox /dev/shm/tmp.wav -n stat 2>&1 | grep '[0-9][0-9][0-9]*$' | sed -e 's/[()]//g' -e 's/: */=/' -e 's/  */_/g' | tee /dev/shm/audio | tr '\n' ',' | sed 's/[, ]*$//'`
curl --silent -XPOST 'http://10.60.0.92:8086/write?consistency=any&db=rot13' --data-binary "fan,dc=trnjanska $info $time"

done
