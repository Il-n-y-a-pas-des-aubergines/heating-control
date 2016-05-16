#!/usr/bin/perl -T

# 16.05.2016, D.A.Merz

use strict;
use warnings;

use IO::Handle;
#use Time::localtime;

### DATABASE Connection
# use DBI - DatabaseInterface;
use DBI qw(:sql_types); # implizit DBD::SQLite database handle
# Database Handle 
my $DBH;

# prepared DB statement
my $DB_INSERT_STATEMENT;
my $DB_READING_INSERT_STATEMENT;
my $DB_MAPPING_INSERT_STATEMENT;
my $DB_LOGGING_INSERT_STATEMENT;
my $DB_MAPPING_SELECT_ID_STATEMENT; 

main();

sub main{
    # readAndInsertData();
    db_connect();
    db_prepareStatements();
    db_insertNewMapping("hallo");
}

sub readAndInsertData{
    while (my $txt = <COM>) {
        print($txt);
    }
}
sub intialize{
    db_connect();
    db_prepareStatements();
    open_pipe();
}
sub open_pipe{
    open ( COM, "/dev/ttyACM0") || die "cannot read serial port: $!";
}
sub db_connect{
	# Datasource
	my $DATABASE = "./db/measurements.db";
	# DBI::SQLite database handle  
	#my $dbh = DBI->connect("dbi:SQLite:dbname=$DATABASE","","");
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
sub db_prepareStatements{
    my $stm= 
    "INSERT INTO t_reading VALUES (?,?,?,?)";
    $DB_READING_INSERT_STATEMENT = $DBH->prepare($stm);

    $stm= 
    "INSERT INTO t_mapping VALUES (?,?,?,?,?)";
    $DB_MAPPING_INSERT_STATEMENT = $DBH->prepare($stm);

    $stm = 
    "INSERT INTO t_logging VALUES (?,?,?,?)";
    $DB_LOGGING_INSERT_STATEMENT = $DBH->prepare($stm);

    $stm = 
    "SELECT id FROM t_mapping WHERE address=?";
    $DB_MAPPING_SELECT_ID_STATEMENT = $DBH->prepare($stm);
    
}
sub db_insertData{
    my $address = shift;
    my $reading = shift; 
    my $time = time();

    #$DB_MAPPING_INSERT_STATEMENT 
    #$DB_MAPPING_SELECT_ID_STATEMENT 
}
sub db_insertNewMapping{
    my $address = shift; 
    my $name = "<Sensor noch nicht zugeordnet>";
    my $valid_from = time();

    $DB_MAPPING_INSERT_STATEMENT->execute(undef, $address, $name, $valid_from, undef );
}

__END__


while (<COM>) {
    print($_);
}



__END__

#        open(my $fh, "<", "input.txt") 
#    	or die "cannot open < input.txt: $!";


#christian@linux-qo6d:~/Projekte/dir_ba_abr> cat /dev/ttyACM0


#christian@linux-qo6d:~/Projekte/dir_ba_abr> file /dev/ttyACM0
#/dev/ttyACM0: character special

# Message Qeue oder Pipeline oder einfache datei ?

# MODE is |- , the filename is interpreted as a command to which output is to be piped, 
# and if MODE is -| , the filename is interpreted as a command that pipes output to us. 

    open(ARTICLE, "-|", "caesar <$article")  # decrypt article
        or die "Can't start caesar: $!";



