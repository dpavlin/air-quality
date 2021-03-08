#!/usr/bin/perl
use warnings;
use strict;

use Time::HiRes;

# sudo apt install libiio-utils mosquitto-clients

my $hostname = `hostname -s`;
chomp($hostname);

while(1) {

	my $t = Time::HiRes::time;

	my $iio = `iio_info`;

	my $device;
	my $name;

	foreach ( split(/\n/, $iio) ) {
		if ( m/iio:device\d+:\s+(\S+)/ ) {
			$device = $1;
		} elsif ( m/(\S+):\s+\(input\)/ ) {
			$name = $1;
		} elsif ( m/attr\s+0:\s+input\svalue: (\d+[\.\d]+)/ ) {
			my $val = $1;
			if ( $val !~ m/\d+\.\d+/ ) {
				$val = $val / 1000;
			}
			my $topic = "iio/$hostname/$device/$name";
			#print "$topic $val\n";
			system "mosquitto_pub -h rpi2 -t $topic -m $val";
		} else {
			#warn "# $_\n";
		}
	}

	sleep Time::HiRes::time + 1 - $t;
}