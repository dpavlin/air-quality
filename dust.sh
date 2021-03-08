#!/bin/sh -xe

cd /nuc/air-quality/
MEASUREMENT=dust ./dsm501.pl /dev/ttyACM0
