package View;

# === CONTROLLER ===============================================================
# Ablaufsteuerung über CGI
# PROTOTYPES
sub initialize();
sub drawHeaderAndTitle(); 
sub drawBody($$);
sub drawFooter(); 
sub drawPage($$);

use CGI qw(*table);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Pretty qw( :html3 );
my $CGI;

# must be true if the website will be displayed on an Appache
my $AppacheConfig = 1;

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
my %SVG_CONF;
my %AKT_CONF;

# je Diagramm gibt es max. 4 Temperaturwerte
my @SVG_FARBEN = (qw(black green red blue));

sub initialize(){
    init_conf();
    init_cgi();
    init_svg();
}
sub init_conf{
    %SVG_CONF = ( 
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
        y_step       =>   0,    # Skalierung wir gesetzt in drawCoordsystem
                                # die Schrittweite ist abhängig von der Anzahl
                                #    der unterzubringenden Punkte
    );

    %AKT_CONF = %SVG_CONF;
}
sub init_cgi{
    $CGI = CGI->new; 
}
sub init_svg{
    $SVG = SVG->new( width =>$SVG_CONF{max_x}, height => $SVG_CONF{max_y},
            stroke => 'black', 'font-family' => "Courier", );
}


sub drawPage($$){
    # CONTROLLER: CGI Seitenanfang ausgeben
    drawHeaderAndTitle();
    
    drawBody(shift, shift);

    # CGI Seitenende ausgeben
    drawFooter();
} #drawPage

sub drawBody($$){
    my $minmax_ref = shift;
    my $dataRows_ref = shift;

    # VIEW: Koordinatensystem und Kurven erstellen und ausgeben
    drawCoordsystem($SVG, 'Raumtemperatur - Aussentemperatur', $minmax_ref);

    # SVG Temp.Kurven für die gewünschten Elemente zeichnen
    #temperatur_kurven_zeichnen( $SVG, $dataRows_ref, "raum_temp", "aussen_temp" );
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
} # drawBody

# ------------------------------------
# CGI Seitenanfang
sub drawHeaderAndTitle() {
    print $CGI->header if $AppacheConfig; # print additional doctype information for appache

    print 
        $CGI->start_html( 'Heizungssteuerung' ),
        $CGI->h1( {-align=>"CENTER"}, 'Heizungssteuerung' );
    #dump_short($CGI);

    # warnings duerfen erst aktiviert werden, wenn der CGI.header geschrieben ist
    warningsToBrowser(1);   

}; # drawHeaderAndTitle

# ------------------------------------
# CGI Seitenende
sub drawFooter() {
    print 
        '<br/><br/>-- (c) Christian Merz und Daniel Merz 2016 --',
        $CGI->end_html,
        "\n";

}; # drawFooter

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

# SVG Koordinatensystem
sub drawCoordsystem {
    #print "drawCoordsystem param: @_<br />\n";
    my $elem = shift;
    my $titel = shift;
    my $minMax_ref = shift; 

    my @y_min_max = @{$minMax_ref};

    # --------------------
    # Vorbereitung Y-Achse

    # y_min_max auf nächsten Int runden
    @y_min_max = ( int($y_min_max[0])-1, int($y_min_max[1])+1 );
    #print "drawCoordsystem y_min_max: @y_min_max<br />\n";

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
    ($x0,$y0) = ($AKT_CONF{x_00}, $AKT_CONF{y_00} + $y_step);
    for (my $x=$y_min_max[0]; $y0>1.25*$AKT_CONF{offset}; $x++) { 
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
        $y0 -= $y_step;
    }

## add a circle to the group
#$elem->circle( cx => 200, cy => 100, r => 50, id => 'circle_in_group_y', 
#    fill   => 'green' );

}; # drawCoordsystem
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

1;
