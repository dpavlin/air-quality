#!/bin/sh -e
mac=A4:C1:38:90:DC:63
test ! -z "$1" && mac=$1

# based on https://ndimension.design.blog/2021/12/16/reading-data-from-xiaomi-mi-temperature-and-humidity-monitor-2-lywsd03mmc/
# find sensor with: sudo hcitool lescan
# A4:C1:38:D8:3F:9C LYWSD03MMC

gatttool -b $mac --char-write-req --handle='0x0038' --value="0100" --listen | \
	awk 'BEGIN { OFS=","; ORS="\n" } /value:/ { print "temperature=" strtonum("0x"$7$6) / 100, "humidity=" strtonum("0x"$8), "battery=" strtonum("0x"$10$9) / 1000 ; fflush() }' | \
	xargs -i curl --silent -XPOST 'http://10.60.0.92:8086/write?consistency=any&db=rot13' --data-binary "mijia,dc=trnjanska,mac=$mac {}"

