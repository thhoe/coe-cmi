#!/usr/bin/env perl
# reads data for ELV WDE1 weather receiver and sent to 'C.M.I'
# usage:
#
# V0.1 14.6.2019 Thomas Höpfner 
#

#modules
use strict;
use warnings;
use LWP::UserAgent;
use IO::Handle;
use Data::Dumper;
use IO::Socket::INET

#auto-flush
$| = 1;

#Variablen deklarieren
my ($socket,$data,$ip,$port,$file,@fields);



$ip='172.16.100.36';		#$ARGV[0]; #erster Paramenter wird in $ipaddr eingespeichert
$port = 5441;		#$ARGV[1]; #zweiter Paramenter wird in $ipaddr eingespeichert
$file='/run/wde1.2';

open($data, '<', $file) or die "Could not open '$file' $!\n";
 
while (my $line = <$data>) {
  chomp $line;
      @fields = split ";" , $line;
#      print Dumper(@fields), "\n";

}
close $data;


if (time()-$fields[1]<300){

my $B1    =54; 		#Knoten
my $B2    =2; 		#PDO
my $B3B4  =$fields[3]*10; 	#Wert1
my $B5B6  =$fields[4]; 	#Wert2
my $B7B8  =$fields[5]*10; 	#Wert3
my $B9B10 =0 ; 		#Wert4
my $B11   =1 ; 		#Einheit1
my $B12   =8 ; 		#Einheit2
my $B13   =1 ; 		#Einheit3
my $B14   =0 ; 		#Einheit4


#Socket erschaffen zur Kommunikation mit Server
sleep(2*$B2);
$socket=new IO::Socket::INET
(
                                
PeerAddr=>$ip,  #PeerAddr von $sock ist eingegebener Paramenter $ipaddr
                                
PeerPort=>$port,        #PeerPort von $sock ist eingegebener Paramenter $port
                                
Proto=>'udp'            #Transportprotokoll: UDP
                                
);

die "Konnte keine Verbindung herstellen: $!\n" unless $socket;


print "Mit $ip verbunden !\n";
        

#Hauptschleife 


# unsigned 8bit  Integer (Char  -> C)
# unsigned 16bit Integer (Short -> S)
# signed   32bit Integer (Long  -> l)
# unsigned 8bit  Integer (Char  -> C)

## Little Endian (X86 Order)
# on x86 Processors
#my $out=pack('CSlC',$zahl1,$zahl2,$zahl3,$zahl1);
# on PPC or other not x86 Processors force Little Endian
#my $out=pack('C<S<lC',$zahl1,$zahl2,$zahl3,$zahl1);

# Big Endian (Network Order)
my $out=pack('CCS<S<S<S<CCCC',$B1,$B2,$B3B4,$B5B6,$B7B8,$B9B10,$B11,$B12,$B13,$B14);

print "Sende Daten zum Server...\n";
$socket->send($out, 1024);
$socket -> close();  


}
