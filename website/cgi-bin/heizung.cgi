#!/usr/bin/perl -T

# 03.04.2015, C.A.Merz
# file: sudo cp /home/christian/perl/heizung.cgi /srv/www/cgi-bin/

use strict;
use warnings;

use Time::localtime;
my $TM;


# === CONTROLLER ===============================================================
# Ablaufsteuerung über CGI
use CGI qw(*table);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Pretty qw( :html3 );
my $CGI;

$CGI = CGI->new; 


# === VIEW =====================================================================
# SVG zur Präsentation
#use SVG;
use SVG (-indent => "  ",   # 2 Blank statt TAB zum Einrücken verwenden
-nocredits  => 1,    # enable/disable credit note comment
-namespace  => '',   # The root element's (and it's children's) namespace prefix
                     # ! wenn nicht '', werden "inline" Grafiken nicht
                     #   ausgegeben !
);
my $SVG;

# Konfiguration der Grafik
my %SVG_CONF = ( 
    # Max.Größe der Grafik
        max_x        => 1000,
        max_y        => 500,
    # Abstand vom Rand
        offset      => 20,
    # Ursprung Koordinatensystem (0,0) = (x_00,y_00)
        x_00         =>  50,    # ist fest 
        y_00_default => 450,    # default max_y-offset; 
        y_00         => 450,    # default max_y-offset; 
                                # wird bei negat. Y-Werten nach oben geschoben
        y_step       =>   0,    # Skalierung wir gesetzt in koordsystem_zeichnen
                                # die Schrittweite ist abhängig von der Anzahl
                                #    der unterzubringenden Punkte
);
my %AKT_CONF = %SVG_CONF;

# je Diagramm gibt es max. 4 Temperaturwerte
my @SVG_FARBEN = (qw(black green red blue));

$SVG = SVG->new( width =>$SVG_CONF{max_x}, height => $SVG_CONF{max_y},
        stroke => 'black', 'font-family' => "Courier", );


# === MODEL ====================================================================
# Saten liegen in einer SQLight Datenbank
use DBI qw(:sql_types); # implizit DBI::SQLite database handle
my $DBH;

my $DATABASE = "../../db/measurements.db";

$DBH = DBI->connect("dbi:SQLite:dbname=$DATABASE", undef, undef, {
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
    # let DBD::SQLite to see if the bind values are numbers or not
  sqlite_unicode => 1,	# UTF-8  -! nicht bei WG !-
});

# Fremdschlüssel aktivieren
$DBH->do("PRAGMA foreign_keys = ON");


# === MATHLIB ==================================================================
# === Prototypen =
# ermittelt den kleinsten und größten Wert der übergebenen Zahlen-Liste
sub min_max(@);


# ------------------------------------------------------------------------------
# globale Variablen, Initialisierung

# aktueller Zeitpunkt
$TM = localtime;
my $stand = sprintf "Stand vom: %02d.%02d.%04d", 
                $TM->mday, ($TM->mon)+1, ($TM->year)+1900;


# === CONTROLLER ===============================================================

# === MODEL ====================================================================

# === VIEW =====================================================================


# ------------------------------------
# main ()
# ------------------------------------

# CONTROLLER: CGI Seitenanfang ausgeben
seiten_anfang( $CGI );


# alle Messwerte des Tages (=ab startzeitpunkt) einlesen
my $WERTE_REF = messwerte_lesen( $DBH, 0);
my $EXTREMWERTE_REF = extremwerte_ermitteln ( $WERTE_REF );

# 1. Raumtemp./Aussentemp.
my @min_max = min_max(
    $EXTREMWERTE_REF->{max_raum_temp}, $EXTREMWERTE_REF->{min_raum_temp}, $EXTREMWERTE_REF->{max_aussen_temp}, $EXTREMWERTE_REF->{min_aussen_temp}
);

# VIEW: Koordinatensystem und Kurven erstellen und ausgeben
koordsystem_zeichnen( $SVG, 'Raumtemperatur - Aussentemperatur', @min_max );


