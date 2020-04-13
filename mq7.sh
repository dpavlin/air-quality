#!/bin/sh -xe

# https://github.com/dpavlin/mq7-co-monitor/
MEASUREMENT=mq7 /home/pi/air-quality/dsm501.pl /dev/serial/by-path/platform-3f980000.usb-usb-0:1.2:1.0-port0
