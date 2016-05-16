#!/usr/bin/perl -T

# 04.04.2015, C.A.Merz
# file: sudo cp /home/christian/perl/heizung.cgi /srv/www/cgi-bin/
# perl tools für Heizung

use strict;
use warnings;

use Time::localtime;

# use DBI;
use DBI qw(:sql_types); # implizit DBD::SQLite database handle

# ------------------------------------
# Prototyp:
sub zufall ($$$$);

# ------------------------------------
# globale Variablen, Initialisierung

# Datenquelle
my $DATABASE = "/srv/www/daten/heizung.dbf";

# DBI::SQLite database handle  
#my $dbh = DBI->connect("dbi:SQLite:dbname=$DATABASE","","");
my $DBH = DBI->connect("dbi:SQLite:dbname=$DATABASE", undef, undef, {
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
    # let DBD::SQLite to see if the bind values are numbers or not
  sqlite_unicode => 1,	# UTF-8  -! nicht bei WG !-
});

# Fremdschlüssel aktivieren
$DBH->do("PRAGMA foreign_keys = ON");

# ------------------------------------
# main ()
# ------------------------------------

# Seitenanfang ausgeben
seiten_anfang();
    
    my $statement;
    $statement = "select max(zeitpunkt) from temperatur_werte";
    my @row_ary  = $DBH->selectrow_array($statement);
    printf "max(zeitpunkt): %i\n", $row_ary[0];

    $statement = 
    "INSERT INTO temperatur_werte VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    my $sth = $DBH->prepare($statement);
    
    $DBH->begin_work; # or $dbh->do('BEGIN TRANSACTION');
     
	print "\n","Zufallswerte einfügen ...\n";
	my $min = $row_ary[0] + 5;
	for ( my $i = $min ; $i < $min+50 ; $i++ ) {
	    my ($zeit,$raum,$aussen,$p1,$p2,$p3,$p4,$b1,$b2,$b3,$b4) =
	    ( 
	        $i,                      # zeitpunkt integer,
            zufall ( $i, 1, 20, 5 ), # raum_temp real,
            zufall ( $i, 5, 5, 15 ), # aussen_temp real,
            zufall ( $i, 10, 50, 25 ), # puffer_1 real,
            zufall ( $i, 7, 40, 10 ), # puffer_2 real,
            zufall ( $i, 5, 30, 5 ), # puffer_3 real,
            zufall ( $i, 2, 25, 5 ), # puffer_4 real,
            zufall ( $i, 2, 45, 5 ), # boiler_1 real,
            zufall ( $i, 2, 40, 5 ), # boiler_2 real,
            zufall ( $i, 2, 35, 5 ), # boiler_3 real,
            zufall ( $i, 2, 30, 5 ), # boiler_4 real,
        );
	    printf "t=%i,r=%f,a=%f,p1=%f,2=%f,3=%f,4=%f,b1=%f,2=%f,3=%f,4=%f\n",
	        $zeit,$raum,$aussen,$p1,$p2,$p3,$p4,$b1,$b2,$b3,$b4;
	    $sth->execute( undef,
	        $zeit,$raum,$aussen,$p1,$p2,$p3,$p4,$b1,$b2,$b3,$b4 );
	}
	
    $DBH->commit; # or $dbh->do('COMMIT');
	# nicht vergessen...
	$DBH->disconnect;

# Seitenende ausgeben
seiten_ende();


# ------------------------------------
# sub Routinen
# ------------------------------------

# ------------------------------------
# CGI Seitenanfang
sub seiten_anfang {
    print 
        "\n================================\n",
        "Perl Tools zur Heizungssteuerung\n",
        "================================\n",
        ;

}; # seiten_anfang

# ------------------------------------
# CGI Seitenende
sub seiten_ende {
    print 
        "\n\n-- (c) Cristian Merz, 2015 --\n\n",
        ;

}; # seiten_ende

# ------------------------------------
# Hilfsfunktionen
# ------------------------------------

# ------------------------------------
# Hilfsfunktionen fuer Entwicklung

# ------------------------------------
sub dump_short {

my $cgi;

    print "-- Parameter: \n";
    foreach my $name ( $cgi->param ) {
        print " $name: ";
        foreach my $value ( $cgi->param( $name ) ) {
            print "$value, ";
        };
        print "\n";
    };
    print "--\n";

}; # dump_short



# ------------------------------------
# MathLib
# ------------------------------------

sub sign ($) {
	# Vorzeichen des uebergebenen Wertes € { -1, 0, 1 }
	my ( $arg ) = shift;
	if( $arg > 0 ) { return 1 };
	if( $arg == 0 ) { return 0 };
	if( $arg < 0 ) { return -1 };
}

sub round ($$) {
	# der uebergebene Wert (1. Argument) wird auf die gewuenscht Anzahl 
	# Nachkommastellen (2. Argument) gerundet
	my ( $wert ) = shift;
	my ( $precision ) = shift; # Anzahl Nachkommastellen
	$precision = 10 ** $precision ;
	return int( $wert * $precision ) / $precision;
}

sub zufall ($$$$) {
	# generiert einen Zufallswert auf Sinus-Basis
	# Aufrubeispiel: zufall ( x, 2, 45, 5 );
	#	die Werte pendeln um die Basis 45 im Bereich [45-5..45+5]
	# 	zu 2*sin(x) wird ein Zufallswert € [0..5-2[ zufällig addiert oder subtrahiert
	my ( $wert ) 		= shift; # x-Wert
	my ( $sin_faktor )	= shift; # Faktor für sin(x) 
	my ( $basis ) 		= shift; # Mittelwert f(x)
	my ( $streuung ) 	= shift; # wie weit der Mittelwert max. ueber- und 
					 # unterschritten werden kann
	return $basis + round( $sin_faktor * sin($wert) , 2 ) + 
		sign( rand() - 0.5 ) * round( rand( $streuung - $sin_faktor ), 2 );
}


