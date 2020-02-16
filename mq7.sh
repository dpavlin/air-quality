#!/bin/sh -xe

# https://github.com/dpavlin/mq7-co-monitor/
MEASUREMENT=mq7 /home/dpavlin/air-quality/dsm501.pl /dev/serial/by-path/pci-0000:00:1a.7-usb-0:5.3.3:1.0-port0
