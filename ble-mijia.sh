#!/bin/bash -e
mac=A4:C1:38:D8:3F:9C
test ! -z "$1" && mac=$1


gatttool -b $mac --char-write-req --handle='0x0038' --value="0100" --listen | tee /dev/stderr | grep --line-buffered value: | while read bt ; do

#echo "XXX[$bt]"

temphexa=$(echo $bt | awk -F ' ' '{print $7$6}'| tr [:lower:] [:upper:] )
humhexa=$(echo $bt | awk -F ' ' '{print $8}'| tr [:lower:] [:upper:])
temperature100=$(echo "ibase=16; $temphexa" | bc)
humidity=$(echo "ibase=16; $humhexa" | bc)
temperature=$(echo "scale=2;$temperature100/100"|bc)

echo $(date +%Y-%m-%d\ %H:%M:%S) $temperature $humidity

curl --silent -XPOST 'http://10.60.0.92:8086/write?consistency=any&db=rot13' --data-binary "mijia,dc=trnjanska,mac=$mac temperature=$temperature,humidity=$humidity"

done # gattool
