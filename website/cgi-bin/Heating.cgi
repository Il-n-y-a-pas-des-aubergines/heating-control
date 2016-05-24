#!/usr/bin/perl -T

# 03.04.2015, C.A.Merz
# file: sudo cp /home/christian/perl/heizung.cgi /srv/www/cgi-bin/

use strict;
use warnings;
use lib ".";

use View;
use Model; 
use Lib;

View::initialize();
Model::initialize();

View::drawHeaderAndTitle();

# load data from db and create body with SVG

View::drawFooter();