# SVG Temp.Kurven für die gewünschten Elemente zeichnen
temperatur_kurven_zeichnen( $SVG, $WERTE_REF, "raum_temp", "aussen_temp" );
    #my $elem = shift;       # SVG Element
    #my $ary_ref = shift;    # Werte aus der DB
    #my @elemente = @_;      # innen/aussen, puffer1-4, boiler1-4


print $SVG->to_xml( # (alias: to_xml render serialise serialize)
#print $SVG->xmlify(
    -inline   => 1,
    #-namespace => "", 
        # ! "", sonst wird NICHTS angezeigt ! default ""
        # xmlify überschreibt alle mit NEW angelegten namespaces
    #-pubid => "-//W3C//DTD SVG 1.0//EN",   # optional/default
);



# Ablaufsteuerung: Aktion je nach gedrücktem Button ausführen

if ( $CGI->param( 'submit_messwerteliste' ) ) {
    # Eigentuemerliste ausgeben 
    messwerteliste_ausgeben( $CGI, $DBH );
#} elsif ( $CGI->param( 'submit_neuer_eigentuemer' ) ) {
#    # neuer Eigentuemer
#    neuer_eigentuemer( $CGI, $DBH );

# default Startseite    
} else {
    # submit_default, default: Startseite ausgeben 
    #startseite_ausgeben( $CGI );
    #messwerteliste_ausgeben( $CGI, $DBH );
}



my $rc  = $DBH->disconnect;

# CGI Seitenende ausgeben
seiten_ende( $CGI );


# ------------------------------------
# sub Routinen
# ------------------------------------

# ------------------------------------

# === CONTROLLER ===============================================================

# ------------------------------------
# CGI Seitenanfang
sub seiten_anfang {
    my $cgi = shift;
    print 
        $cgi->header,
        $cgi->start_html( 'Heizungssteuerung' ),
        $cgi->h1( {-align=>"CENTER"}, 'Heizungssteuerung' );
    dump_short($cgi);

    # warnings duerfen erst aktiviert werden, wenn der CGI.header geschrieben ist
    warningsToBrowser(1);   

}; # seiten_anfang

# ------------------------------------
# CGI Seitenende
sub seiten_ende {
    my $cgi = shift;
    print 
        '<br/><br/>-- (c) Christian Merz, 2015 --',
        $cgi->end_html;

}; # seiten_ende


# === MODEL ====================================================================

# ------------------------------------
# alle Grundstücke eines Eigentuemers ausgeben
# - dummy - test -
sub messwerteliste_ausgeben {
    my $cgi = shift;
    my $dbh = shift;

    my $zeilen = 0;

    print 
        $cgi->h2( "Messwerte" );

    # Button fuer neues Grundstück ausgeben
###     print 
###     $cgi->start_form,
###     $cgi->hidden( -name=>'id_nr', -value=>"$id_nr" ),
###     $cgi->submit( -name=>'submit_insert_flur', -value=>'Neues Grundstück' );

    print 
        $cgi->start_table( { -border => 1 } ),
        $cgi->Tr( [
        $cgi->th( [ "ID", "Zeitpkt", "RaumTemp", "AussenTemp",
            "Puffer1", "Puffer2", "Puffer3", "Puffer4",
            "Boiler1", "Boiler2", "Boiler3", "Boiler4" ] ),
        ] );

    # zu dem Eigentuemer alle Grundstücke einlesen
    my $sth = $dbh->prepare("SELECT * FROM temperatur_werte ORDER BY id");
    $sth->execute();
    while ( my @zeile = $sth->fetchrow_array ) {
        $zeilen++;
    
        # die ROWID wird als submit Button ausgegeben
        my $flur_button = sprintf '%s',
            $cgi->submit( -name=>'submit_flur_bearbeiten', -value=>"$zeile[0]" );
    
        # Zeile ausgeben
        print
            $cgi->Tr(
                $cgi->td( [ @zeile ] )  
            );                  
    };

    # Ende Tabelle/Formular
    print 
        $cgi->end_table, 
        $cgi->end_form, 
        $cgi->p( "$zeilen Zeile(n)." );

}; # messwerteliste_ausgeben






