#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/ttyUSB0';
my $influx_url = shift @ARGV || 'http://10.13.37.229:8186/write?db=telegraf';
$influx_url = 'http://10.13.37.92:8086/write?db=rot13';

my $s = new Device::SerialPort( $port ) || die $!;
$s->baudrate(9600);
$s->databits(8);
$s->parity('none');
$s->stopbits(1);
$s->handshake('none');
$s->read_char_time(5);
$s->read_const_time(10);


while (1) {

	my ($len, $string) = $s->read(9);
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
			my $influx = "zph02,dc=trnjanska pm25_pcnt=$pcnt";
			print "$influx\n";
			system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
		}
	}

};


$s->close;
