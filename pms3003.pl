#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Time::HiRes;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/serial/by-path/platform-3f980000.usb-usb-0:1.3:1.0-port0';
my $influx_url = shift @ARGV || 'http://10.60.0.92:8086/write?consistency=any&db=rot13';

my $debug = $ENV{DEBUG} || 0;

my $s = new Device::SerialPort( $port ) || die $!;
$s->baudrate(9600);
$s->databits(8);
$s->parity('none');
$s->stopbits(1);
$s->handshake('none');
$s->read_char_time(5);
$s->read_const_time(100);

my @names = qw(
pm1_0_s
pm2_5_s
pm10_s
pm1_0
pm2_5
pm10
pm1_0_r
pm2_5_r
pm10_r
);


while (1) {

	my ($len, $string) = $s->read(24);
	my $t = int( Time::HiRes::time() * 1_000_000_000 );
	die $! if ! defined($len);
	if ( $len > 0 ) {
		my @v = unpack('n*', $string);
		warn "# $len ",dump($string), dump( @v ), $/ if $debug;
		my $header = shift @v; 
		my $checksum = pop @v;	  # remove checksum
	
		my $sum = 0;
		foreach my $b ( unpack('C*', substr($string,0,-2) ) ) {
			$sum += $b;
		}
		$sum = $sum & 0xffff;

		if ( $header == 0x424d && $sum == $checksum ) {
			shift @v; # skip len

			my $influx = "pms3003,dc=trnjanska ";
			foreach my $i ( 0 .. $#v ) {
				$influx .= "$names[$i]=$v[$i],";
			};
			$influx =~ s/,$//;
			$influx .= " $t";
			print "$influx\n" if -e '/dev/shm/air-debug';
			system "curl --max-time 2 --silent -XPOST '$influx_url' --data-binary '$influx'"
		}
	}

};


$s->close;
