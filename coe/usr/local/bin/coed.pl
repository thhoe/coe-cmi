#!/usr/bin/env perl
# sendet digitale Werte an das C.M.I
#
# V0.1 19.7.2019 Thomas Höpfner 
#

#modules
use strict;
use warnings;
use LWP::UserAgent;
use IO::Handle;
use IO::Socket::INET

#auto-flush
$| = 1;

#Variablen deklarieren
my ($socket,$data,$ip,$port,$dec);



$ip='172.16.100.36';		#$ARGV[0]; #erster Paramenter wird in $ipaddr eingespeichert
$port = 5441;		#$ARGV[1]; #zweiter Paramenter wird in $ipaddr eingespeichert

my $KN    =54; 		#Knoten

my $bin = '10011001';


chomp $bin;
$dec=0;

while (!((my $dig = chop $bin) eq '')) {
    $dec = 2*$dec + $dig;
}

print $dec . "\n";


#Socket erschaffen zur Kommunikation mit Server
sleep(1);
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
my $out=pack('CCS<S<S<S<CCCC',$KN,0,$dec,0,0,0,0,0,0,0);

print "Sende Daten zum Server...\n";
$socket->send($out, 1024);
$socket -> close();  