# ------------------------------------
# alle Messwerte des Tages (=ab startzeitpunkt) einlesen
sub messwerte_lesen {
    my $dbh   = shift;
    my $start = shift;

    # perldoc DBI:
    #  my $emps = $dbh->selectall_arrayref(
    #      "SELECT ename FROM emp ORDER BY ename",
    #      { Slice => {} }
    #  );
    #  foreach my $emp ( @$emps ) {
    #      print "Employee: $emp->{ename}\n";
    #  }

    # Messwerte einlesen
    my $ary_ref  = $dbh->selectall_arrayref(
        "SELECT * FROM temperatur_werte " .
        "where ? <= zeitpunkt and zeitpunkt <= 24+? ORDER BY id",
        { Slice => {} },
        $start, $start
    );
    # DEV = proof of concept
    #print "<p>\n";
    #foreach my $std ( @$ary_ref ) {
    #    print "ID: $std->{id} <br />\n";
    #}
    #print "</p>\n";

    return $ary_ref;

}; # messwerte_lesen


# ------------------------------------
# aus den Messwerten des Tages (s. messwerte_lesen) die Extremwerte ermitteln
sub extremwerte_ermitteln {
    my $ary_ref   = shift;

    my %extremwerte = (
        max_raum_temp   => -100,
        max_aussen_temp => -100,
        max_puffer_1    => -100,
        max_puffer_2    => -100,
        max_puffer_3    => -100,
        max_puffer_4    => -100,
        max_boiler_1    => -100,
        max_boiler_2    => -100,
        max_boiler_3    => -100,
        max_boiler_4    => -100,
        min_raum_temp   =>  100,
        min_aussen_temp =>  100,
        min_puffer_1    =>  100,
        min_puffer_2    =>  100,
        min_puffer_3    =>  100,
        min_puffer_4    =>  100,
        min_boiler_1    =>  100,
        min_boiler_2    =>  100,
        min_boiler_3    =>  100,
        min_boiler_4    =>  100,
    );

    foreach my $idx ( @$ary_ref ) {
        # Raumtemperatur
        if ($idx->{raum_temp} > $extremwerte{max_raum_temp}) { $extremwerte{max_raum_temp} = $idx->{raum_temp} };
        if ($idx->{raum_temp} < $extremwerte{min_raum_temp} ) { $extremwerte{min_raum_temp} = $idx->{raum_temp} };
        # Aussentemperatur
        if ($idx->{aussen_temp} > $extremwerte{max_aussen_temp} ) { $extremwerte{max_aussen_temp} = $idx->{aussen_temp} };
        if ($idx->{aussen_temp} < $extremwerte{min_aussen_temp} ) { $extremwerte{min_aussen_temp} = $idx->{aussen_temp} };
        # Puffer 1 - 4
        # Boiler 1 - 4
    }
    # DEV = proof of concept
    print "<p>\n";
    print "max_raum_temp: $extremwerte{max_raum_temp} <br />\n";
    print "min_raum_temp: $extremwerte{min_raum_temp} <br />\n";
    print "max_aussen_temp: $extremwerte{max_aussen_temp} <br />\n";
    print "min_aussen_temp: $extremwerte{min_aussen_temp} <br />\n";
    print "</p>\n";

    return \%extremwerte;

}; # extremwerte_ermitteln









# === VIEW =====================================================================

