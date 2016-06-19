package Graph;

# SVG zur Präsentation
#use SVG;
use SVG (-indent => "  ",   # 2 Blank statt TAB zum Einrücken verwenden
-nocredits  => 1,    # enable/disable credit note comment
-namespace  => '',   # The root element's (and it's children's) namespace prefix
                     # ! wenn nicht '', werden "inline" Grafiken nicht
                     #   ausgegeben !
);

# je Diagramm gibt es max. 4 Temperaturwerte
my @SVG_FARBEN = (qw(black green red blue));

# initializes configuration and SVG. Returns the Graph object as reference
sub initGraph{
    my %graph;
    init_conf(\%graph);
    init_svg(\%graph);
    return \%graph;
}

sub init_conf($){
    my $graph_ref = shift;

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
    #$graph_ref->{default} = \%SVG_CONF;
    #$graph_ref->{current} = \%SVG_CONF;
    $graph_ref->{conf} = \%SVG_CONF;

}

sub init_svg($){
    my $graph_ref = shift;

    $SVG = SVG->new( width =>$SVG_CONF{max_x}, height => $SVG_CONF{max_y},
            stroke => 'black', 'font-family' => "Courier", );

    $graph_ref->{svg} = $SVG;
}

# SVG Koordinatensystem
sub drawCoordsystem{
    #print "drawCoordsystem param: @_<br />\n";
    my $graph = shift;
    my $title = shift;
    my $minMaxData_ref = shift;
    my $minMaxTime_ref = shift; 

    #print "Min Max is : ";
    #print "@y_min_max";
    #print "\n";
    
    drawXaxis($graph);
    drawYaxis($graph, $minMaxData_ref, $title);
    # --------------------
    
# mein Koordinatensstem:
# die Y-Achse geht immer von (0,0) bis (0,max_y-offset)
# die X-Achse geht per default von (0,0) bis (0,max_x-offset)
# für negative Y-Werte wird die X-Achse "nach oben" geschoben
# Feature: "Stauchung der Y-Achse von 0 bis min(y-werte)
    
# Transformationen
# transform="rotate(45 50 50)" # um 45° drehen um den Punkt (50,50)
# transform="translate(30)"    # in x-Richtung 30 Punkte verschieben
# transform="translate(30,40)" # in Richtung x=30, y=40 Punkte verschieben
# transform="translate(30) rotate(45 50 50)" # erst drehen, dann verschieben

}; # drawCoordsystem

sub drawXaxis($$){
    my $graph = shift; 
    my $minmaxTime = shift;
    
    my $AKT_CONF = $graph->{conf};
    my $svg = $graph->{svg};
    # --------------------
    # die X-Achse geht von
    #   SVG(x_00, y_00) -> (max_x-offset, y_00)
    $svg->line(
        id => 'x_achse',
        x1 =>  $AKT_CONF->{x_00},
        y1 =>  $AKT_CONF->{y_00},
        x2 =>  $AKT_CONF->{max_x}-$AKT_CONF->{offset},
        y2 =>  $AKT_CONF->{y_00},
    );
    $svg->text(
        id          => 'x_text',
        'font-size' => "20",
        x           => $AKT_CONF->{max_x}-$AKT_CONF->{offset}-40,
        y           => $AKT_CONF->{y_00}-6,
        -cdata      => 'Zeit',
    );
    
    # --------------------
    # Bemaßung X-Achse
     my $x_bemassung = $svg->group(
        id            => 'x_bemassung',
        'font-size'   => "10",
    );
     
    my $x0;
    for (my $x=1; $x<=24; $x++) { 
        ($x0,$y0) = ($AKT_CONF->{x_00}+30*$x, $AKT_CONF->{y_00});
        # Striche senkrecht zur Achse
        $x_bemassung->line(
            id => "x$x",
            x1 =>  $x0,
            y1 =>  $y0-5,
            x2 =>  $x0,
            y2 =>  $y0+5,
        );
        # Beschriftung
        $x_bemassung->text(
            id     => "xtxt$x",
            x      => $x0,
            y      => $y0,
            transform => "translate(-5,15) rotate(45 $x0 $y0)",
            -cdata => "$x",
        );
    }
}

sub getTimestep{
    my $startTime = shift;
    my $endTime = shift; 
    my $timeInterval = $endTime - $startTime;
    
    my $minute = 60;
    my $hour = $minute * 60;
    my $day = 24 * $hour;
    my $month = 30 * $day;
    my $year = 12 * $month;
    return  ($timeInterval <  2 * $hour)   ?  5 * $minute : 
            ($timeInterval <  4 * $hour)   ? 10 * $minute :
            ($timeInterval < 13 * $hour)   ? 30 * $minute : 
            ($timeInterval <  1 * $day )   ?  1 * $hour : 
            ($timeInterval <  6 * $day )   ?  5 * $hour : 
            ($timeInterval < 10 * $day )   ? 10 * $hour : 
            ($timeInterval <  1 * $month ) ?  1 * $day :  
            ($timeInterval <  5 * $month ) ?  5 * $day : 
            ($timeInterval < 10 * $month ) ? 10 * $day : 
            ($timeInterval < 30 * $month ) ?  1 * $month : 
            ($timeInterval <150 * $month ) ?  5 * $month : 
                                              1 * $year;
}

