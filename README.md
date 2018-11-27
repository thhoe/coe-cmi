# coe-cmi
CAN over Ethernet Monitoring Interface

1 Allgemein
COE-MI steht für CAN over Ethernet Monitoring Interface. Es ermöglicht die Überwachung von  Reglern der Firma TA (Technische Alternative) aus Österreich. 
2 Installation
2.1 COE-MI
COE-MI ist ein in Perl geschriebener Daemon. Eine funktionierende  Perl-Installation ist Voraussetzung. Soll Nagios genutzt werden muss nagios nsca installiert werden. Zur Installation müssen nur die Dateien an die richtige Stelle kopiert werden, und die Rechte richtig gesetzt sein. Das erfolgt durch entpacken des Archives mit root Rechten: 
root@nagios:~# tar xfvz coe-mi.tar.gz -C .	
Eine Liste der Dateien   ist im Anhang, eine Beschreibung der Funktion in der Datei selbst. Die Rechte sollten mit dehnen der benachbarten / übergeortneten übereinstimmen.
Der Daemion benödigt eine Feste IP-Adresse. 
