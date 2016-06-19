package View;

# === CONTROLLER ===============================================================
# Ablaufsteuerung über CGI
# PROTOTYPES
sub initialize();
sub drawHeaderAndTitle(); 
sub drawBody($$$);
sub drawFooter(); 
sub drawPage($$);

use CGI qw(*table);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Pretty qw( :html3 );
use Graph;
my $CGI;

# must be true if the website will be displayed on an Appache
my $AppacheConfig = 1;

my $graph;

sub initialize(){
    init_cgi();
    $graph = Graph::initGraph();
}
sub init_cgi{
    $CGI = CGI->new; 
}

sub drawPage($$){
    # CONTROLLER: CGI Seitenanfang ausgeben
    drawHeaderAndTitle();
    
    drawBody(shift, shift, shift);

    # CGI Seitenende ausgeben
    drawFooter();
} #drawPage

sub drawBody($$$){
    my $dataRows_ref = shift;
    my $minmaxData = shift;
    my $minmaxTime = shift;
    
    my $title = 'Raumtemperatur - Aussentemperatur';

    # VIEW: Koordinatensystem und Kurven erstellen und ausgeben
    Graph::drawCoordsystem($graph,$title , $minmax_ref, $minmaxTime);

    # SVG Temp.Kurven für die gewünschten Elemente zeichnen
    #Graph::temperatur_kurven_zeichnen( $graph, $dataRows_ref, "raum_temp", "aussen_temp" );
        #my $elem = shift;       # SVG Element
        #my $ary_ref = shift;    # Werte aus der DB
        #my @elemente = @_;      # innen/aussen, puffer1-4, boiler1-4


    Graph::render($graph);
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

1;
