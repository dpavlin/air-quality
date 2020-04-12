#!/bin/sh

MEASUREMENT=mq /home/dpavlin/air-quality/dsm501.pl /dev/serial/by-path/pci-0000:00:1d.0-usb-0:2:1.0-port0 'http://10.60.0.92:8086/write?consistency=any&db=rot13' # debee
