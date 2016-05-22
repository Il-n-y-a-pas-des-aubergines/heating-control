package Lib;

use Time::localtime;
my $TM;
# aktueller Zeitpunkt
$TM = localtime;
my $stand = sprintf "Stand vom: %02d.%02d.%04d", 
                $TM->mday, ($TM->mon)+1, ($TM->year)+1900;

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

1;
