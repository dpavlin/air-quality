#!/usr/bin/perl
use warnings;
use strict;

use Time::HiRes;

# sudo apt install libiio-utils mosquitto-clients

my $influx_url = shift @ARGV || 'http://10.60.0.92:8086/write?consistency=any&db=rot13';

my $delay = $ENV{DELAY} || 1;

my $hostname = `hostname -s`;
chomp($hostname);

while(1) {

	my $t = Time::HiRes::time;
	my $t_influx = int( $t * 1_000_000_000 );

	my $iio = `iio_info`;

	my $device;
	my $name;

	my $influx = '';

	foreach ( split(/\n/, $iio) ) {
		if ( m/iio:device\d+:\s+(\S+)/ ) {
			$device = $1;

			if ( $influx =~ m/,$/ ) {
				$influx =~ s/,$/ $t_influx\n/;
			} elsif ( $influx =~ m/ $/ ) { # only device
				$influx =~ s/\S+\s$//;
			}
			$influx .= "iio,dc=trnjanska,host=$hostname,device=$device ";

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

			$influx .= "$name=$val,";
		} else {
			#warn "# $_\n";
		}
	}

	$influx =~ s/,$/ $t_influx/;
	system "curl --silent -XPOST '$influx_url' --data-binary '$influx'";
	warn "$influx\n";

	my $dt = Time::HiRes::time + $delay - $t - 0.01;
	if ( $dt > 0 ) {
		sleep $dt;
	}
}
