#!/usr/bin/perl 

#coe-mi.pl

use strict 'vars'; #strict macht debugging einfacher
use IO::Socket::INET;#Modul wird benoetigt um Netzwerkfunktionen zu nutzen
use LWP::UserAgent;#Modul wird für http-post benödigt
use Getopt::Long;# Modul wird für die Auswertunf von Kommandozeilenparametern gebraucht.

#Variablen deklarieren
 my ($socket, $message,$peer_address,$peer_port);#UDP-Socket
 my ($i,$j,$x,$y,$z); # Variablen für Schleifen
 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst,$ZEIT,$TIME) ;
 our $IP;     		# An diese IP sendet das CMI die Daten. Der Port 5441 ist fest.
 our $URL;			# auf dieser URL hört der Volkzähler um Daten Anzunehmen
 our $PLUG;			# Pfad zu meinen Nagios Plugin
 our %ADR;			# Liste der Knoten
 our %KAN;			# Liste der Kanäle
 our %BEZ;		  	# HASH für die Beschreibung der Knoten und Kanäle
 our %CMD;			# HASH für das NAGIOS Kommando
 our %UUID;			# HASH für  Volkszähler UUID
 my $N;				# Werte ohne Einheit 


# Default-Werte festlegen und mit übergebenen Parametern überschreiben
 my $CONF="/etc/coe/coe-mi.cfg" ;
 my $VERBOSE;
 my $DIR="/tmp/";
 my $LOG;
 my $CHECK;
 GetOptions ('verbose' => \$VERBOSE,
             'conf=s'  => \$CONF,
			 'dir=s'   => \$DIR,
			 'log'     => \$LOG,
			 'test'   => \$CHECK);
 $VERBOSE=($VERBOSE or $CHECK);

 # Daten aus der Konfigurationsdatei einlesen			 
 &parse_config ($CONF);

 # Daten aus der Konfigurationsdatei zur Kontrolle ausgeben
 if ($VERBOSE) {&check_config();};
  
# Daten als Listen/Hash eingeben  
 my @BOOL=("AUS","EIN");		# Text für digitale Wert
 my %EINHEIT=(
			 0 => " ",
			 1 => "°C",
			 2 => "W/m²",
			 3 => "l/h",
			 4 => "Sek",
			 5 => "Min",
			 6 => "l/Pulse",
			 7 => "Kelvin",
			 8 => "%",
			 9 => "kW",
			 10 => "kWh",
			 11 => "MWh",
			 12 => "V",
			 13 => "mA",
			 14 => "h",
			 15 => "d",
			 16 => "Pulse",
			 17 => "K",
			 18 => "km/h",
			 19 => "Hz",
			 20 => "l/min",
			 23 => "bar");
 my%FACTOR=(
			1 => 10,
            8 => 10,
			23 => 100);
 if ($VERBOSE) {
 print "\n====\nEinheiten\n====\n"; 
 print "#\tEinheit\tFaktor";
 foreach (sort { $a <=> $b } keys %EINHEIT) {
 print "\n$_\t$EINHEIT{$_}\t";
 if ($FACTOR{$_}){print $FACTOR{$_};};
 };
print "\n====\n\n";
}

if ($CHECK){exit;};

my $continue=1;
#my $continue = &daemonize();


{#Socket erschaffen zur Kommunikation mit Client
$socket=new IO::Socket::INET(
LocalHost =>$IP,#LocalHost von $socket ist eingegebener Paramenter $ip
LocalPort=>'5441',#LocalPort von $sock ist eingegebener Paramenter $port
Proto=>'udp'#Transportprotokoll: UDP
);
die "Konnte keine Verbindung herstellen: $!\n" unless $socket; #wenn fehlgeschlagen dann schließen

print "UDP Server bereit und wartet auf eine Verbingung $IP\n";
}

if ($LOG){print "Die Daten werden in $DIR gelogt.\n";};

#Hauptschleife  



