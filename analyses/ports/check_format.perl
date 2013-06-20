#!/usr/bin/perl 

use strict;
use warnings;

my $Count = 0;
while (<>) {
    chomp;
    if ( $_ =~ /^(.+)\t\s*([\-\.\d]+)\s+([\-\.\d]+)/ ) {
        my $Name = $1;
        my $Long = $2;
        my $Lat  = $3;
        if ( $Count >= 1646 ) {
            $Long = $3;
            $Lat  = $2;
        }
        $Name =~ s/\s+$//;
        printf "%-25s\t%6.1f\t%6.1f", $Name, $Long, $Lat;
        if($_ =~ /(\#.*)/) { print "  $1"; }
        print "\n";
        $Count++;
    }
    else { die "Bad line $_;"; }
}
