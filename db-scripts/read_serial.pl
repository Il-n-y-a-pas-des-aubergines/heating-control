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

my $LOG_LEVEL = 2;
my @states = ("Error","Warning","Information","Debug");
# set to one for a db_connection and basic functionality test
# 0=none, 1=TEST
my $TEST_MODE = 0; 

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
my $DATABASE_PATH = "../db/measurements.db";

main();

sub main{
    if($TEST_MODE){
        test();
        die "test finished!";
    }

    db_initialize();
    open_pipe();
    # skip leading trash data till Init String is found
    skipDataTillInitMessage();
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
    my $valid_reading = "[<aabcd1234bcd1239;+160><YOU CANNOT IMAGINE HOW INVALID THIS DATA IS><aabcd1234bcd1239;+139>]";
    my $invalid_reading = "[<To be or not to be?>";

    print ">>> Test extractAddressAndTemperature()\n";
    my @result = extractAddressAndTemperature($valid_reading);
    my @filteredArr = filterSensordata(\@result);
    foreach my $h_ref ( @filteredArr){
        print ">>>>>> Got one reading...\n";
        my %h = %{$h_ref};
        print (">>>>>> Addr: $h{'address'}, Temp: $h{'reading'}\n");
        print ">>>>>> Insert data into db...\n";
        db_insertNewData ($h{'address'}, $h{'reading'});
        print "\n";
    }
    # AND NOW TEST WITH COMPLETELY INVALID DATA
    @result = extractAddressAndTemperature($invalid_reading);
    if (@result){
        print "hm, there should be no valid data...\n";
    }


    #print @result;
    #db_insertNewMapping("AC2F");
    #db_insertNewData("AC2F", 1300);
}

sub skipDataTillInitMessage{
    while (1) {
        while (my $txt = <COM>) {
            print($txt."\n");
            return if $txt =~ /\[InitArduino\]/;
        }
        print "Init: warte 1 sec...\n";
        sleep 1;
    }
}

sub readAndInsertData{
    while (1) {
        while (my $txt = <COM>) {
            print($txt);
            my @sensorData = extractAddressAndTemperature($txt);
            if (@sensorData){
                my @filtered_data = filterSensordata(\@sensorData);
                foreach my $hash_ref  (@filtered_data){
                    my %s = %{$hash_ref};
                    db_insertNewData($s{'address'},$s{'reading'});
                }
                #print "eine Zeile verarbeitet\n";
            }
    
        }
        print "warte 1 sec...\n";
        sleep 1;
    }
    print "Ende von readAndInsertData\n";
}

sub extractAddressAndTemperature{
    my $reading = shift;
    chomp $reading;
    my @result; 
    
    # check if reading mathes [(<...>)*]
    if ($reading =~ /^\s*\[(<[^<>]+>)*\]\s*$/){
        $reading = substr($reading,1,length($reading)-2);
        
        my $validDataCounter = 0;
        # for each sensorData which is defined by <...>
        while ($reading =~ /(<[^<>]+>)/g){
            my $singleSensorData = $1;

            # check if sensor data is valid (must match <HEX-ADDR;+/-TEMPERATURE>)
            unless ($singleSensorData =~ /<([0-9a-f]{16});([+|-]?\d+)>/i){
                db_log(1,"extractAddressAndTemperature()", "Structure of sensorData not valid: ".$singleSensorData);
                next;
            }

            db_log(3,"extractAddressAndTemperature()","Got sensor data with valid structure: ".$singleSensorData);
            
            # build hash with sensor data
            my %hash = (
                address=>$1,
                reading=>$2
            );
           
            # save hash in array
            push(@result, \%hash);
            $validDataCounter++;
        } 

        db_log(3,"extractAddressAndTemperature()","Got data with valid structure from ".$validDataCounter." sensors.")
    }else{
        db_log(0, "extractAddressAndTemperature()", "Reading does not match basic structure!: ".$reading);
    }

    # return the list
    return @result; 
}
# TODO : Still has to be implemented!
sub filterSensordata{
    my $sensorData = shift;

    my @result;
    foreach my $data (@$sensorData){
        my %h = %{$data};

        unless (filterSingleSensordata(\%h)){
            # sensor data seems not to be valid...
            db_log(2,"filterSensordata()","Sensordata with invalid values have been ignored: ",%h);
            next;
        }
        
        push (@result, \%h);
    }
    
    return @result;
}
sub filterSingleSensordata{
    return 1;
}

sub db_initialize{
    db_connect();
    db_prepareStatements();
    db_log(2, "db_initialize()","Successfully connected to Database!");
}
sub open_pipe{
    open ( COM, "/dev/ttyACM0") || die "cannot read serial port: $!";
    db_log(2, "db_initialize()","Successfully opened serial pipe!");
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
    "INSERT INTO t_reading (id,mapping_id,time,reading) VALUES (?,?,?,?)";
    $DB_READING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Insert new Mapping
    $stm= 
    "INSERT INTO t_mapping (id,address,name,usage_from,usage_till) VALUES (?,?,?,?,?)";
    $DB_MAPPING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Insert new Logging 
    $stm = 
    "INSERT INTO t_logging (id,timestamp,state,module,message) VALUES (?,?,?,?,?)";
    $DB_LOGGING_INSERT_STATEMENT = $DBH->prepare($stm);
    # Select ID, Address from Mapping
    $stm = 
    "SELECT id,address FROM t_mapping WHERE address=? AND usage_till IS NULL";
    $DB_MAPPING_SELECT_ID_STATEMENT = $DBH->prepare($stm);
}
sub db_insertNewData{
    my $address = shift;
    my $addressId; 
    my $time = time();
    my $reading = shift; 

    db_log(3, "InsertReading()","Insert new Reading. Address: ".$address." Reading: ".$reading);
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
            db_log(0,"InserReading()","Failed to insert a new Mapping");
            return;
        }

        $addressId = $array_ref->[0]->[0];
    }

    my $id = undef;
    $DB_READING_INSERT_STATEMENT->execute($id, $addressId, $time, $reading); 
}
sub db_insertNewMapping{
    my $id = undef;
    my $address = shift; 
    my $name = "<Sensor noch nicht zugeordnet>";
    my $usage_from = time();
    my $usage_till = undef;

    $DB_MAPPING_INSERT_STATEMENT->execute($id, $address, $name, $usage_from, $usage_till );
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

    $DB_LOGGING_INSERT_STATEMENT->execute(undef, $timestamp, $state, $module, $msg); 
}


__END__


#christian@linux-qo6d:~/Projekte/dir_ba_abr> cat /dev/ttyACM0

#christian@linux-qo6d:~/Projekte/dir_ba_abr> file /dev/ttyACM0
#/dev/ttyACM0: character special

