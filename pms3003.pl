#!/usr/bin/perl
use warnings;
use strict;
# sudo apt install libdevice-serialport-perl libdata-dump-perl
use Device::SerialPort;
use Data::Dump qw(dump);

my $port = shift @ARGV || '/dev/ttyUSB1';
my $influx_url = shift @ARGV || 'http://10.13.37.229:8186/write?db=telegraf';
$influx_url = 'http://10.13.37.92:8086/write?db=rot13';

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
	if ( $len > 0 ) {
		my @v = unpack('n*', $string);
		warn "# $len ",dump($string), dump( @v ), $/;
		my $header = shift @v; 
		if ( $header == 0x424d ) {
			shift @v; # skip len
			pop @v;	  # remove checksum
			my $influx = "pms3003,dc=trnjanska ";
			foreach my $i ( 0 .. $#v ) {
				$influx .= "$names[$i]=$v[$i],";
			};
			$influx =~ s/,$//;
			print "$influx\n";
			system "curl --silent -XPOST '$influx_url' --data-binary '$influx'"
		}
	}

};


$s->close;