# ------------------------------------
# SVG Koordinatensystem
sub koordsystem_zeichnen {
    #print "koordsystem_zeichnen param: @_<br />\n";
    my $elem = shift;
    my $titel = shift;
    my @y_min_max = @_;

    # --------------------
    # Vorbereitung Y-Achse

    # y_min_max auf nächsten Int runden
    @y_min_max = ( int($y_min_max[0])-1, int($y_min_max[1])+1 );
    #print "koordsystem_zeichnen y_min_max: @y_min_max<br />\n";

    # so viele Punkte müssen auf der y-Achse untergebracht werden:
    my $y_anz_punkte = $y_min_max[1] - $y_min_max[0] +1;

    # die Schrittweite ist abhängig von der Anzahl der unterzubringenden Punkte
    my $y_step = ( $y_anz_punkte <= 16 ) ? 30 :
                 ( $y_anz_punkte <= 32 ) ? 15 :
                 ( $y_anz_punkte <= 64 ) ?  7 :
                                            3 ;
    $AKT_CONF{y_step} = $y_step;
 
    # bei negativen y-Werten muss die X-Achse nach oben verschoben werden
    if ( $y_min_max[0] < 0 ) { 
        $AKT_CONF{y_00} = $AKT_CONF{y_00_default} + $y_step*$y_min_max[0];
    } else { 
        $AKT_CONF{y_00} = $AKT_CONF{y_00_default};
    }

    # --------------------
    my $tag;

# mein Koordinatensstem:
# die Y-Achse geht immer von (0,0) bis (0,max_y-offset)
# die X-Achse geht per default von (0,0) bis (0,max_x-offset)
#   für negative X-Werte wird sie "nach oben" geschoben
# Feature: "Stauchung der Y-Achse von 0 bis min(y-werte)


    # --------------------
    # die X-Achse geht von
    #   SVG(x_00, y_00) -> (max_x-offset, y_00)
    $tag = $elem->line(
        id => 'x_achse',
        x1 =>  $AKT_CONF{x_00},
        y1 =>  $AKT_CONF{y_00},
        x2 =>  $AKT_CONF{max_x}-$AKT_CONF{offset},
        y2 =>  $AKT_CONF{y_00},
    );
    $tag = $elem->text(
        id          => 'x_text',
        'font-size' => "20",
        x           => $AKT_CONF{max_x}-$AKT_CONF{offset}-40,
        y           => $AKT_CONF{y_00}-6,
        -cdata      => 'Zeit',
    );

    # --------------------
    # die Y-Achse geht von 
    #   SVG(x_00, y_00) -> SVG(x_00, offset)
    # ! y_00_default statt y_00 !
    $tag = $elem->line(
        id => 'y_achse',
        x1 =>  $AKT_CONF{x_00},
        y1 =>  $AKT_CONF{y_00_default},
        x2 =>  $AKT_CONF{x_00},
        y2 =>  $AKT_CONF{offset},
    );
    $tag = $elem->text(
        id     => 'y_text',
        'font-size' => "20",
        x      => $AKT_CONF{x_00},
        y      => $AKT_CONF{offset},
        -cdata => "Temperatur: $titel",
    );

# Transformationen
# transform="rotate(45 50 50)" # um 45° drehen um den Punkt (50,50)
# transform="translate(30)"    # in x-Richtung 30 Punkte verschieben
# transform="translate(30,40)" # in Richtung x=30, y=40 Punkte verschieben
# transform="translate(30) rotate(45 50 50)" # erst drehen, dann verschieben

    # --------------------
    # Hilfspunkt für Berechnungen
    my ($x0,$y0);

    # --------------------
    # Bemaßung X-Achse
    my $x_bemassung = $elem->group(
        id            => 'x_bemassung',
        'font-size'   => "10",
    );
    for (my $x=1; $x<=24; $x++) { 
        ($x0,$y0) = ($AKT_CONF{x_00}+30*$x, $AKT_CONF{y_00});
        # Striche senkrecht zur Achse
        $tag = $x_bemassung->line(
            id => "x$x",
            x1 =>  $x0,
            y1 =>  $y0-5,
            x2 =>  $x0,
            y2 =>  $y0+5,
        );
        # Beschriftung
        $tag = $x_bemassung->text(
            id     => "xtxt$x",
            x      => $x0,
            y      => $y0,
            transform => "translate(-5,15) rotate(45 $x0 $y0)",
            -cdata => "$x",
        );
    }

    # --------------------
    # Bemaßung Y-Achse


    my $y_bemassung = $elem->group(
        id            => 'y_bemassung',
        'font-size'   => "10",
    );
    #for (my $x=1; $x<=16; $x++) { 
    #    ($x0,$y0) = ($AKT_CONF{x_00}, $AKT_CONF{y_00}-30*$x);
    for (my $x=$y_min_max[0]; $x<=$y_min_max[1]; $x++) { 
        ($x0,$y0) = ($AKT_CONF{x_00}, $AKT_CONF{y_00}-$y_step*$x);
        # Striche senkrecht zur Achse
        $tag = $y_bemassung->line(
            id => "y$x",
            x1 =>  $x0-5,
            y1 =>  $y0,
            x2 =>  $x0+5,
            y2 =>  $y0,
        );
        # Beschriftung
        $tag = $y_bemassung->text(
            id     => "ytxt$x",
            x      => $x0-25,
            y      => $y0+5,
            -cdata => "$x",
        );
    }

## add a circle to the group
#$elem->circle( cx => 200, cy => 100, r => 50, id => 'circle_in_group_y', 
#    fill   => 'green' );

}; # koordsystem_zeichnen


