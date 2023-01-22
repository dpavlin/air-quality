#!/bin/bash -e
mac=A4:C1:38:D8:3F:9C
test ! -z "$1" && mac=$1


gatttool -b $mac --char-write-req --handle='0x0038' --value="0100" --listen | tee /dev/stderr | grep --line-buffered value: | while read bt ; do

#echo "XXX[$bt]"

v=$( echo $bt | awk '{ print "temperature=" strtonum("0x"$7$6) / 100, "humidity=" strtonum("0x"$8), "a=" strtonum("0x"$9), "b="strtonum("0x"$10) }' | sed 's/ /,/g' )

echo $(date +%Y-%m-%d\ %H:%M:%S) $mac $v

curl --silent -XPOST 'http://10.60.0.92:8086/write?consistency=any&db=rot13' --data-binary "mijia,dc=trnjanska,mac=$mac $v"

done # gattool
