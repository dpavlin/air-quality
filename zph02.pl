#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Time::HiRes;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/serial/by-path/platform-3f980000.usb-usb-0:1.4.2:1.0';
my $influx_url = shift @ARGV || 'http://10.13.37.92:8086/write?consistency=any&db=rot13';

my $s = new Device::SerialPort( $port ) || die $!;
$s->baudrate(9600);
$s->databits(8);
$s->parity('none');
$s->stopbits(1);
$s->handshake('none');
$s->read_char_time(5);
$s->read_const_time(10);


while (1) {

	alarm 3;
	# Usb serial which I'm using is buggy and blocks from time to time.
	# This will ensure that we have passed here every 3 seconds
	# or we will be killed and systemd will restart us

	my ($len, $string) = $s->read(9);
	my $t = int( Time::HiRes::time() * 1_000_000_000 );
	die $! if ! defined($len);
	if ( $len > 0 ) {
		my @v = unpack('C*', $string);
		#warn "# $len ",dump($string), dump( @v ), $/;

		my $sum = 0;
		# -2 is specified in datasheet, next byte is 0 so it's same as -1
		foreach my $i ( 0 .. $#v - 2 ) {
			$sum += $v[$i];
			$sum = $sum & 0xff;
		}
		$sum = ~$sum & 0xff;

		my $checksum = $v[8];
		my $pcnt = $v[3] + ( $v[4] / 100 );
		if ( $v[0] == 0xff && $sum == $checksum ) {
			my $influx = "zph02,dc=trnjanska pm25_pcnt=$pcnt $t";
			print "$influx\n";
			system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
		}
	}

};


$s->close;
