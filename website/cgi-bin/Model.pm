package Model;

# API
sub initialize();
sub cleanUp();
sub db_readSensorData($$); # params: startTime, endTime
sub calculatExtremeValues(\@); # params: readingDataArr_ref

# === MODEL ====================================================================
# Saten liegen in einer SQLight Datenbank
use DBI qw(:sql_types); # implizit DBI::SQLite database handle
my $DBH;

my $DATABASE = "../../db/measurements.db";

# Statements
my $DB_READ_SENSORDATA; 

sub initialize(){
    connectDb();
    db_prepareStatements();
}
sub cleanUp(){
    disconnectDb();
}

sub connectDb{
    $DBH = DBI->connect("dbi:SQLite:dbname=$DATABASE", undef, undef, {
      AutoCommit => 1,
      RaiseError => 1,
      sqlite_see_if_its_a_number => 1,
        # let DBD::SQLite to see if the bind values are numbers or not
      sqlite_unicode => 1,	# UTF-8  -! nicht bei WG !-
    });

    # Fremdschlüssel aktivieren
    $DBH->do("PRAGMA foreign_keys = ON");
}

sub disconnectDb{
    my $rc  = $DBH->disconnect;
}

sub db_prepareStatements{
    
    my $stm= 
        "SELECT r.time, m.address, r.reading ".
        "From t_mapping m join t_reading r on m.id=r.mapping_id ".
        "where ? <= r.time and r.time < ? ORDER BY r.time";
    $DB_READ_SENSORDATA = $DBH->prepare($stm);
}
# ------------------------------------
# alle Messwerte des Tages (=ab startzeitpunkt) einlesen
# TIME | ADDRESS | READING
# secFrom1970 | HEX | 10^-2°C
sub db_readSensorData($$){
    my $startTime = shift;
    my $endTime = shift;

    # Messwerte einlesen
    $DB_READ_SENSORDATA->execute($startTime, $endTime);
    my $ary_ref = $DB_READ_SENSORDATA->fetchall_arrayref;

    return $ary_ref;

}; # messwerte_lesen

# aus den Messwerten des Tages (s. messwerte_lesen) die Extremwerte ermitteln
sub calculatExtremeValues(\@) {
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

1;
