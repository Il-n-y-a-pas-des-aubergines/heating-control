#!/usr/bin/perl


use strict;
use warnings;

use IO::Handle;

open ( COM, "/dev/ttyACM0") || die "cannot read serial port: $!";

while (my $txt = <COM>) {
    print($txt);
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



