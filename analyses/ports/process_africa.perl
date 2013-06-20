#!/usr/bin/perl -w

# Convert a port locations file from forum format

use strict;
use warnings;

while (<>) {
    chomp;
    $_ =~ s/^\W+//;
    my @Fields = split /\t/, $_;
    my $Alt;
    if ( $Fields[0] =~ /\((.+)\)/ ) {
        $Alt = $1;
        $Fields[0] =~ s/\(.+\)//;
    }
    unless ( $Fields[1] =~ /Lat\s+([\-\.\d]+), Long ([\-\.\d]+)/ ) {
        die "Bad position $Fields[1]";
    }
    my $Lat = $1;
    my $Lon = $2;
    printf "%-20s\t%5.1f\t%6.1f\n", $Fields[0], $Lat, $Lon;
    if ( defined($Alt) ) {
        printf "%-20s\t%5.1f\t%6.1f\n", $Alt, $Lat, $Lon;
    }
}