# ------------------------------------
# SVG eine Temp.Kurve zeichnen
sub kurve_zeichnen {
    #print "kurve_zeichnen <br />\n";
    my $elem = shift;       # SVG Element
    my $ary_ref = shift;    # Werte aus der DB
    my $welcher_graph = shift;  # innen/aussen, puffer1-4, boiler1-4
    my $farb_index = shift;     # Index der zugehörigen Farbe

    my ($points, $x, $y);

# Muster
#$elem->polyline(
#   fill=>"lightgray", stroke=>"red", 'stroke-width'=>"5px",
#    points=>"400 10, 120 10, 200 80, 280 20, 300 20
#            220 100, 300 180, 280 180, 200 120, 120 180, 100 180
#            180 100, 80 10, 10 10, 10 200, 400 200" 
#);

    #print "zeitpunkt => $welcher_graph <br />\n";
    foreach my $p ( @$ary_ref ) {
        #print "$p->{zeitpunkt} => $p->{$welcher_graph} <br />\n";
        ($x, $y) = ($AKT_CONF{x_00} + 30 * $p->{zeitpunkt},
                    $AKT_CONF{y_00} - $AKT_CONF{y_step} * $p->{$welcher_graph});
        if ( length($points) ) {
            $points .= ", $x $y";   # alle Folgepunkte
        } else {
            $points .= "$x $y";     # erster Punkt
        }
    }
    my $farbe = $SVG_FARBEN[$farb_index];
    $elem->polyline(
       fill=>"none", stroke=>"$farbe", points=>"$points" 
    );
    # Beschriftung
    $elem->text(
        #id     => "xtxt$x",
        x      => $x,
        y      => $y,
        stroke =>"$farbe",
        -cdata => "$welcher_graph",
    );

}; # kurve_zeichnen


# ------------------------------------
# SVG Temp.Kurven für die gewünschten Elemente zeichnen
sub temperatur_kurven_zeichnen {
    #print "temperatur_kurven_zeichnen param: @_<br />\n";
    my $elem = shift;       # SVG Element
    my $ary_ref = shift;    # Werte aus der DB
    my @elemente = @_;      # innen/aussen, puffer1-4, boiler1-4

    my ($points, $x0, $y0, $x, $y);

    
    for (my $i=0; $i<@elemente; $i++) { 
        kurve_zeichnen( $elem, $ary_ref, $elemente[$i], $i );
    }

}; # temperatur_kurven_zeichnen


# ------------------------------------
# Hilfsfunktionen
# ------------------------------------

# === MATHLIB ==================================================================

# ermittelt den kleinsten und größten Wert der übergebenen Zahlen-Liste
sub min_max(@) {
    if (@_ == 0) { return ''    ; } # leeres Array
    if (@_ == 1) { return $_[0] ; } # genau 1 Element
    my @tmp = sort { $a <=> $b } @_;    # Liste numerisch sortieren
    return $tmp[0], $tmp[-1];           # erstes/letztes Element zurück liefern
}


# ------------------------------------
# Hilfsfunktionen fuer Entwicklung

# ------------------------------------
sub dump_short {
    my $cgi = shift;

    print "<!-- \n", $stand, "\nParameter:\n";
    foreach my $name ( $cgi->param ) {
        print " $name: ";
        foreach my $value ( $cgi->param( $name ) ) {
            print "$value, ";
        };
        print "\n";
    };
    print "-->\n";

}; # dump_short
