#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Time::HiRes;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/serial/by-path/platform-3f980000.usb-usb-0:1.5:1.2';
my $influx_url = shift @ARGV || 'http://10.13.37.92:8086/write?consistency=any&db=rot13';

my $s = new Device::SerialPort( $port ) || die $!;
$s->baudrate(9600);
$s->databits(8);
$s->parity('none');
$s->stopbits(1);
$s->handshake('none');
$s->read_char_time(1);
$s->read_const_time(10);
$s->debug(1);

$s->write("\xFF\x01\x86\x00\x00\x00\x00\x00\x79");

while (1) {

	my ($len, $string) = $s->read(9);
	my $t = int( Time::HiRes::time() * 1_000_000_000 );
	die $! if ! defined($len);
	if ( $len > 0 ) {
		my @v = unpack('C*', $string);
		if ( $#v < 8 ) {
			die "# $len ",dump($string), dump( @v ), $/;
		}

		my $sum = 0;
		foreach my $i ( 1 .. $#v - 1 ) {
			$sum += $v[$i];
			$sum = $sum & 0xff;
		}
		$sum = 0xff - $sum + 1;

		my $checksum = $v[8];
		my $co2 = $v[2] * 255 + $v[3];
		if ( $v[0] == 0xff && $sum == $checksum ) {
			my $influx = "mh-z19b,dc=trnjanska co2=$co2 $t";
			print "$influx\n";
			system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
		}
		sleep 1;
		$s->write("\xFF\x01\x86\x00\x00\x00\x00\x00\x79");
	}

};


$s->close;