while ($continue) {

#empfange bis zu 1024 bytes von client, packe empfangene Daten in $message Variable     
        $socket->recv($message,1024);
		my $client_address = $socket->peerhost();
        $TIME = time();
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		$year += 1900;
		$mon +=1;
		$ZEIT = sprintf("%02d.%02d.%04d %02d:%02d:%02d", $mday , $mon , $year , $hour, $min, $sec) ;
		
		# die Rohdaten in einzelne Zeichen splitten je 8bit
		my @data=split(//,$message);
 if ($VERBOSE) {print "\a\n";};

		# Daten Nach Hex-Werte konvertieren
		@data=map{ unpack('H*',$_) }@data;
		
		
		# das array wider zusammenführen
		my $hex_data=join(' ', @data);

		# und alles ausgeben
 if ($VERBOSE) {print "$ZEIT\t$client_address\t$hex_data\n";};
		
		my $KNOTEN= hex($data[0]);
		$x="";
		if ($BEZ{$KNOTEN}){$x="($BEZ{$KNOTEN})"; 
 if ($VERBOSE) {print "\t\t\t\tAbsender => $client_address $KNOTEN $x\n\n";};
 
		# Nagios Ausgabe
		if (time()-120 > $ADR{$KNOTEN}){
		
		$z = $TIME-$ADR{$KNOTEN};
		$y = $KNOTEN;
		
			if($CMD{$y}){
				$z = "$PLUG$CMD{$y} $TIME $client_address $y \"$BEZ{$y}\"";
				$x = $x."CMD => $z\t";
				# &ngcmd ($z);
				if ($VERBOSE) {print "\aNagios CMD => $y $x\t$z s\n";};
				system ($z);
				};
				
		$ADR{$KNOTEN} = $TIME;
		}

		
		my $PDO=hex($data[1]);

	
		if ($PDO > 0 ){

		# 4 analoge Werte in einen Datensatz
		for (my $i = 0 ; $i < 4;$i++) {
			
			my $W1=unpack('s',pack 's', hex($data[3+$i+$i].$data[2+$i+$i]));
			#my $W1="$data[$PDO+2+$i+$i]$data[$PDO+1+$i+$i]";
			#$W1 = hex($W1);
			my $E1=hex($data[10+$i]);
			
			if ($FACTOR{$E1}){
			my $D1=log($FACTOR{$E1})/log(10);
			$D1="%.".$D1."f";
			$W1=sprintf($D1,$W1 / $FACTOR{$E1});
			}
			
			$N = $W1;
			
			if ($EINHEIT{$E1}){
			$W1 = "$W1 $EINHEIT{$E1}";
			}
			
			$y = $KNOTEN."#".($i+ $PDO*4 +13);
			  $x="$KNOTEN\t$y\t$W1    \t";
			  if ($BEZ{$y}){
				$x=$x."Bez. => $BEZ{$y}\n\t\t\t\t";
				if($UUID{$y}){
					$x =$x."UUID => $UUID{$y}\n\t\t\t\t";
					&vzpost ($UUID{$y}, $N);
					};
				if($CMD{$y}){
					$z = "$PLUG$CMD{$y} $TIME $client_address $y $W1 \"$BEZ{$y}\"";
					$x = $x."CMD => $z\n\t\t\t\t";
					system ($z);
					};
			    if ($VERBOSE) {print"$x\n";};
			    }

		};	
			
			}	
		else{
			#16 Digitale Werte sind in einen Datensatz
						
			my $W1= sprintf( "%08b", hex($data[3]));
			my $W2= sprintf( "%08b", hex($data[2]));
			my $W = reverse "$W1$W2";  # Anpassen der Reienfolge

			#Aus den Daten ein ARRAY machen
			my @DIGI=split(//,$W);
			
		  for (my $i = 0 ; $i < 16;$i++) {
			  $y = $KNOTEN."#".($i +1);
			  $x="$KNOTEN\t$y\t$BOOL[$DIGI[$i]]\t";
			  if ($BEZ{$y}){
				$x="$x\tBez. => $BEZ{$y}\n\t\t\t\t";
				if($UUID{$y}){
					$x =$x."UUID => $UUID{$y}\n\t\t\t\t";
					&vzpost ($UUID{$y}, $DIGI[$i]);
										};
				if($CMD{$y}){
					$z = "$PLUG$CMD{$y} $TIME $client_address $y $DIGI[$i] \"$BEZ{$y}\"";
					$x = $x."CMD => $z\n\t\t\t\t";
					system ($z);
					
					};
			    if ($VERBOSE) {print"$x\n";};
			    }
			#
		    }
			}		
		};
}
#Schließe Socket
$socket -> close();               
  

sub vzpost {# Daten per post an den Server senden
# ========================================
# http://xmodulo.com/2013/05/how-to-send-http-get-or-post-request-in-perl.html
# http://wiki.volkszaehler.org/development/api/reference
# das geht:  curl -d "" http://localhost/middleware.php/data/5ae94780-ecc7-11e2-91b8-33a3b9ebc717.json?value=24.9


        my $server_endpoint = "http://$URL/data/$_[0].json?value=$_[1]"; 
		#print $server_endpoint;
		#my $server_endpoint = "http://localhost/middleware.php/data/${uuid}.json?value=" . $val;
        #print "ss=" . $server_endpoint . "\n"; #

        my $ua = LWP::UserAgent->new;
		#print $ua . "\n"; #
        # set custom HTTP request header fields
        my $req = HTTP::Request->new(POST => $server_endpoint);
        $req->header('content-type' => 'application/json');
        #$req->header('x-auth-token' => 'kfksj48sdfj4jd9d');

        # add POST data to HTTP request body
        $req->content(" ");

        $ua = LWP::UserAgent->new;
        my $resp = $ua->request($req);
        if ($resp->is_success) {
                my $message = $resp->decoded_content;
		#		print "Received reply: $message\n";
        } else {
                print "HTTP GET error code: ", $resp->code, "\n";
                print "HTTP GET error message: ", $resp->message, "\n";
        }
    }

sub check_config {	# Konfiguration ausgeben

print "\n\n====\nGlobale Einstellungen\n====\n";
if($IP){print "An diese IP sendet das CMI die Daten. Der Port 5441 ist fest. : $IP\n";}else{print"Eine IP muss angeben werden.\n";};
if($URL){print "Auf dieser URL hört der Volkzähler um Daten Anzunehmen : $URL\n";}else{print"Volkszähler ist nicht aktiviert\n";};
if($PLUG){print "Hier stehen die Nagios-Plugin : $PLUG\n";}else{print"Nagios ist nicht aktiviert\n";};

print "\n====\nKnoten\n====\n"; 
foreach (keys %ADR) {
print "==\nAdresse : $_\n";
if ($BEZ{$_}){print "Bezeichnung : $BEZ{$_}\n"};
if ($CMD{$_}){print "Nagios CMD : $CMD{$_}\n"};
print "==\n";
}

print "\n\====\nWerte\n====\n"; 
foreach (sort { $a <=> $b } keys %KAN) {
print "==\nAdresse : $KAN{$_}\n";
if ($BEZ{$KAN{$_}}){print "Bezeichnung : $BEZ{$KAN{$_}}\n"};
if ($CMD{$KAN{$_}}){print "Nagios CMD : $CMD{$KAN{$_}}\n"};
if ($UUID{$KAN{$_}}){print "Volkszähler UUID : $UUID{$KAN{$_}}\n"};
print "==\n";
}

print "\n\n====\nENDE Konfigurationsdatei\n====\n\n"; 
}

sub parse_config {	# Daten Aus der Konfiguration lesen
 my $file = shift;
 local *CF;

 open(CF,'<'.$file) or die "Open $file: $!";
 read(CF, my $data, -s $file);
 close(CF);

 my @lines  = split(/\015\012|\012|\015/,$data);
 my $config = {};
 my $count  = 0;
 my $T_ADR;	# temporäre Adresse
 my $T_KAN;	# temporärer Kanal
 
 
 foreach my $line(@lines)
 {
  $count++;

  next if($line =~ /^\s*#/);
  next if($line !~ /^\s*\S+\s*=.*$/);

  my ($key,$value) = split(/=/,$line,2);

  # Remove whitespaces at the beginning and at the end

  $key   =~ s/^\s+//g;
  $key   =~ s/\s+$//g;
  $value =~ s/^\s+//g;
  $value =~ s/\s+$//g;
  
  #die "Configuration option '$key' defined twice in line $count of configuration file '$file'" if($config->{$key});
  
  $config->{$key} = $value;

  
  SWITCH: {
  	# An diese IP sendet das CMI die Daten. Der Port 5441 ist fest.
	$key eq "IP" && do	{
						$IP = $value;
						last SWITCH;
						};
	# auf dieser URL hört der Volkzähler um Daten Anzunehmen						
    $key eq "URL" && do {
						$URL = $value;
						last SWITCH;
						};  
	# Liste der Knoten						
    $key eq "ADR" && 	do {if ($value) {
                       $T_ADR = $value;
					   $T_KAN = $value;
					   $ADR{$value} = 1;
					   $BEZ{$T_KAN} = "Virtuell $T_KAN";
					   };
                       last SWITCH;
					   };
	# Liste der Kanäle
	$key eq "KAN" && 	do {if ($value) {
                       $T_KAN = $T_ADR*32+$value;
					   #print "KAN:	$T_KAN\n";
					   $KAN{$T_KAN} = $T_ADR."#".$value;
					   $T_KAN = $T_ADR."#".$value;
					   $BEZ{$T_KAN} = "Kanal $T_KAN";
					   };
                       last SWITCH;
					   };
	# Beschreibung der Knoten und Kanäle
	$key eq "BEZ" &&	do { if ($value) {
					   $BEZ{$T_KAN} = $value;
					   #print "BEZ:	$T_KAN=$BEZ{$T_KAN}\n";
					   };
					   last SWITCH;
					   };
	# HASH für  Volkszähler UUID
	$key eq "UUID" &&	do {  if ($value) {
					   $UUID{$T_KAN} = $value;
					   #print "UUID:	$T_KAN=$UUID{$T_KAN}\n";
					   };
					   last SWITCH;
                       };
	# HASH für das NAGIOS Kommando
	$key eq "CMD" &&	do {  if ($value) {
					   $CMD{$T_KAN} = $value;
					   #print "CMD:	$T_KAN=$CMD{$T_KAN}\n";
					   };
					      last SWITCH;
					   };
	# Pfad zu meinen Nagios Plugin
	$key eq "PLUG" && do	{
						$PLUG = $value;
						last SWITCH;
						};
					   
	do { print "\a\n\nUnbekanter Schlüssel Zeile $count:\t$key\t$value\n";exit;}
	}
  
}
 

 return $config;
}

sub daemonize {
   use POSIX;
   POSIX::setsid or die "setsid: $!";
   my $pid = fork ();
   if ($pid < 0) {
      die "fork: $!";
   } elsif ($pid) {
   open(DATEI,">/var/run/coe-mi.pid");
   print DATEI $pid;     
   exit 0;
   }
   chdir "/";
   umask 0;
   foreach (0 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024))
      { POSIX::close $_ }
   open (STDIN, "</dev/null");
   open (STDOUT, ">/dev/null");
   open (STDERR, ">&STDOUT");
 }
