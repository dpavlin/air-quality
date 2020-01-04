#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Time::HiRes;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/ttyUSB2';
my $influx_url = shift @ARGV || 'http://10.13.37.229:8186/write?db=telegraf';
$influx_url = 'http://10.13.37.92:8086/write?db=rot13';

my $s = new Device::SerialPort( $port ) || die $!;
$s->baudrate(115200);
$s->databits(8);
$s->parity('none');
$s->stopbits(1);
$s->handshake('none');
$s->read_char_time(5);
$s->read_const_time(10);


while (1) {

	my ($len, $string) = $s->read(128);
	my $t = int( Time::HiRes::time() * 1_000_000_000 );
	die $! if ! defined($len);
	if ( $len > 0 ) {
		warn "# len=$len ",dump($string);
		if ( $string !~ m/^#/ ) {
			$string =~ s/[\r\n]+$//;
			$string =~ s/\s/,/g;
			my $influx = "dsm501,dc=trnjanska $string $t";
			print "$influx\n";
			system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
		} else {
			warn "SKIP: $string\n";
		}
	}

};


$s->close;
