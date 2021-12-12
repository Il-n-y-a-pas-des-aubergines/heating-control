#!/usr/bin/perl -T

# 03.04.2015, C.A.Merz
# file: sudo cp /home/christian/perl/heizung.cgi /srv/www/cgi-bin/

use lib '/home/daniel/perl5/lib/perl5';
use strict;
use warnings;
use Time::localtime;
use Time::Local;
use lib ".";

use View;
use Model; 
use Lib;

my $startTime;
my $endTime;

sub main(){
    init();

    View::drawHeaderAndTitle();

    # TODO: change next lines, for now ALL data will be get from db
    $startTime = 0;
    $endTime = 9999999999;
    # load data from db
    my $data_ref = Model::db_readSensorData($startTime, $endTime);
    my $minmax_ref = Model::calculatExtremeValues($data_ref);
    my @minmaxTime = [$startTime, $endTime];

    View::drawBody($data_ref, $minmax_ref, \@minmaxTime);

    View::drawFooter();
}
sub init(){
    View::initialize();
    Model::initialize();
    # set timeStamps
    my $now = localtime; 
    $startTime = timelocal(0,0,0,$now->mday, $now->mon, $now->year);
    $endTime = timelocal(59,59,23,$now->mday, $now->mon, $now->year);
}

main();