sub drawYaxis{
    my $graph = shift;
    my $minMaxData_ref = shift;
    my $title = shift;
    
    my $AKT_CONF = $graph->{conf};
    my $svg = $graph->{svg};
    my @y_min_max = @{$minMaxData_ref};

    # y_min_max auf nächsten Int runden
    @y_min_max = ( int($y_min_max[0]), int($y_min_max[1]) );
    #print "drawCoordsystem y_min_max: @y_min_max<br />\n";

    # so viele Punkte müssen auf der y-Achse untergebracht werden:
    my $y_anz_punkte = $y_min_max[1] - $y_min_max[0] +1;

    # die Schrittweite ist abhängig von der Anzahl der unterzubringenden Punkte
    my $deltaY_data =   ( $y_anz_punkte >= 40 ) ? 5 :
                        ( $y_anz_punkte >= 20 ) ? 2 :
                                                  1 ;
    
    my $y_step =  ( $AKT_CONF->{max_y} - (2*$AKT_CONF->{offset})) / 22;
                #( $y_anz_punkte <= 16 ) ? 30 :
                # ( $y_anz_punkte <= 32 ) ? 15 :
                # ( $y_anz_punkte <= 64 ) ?  7 :
                #                            3 ;
    
    $AKT_CONF->{y_step} = $y_step;
 
    # bei negativen y-Werten muss die X-Achse nach oben verschoben werden
    if ( $y_min_max[0] < 0 ) { 
        $AKT_CONF->{y_00} = $AKT_CONF->{y_00_default} + $y_step*($y_min_max[0]/$deltaY_data);
    } else { 
        $AKT_CONF->{y_00} = $AKT_CONF->{y_00_default};
    }
    
    # --------------------
    # die Y-Achse geht von 
    #   SVG(x_00, y_00) -> SVG(x_00, offset)
    # ! y_00_default statt y_00 !
    $svg->line(
        id => 'y_achse',
        x1 =>  $AKT_CONF->{x_00},
        y1 =>  $AKT_CONF->{y_00_default},
        x2 =>  $AKT_CONF->{x_00},
        y2 =>  $AKT_CONF->{offset},
    );
    $svg->text(
        id     => 'y_text',
        'font-size' => "20",
        x      => $AKT_CONF->{x_00},
        y      => $AKT_CONF->{offset},
        -cdata => "Temperatur: $title",
    );

    
    # --------------------
    # Bemaßung Y-Achse
    my $y_bemassung = $svg->group(
        id            => 'y_bemassung',
        'font-size'   => "10",
    );
    
    my $x0 = $AKT_CONF->{x_00};
    # calculate last point at the bottom
    my $amountOfSteps = 
        int(($AKT_CONF->{y_00} - $AKT_CONF->{y_00_default}) / $y_step);
    my $y_value = $deltaY_data * $amountOfSteps;
    # calculate position of last point
    $y0 = $AKT_CONF->{y_00} - ($y_step * $amountOfSteps);
    while ($y0>1.25*$AKT_CONF->{offset}) { 
        # Striche senkrecht zur Achse
        $y_bemassung->line(
            id => "y$y_value",
            x1 =>  $x0-5,
            y1 =>  $y0,
            x2 =>  $x0+5,
            y2 =>  $y0,
        );
        # Beschriftung
        $y_bemassung->text(
            id     => "ytxt$y_value",
            x      => $x0-25,
            y      => $y0+5,
            -cdata => "$y_value",
        );
        $y0 -= $y_step;
        $y_value += $deltaY_data;
    }
}

# SVG eine Temp.Kurve zeichnen
sub kurve_zeichnen {
    #print "kurve_zeichnen <br />\n";
    my $graph = shift;       # SVG Element
    my $ary_ref = shift;    # Werte aus der DB
    my $welcher_graph = shift;  # innen/aussen, puffer1-4, boiler1-4
    my $farb_index = shift;     # Index der zugehörigen Farbe

    my ($points, $x, $y);
    my $svg = $graph->{svg};
    my $AKT_CONF = $graph->{conf};

# Muster
#$svg->polyline(
#   fill=>"lightgray", stroke=>"red", 'stroke-width'=>"5px",
#    points=>"400 10, 120 10, 200 80, 280 20, 300 20
#            220 100, 300 180, 280 180, 200 120, 120 180, 100 180
#            180 100, 80 10, 10 10, 10 200, 400 200" 
#);

    #print "zeitpunkt => $welcher_graph <br />\n";
    foreach my $p ( @$ary_ref ) {
        #print "$p->{zeitpunkt} => $p->{$welcher_graph} <br />\n";
        ($x, $y) = ($AKT_CONF->{x_00} + 30 * $p->{zeitpunkt},
                    $AKT_CONF->{y_00} - $AKT_CONF->{y_step} * $p->{$welcher_graph});
        if ( length($points) ) {
            $points .= ", $x $y";   # alle Folgepunkte
        } else {
            $points .= "$x $y";     # erster Punkt
        }
    }
    my $farbe = $SVG_FARBEN[$farb_index];
    $svg->polyline(
       fill=>"none", stroke=>"$farbe", points=>"$points" 
    );
    # Beschriftung
    $svg->text(
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
    my $graph_ref = shift;       # SVG Element
    my $ary_ref = shift;    # Werte aus der DB
    my @elemente = @_;      # innen/aussen, puffer1-4, boiler1-4

    my ($points, $x0, $y0, $x, $y);

    
    for (my $i=0; $i<@elemente; $i++) { 
        kurve_zeichnen( $graph_ref->{svg}, $ary_ref, $elemente[$i], $i );
    }

}; # temperatur_kurven_zeichnen

sub render($){
    my $graph_ref = shift;
    print $graph_ref->{svg}->to_xml( # (alias: to_xml render serialise serialize)
    #print $SVG->xmlify(
        -inline   => 1,
        #-namespace => "", 
            # ! "", sonst wird NICHTS angezeigt ! default ""
            # xmlify überschreibt alle mit NEW angelegten namespaces
        #-pubid => "-//W3C//DTD SVG 1.0//EN",   # optional/default
    );
} 

1;
