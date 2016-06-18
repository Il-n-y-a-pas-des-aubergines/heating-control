package Model;

# API
sub initialize();
sub cleanUp();
sub db_readSensorData($$); # params: startTime, endTime
sub calculatExtremeValues($); # params: readingDataArr_ref

# === MODEL ====================================================================
# Saten liegen in einer SQLight Datenbank
use DBI qw(:sql_types); # implizit DBI::SQLite database handle
my $DBH;

my $DATABASE = "../../db/measurements.db";

# Statements
my $DB_READ_SENSORDATA; # returns the values as: time|address|reading

sub initialize(){
    connectDb();
    db_prepareStatements();
}
sub cleanUp(){
    disconnectDb();
}

sub connectDb{
    die "Database file '$DATABASE' doesn't exist!" unless -f $DATABASE; 

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
# UNIX-TIME | ADDRESS | READING
# secFrom1970 | HEX | 1=10^-2°C
sub db_readSensorData($$){
    my $startTime = shift;
    my $endTime = shift;

    # Messwerte einlesen
    $DB_READ_SENSORDATA->execute($startTime, $endTime);
    my $arr_ref = $DB_READ_SENSORDATA->fetchall_arrayref({});

    return $arr_ref;

}; # messwerte_lesen

# aus den Messwerten des Tages (s. messwerte_lesen) die Extremwerte ermitteln
# Returns ref to arr (minVal, maxVal)
sub calculatExtremeValues($) {
    my $rows_ref = shift;

    my $minVal = 200;
    my $maxVal = -200;

    foreach my $r (@$rows_ref){
        my %row = %$r;
        
        $minVal = $row{'reading'} if ($row{'reading'} < $minVal);
        $maxVal = $row{'reading'} if ($row{'reading'} > $maxVal);
    }

    # ensure at least a range between 0 and 30
    $minVal = 0 if (0 < $minVal);
    $maxVal = 300 if (300 > $maxVal);

    # degree values are in 1/100°C -> return in °C
    my @result = ($minVal/100, $maxVal/100);
    return \@result;

}; # extremwerte_ermitteln

1;
