#!/usr/bin/perl -T

################################################################
# 16.05.2016, D.A.Merz
# TODO: Implement 'filterSensorData()' for sensor data filtering
#
###############################################################

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

# Datasource
my $DATABASE_PATH = "./db/measurements.db";
my $LOG_LEVEL = 2;
my @states = ("Error","Warning","Information","Debug");
# set to one for a db_connection and basic functionality test
my $TEST_MODE = 1; 

main();

sub main{
    if($TEST_MODE){
        test();
        die "test finished!";
    }

    db_initialize();
    open_pipe();
    # Following function will read data from the pipe and insert it into the db
    # will never return!
    readAndInsertData();

}

### Used to test methods of this script
sub test{
    print ">>>>>  Testing....\n";
    # initialize db for logging
    db_initialize();

    # FOR THIS TEST A LOT OF LOGGING MESSAGES IN THE DB WILL BE PRODUCED!
    $LOG_LEVEL = 3;
    #extractAddressAndTemperature("[<aabcd1234bcd1239;+160><aabcd1234bcd1239;+160>]");
    my @result = extractAddressAndTemperature("[<aabcd1234bcd1239;+160><THIS IS FUCKING INVALID><aabcd1234bcd1239;+139>]");
    my @filteredArr = @{filterSensordata(\@result)};
    foreach my $h_ref ( @filteredArr){
        my %h = %{$h_ref};
        print ("Addr: $h{'address'}, Temp: $h{'reading'}\n");
    }
    # AND NOW TEST WITH COMPLETELY INVALID DATA
    @result = extractAddressAndTemperature("[<To be or not to be?>");

    #print @result;
    #db_insertNewMapping("AC2F");
    #db_insertNewData("AC2F", 1300);
}

sub readAndInsertData{
    while (my $txt = <COM>) {
        #print($txt);
        my @sensorData = extractAddressAndTemperature($txt);
        if (@sensorData){
            my @filtered_data = @{filterSensordata(\@sensorData)};
            foreach my $hash_ref  (@sensorData){
                my %s = %{$hash_ref};
                db_insertNewData($s{"address"},$s{"reading"});
            }
        }

    }
}

sub extractAddressAndTemperature{
    my $reading = shift;
    my @result; 
    
    # check if reading mathes [(<...>)*]
    if ($reading =~ /^\[(<[^>]*>)*\]$/){
        $reading = substr($reading,1,length($reading)-2);
        
        my $validDataCounter = 0;
        # for each sensorData which is defined by <...>
        while ($reading =~ /(<[^>]*>)/g){
            my $singleSensorData = $1;

            # check if sensor data is valid (must match <HEX-ADDR;+/-TEMPERATURE>)
            unless ($singleSensorData =~ /<([0-9a-f]{16});([+|-]?\d+)>/i){
                db_log(1,"extractAddressAndTemperature()", "Sensor data not valid: ".$singleSensorData);
                next;
            }

            db_log(3,"extractAddressAndTemperature()","Got valid sensor data: ".$singleSensorData);
            print "Result of RegEx: ".$1." ".$2."\n";
            # build hash with sensor data
            my %hash = (
                address=>$1,
                reading=>$2
            );
            print "Result of RegEx secondTime: ".$1." ".$2."\n";
            # save hash in array
            push(@result, \%hash);
            $validDataCounter++;
        } 

        db_log(2,"extractAddressAndTemperature()","Got valid data from ".$validDataCounter." sensors.")
    }else{
        db_log(0, "extractAddressAndTemperature()", "Reading does not match basic structure!: ".$reading);
    }

    # return the list
    return @result; 
}
# TODO:Still has to be implemented!
sub filterSensordata{
    return shift;
}

sub db_initialize{
    db_connect();
    db_prepareStatements();
}
sub open_pipe{
    open ( COM, "/dev/ttyACM0") || die "cannot read serial port: $!";
}
sub db_connect{
	# DBI::SQLite database handle  
	#my $dbh = DBI->connect("dbi:SQLite:dbname=$DATABASE_PATH","","");
	$DBH = DBI->connect("dbi:SQLite:dbname=$DATABASE_PATH", undef, undef, {
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
    # Insert new Reading 
    my $stm= 
    "INSERT INTO t_reading VALUES (?,?,?,?)";
    $DB_READING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Insert new Mapping
    $stm= 
    "INSERT INTO t_mapping VALUES (?,?,?,?,?)";
    $DB_MAPPING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Insert new Logging 
    $stm = 
    "INSERT INTO t_logging VALUES (?,?,?,?,?)";
    $DB_LOGGING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Select ID, Address from Mapping
    $stm = 
    "SELECT id,address FROM t_mapping WHERE address=? AND valid_to IS NULL";
    $DB_MAPPING_SELECT_ID_STATEMENT = $DBH->prepare($stm);
}
sub db_insertNewData{
    my $address = shift;
    my $addressId; 
    my $time = time();
    my $reading = shift; 

    db_log(3, "InsertReading()","Insert new Reading.");
    $DB_MAPPING_SELECT_ID_STATEMENT->execute($address);
    my $array_ref = $DB_MAPPING_SELECT_ID_STATEMENT->fetchall_arrayref;

    #print "Id first element of first row: $array_ref->[0]->[0]\n";
    #print "Anzahl elemente: $#$array_ref\n";
    #die "Whatever";
    if ($#$array_ref == 0){
        $addressId = $array_ref->[0]->[0];
    } else {
        # address does not yet exist 
        db_log(2,"InsertReading()","Insert new Mapping.");
        db_insertNewMapping($address);
        $DB_MAPPING_SELECT_ID_STATEMENT->execute($address);
        $array_ref = $DB_MAPPING_SELECT_ID_STATEMENT->fetchall_arrayref;

        unless ($#$array_ref == 0){
            die "Insert of new Mapping failed!";
        }

        $addressId = $array_ref->[0]->[0];
    }

    $DB_READING_INSERT_STATEMENT->execute(undef, $addressId, $time, $reading); 
}
sub db_insertNewMapping{
    my $address = shift; 
    my $name = "<Sensor noch nicht zugeordnet>";
    my $valid_from = time();

    $DB_MAPPING_INSERT_STATEMENT->execute(undef, $address, $name, $valid_from, undef );
}
sub db_log{
    my $timestamp = time();
    my $log_level = shift; 
    my $module = shift;
    my $msg = shift;

    if ($log_level > $LOG_LEVEL){
        return;
    }

    $module = "Read_Serial.".$module;
    my $state = $states[$log_level];

    $DB_LOGGING_INSERT_STATEMENT->execute(undef, $timestamp, $module, $state, $msg); 
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



