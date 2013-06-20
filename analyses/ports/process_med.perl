#!/usr/bin/perl -w

# Convert a port locations file from forum format

use strict;
use warnings;

while (<>) {
    chomp;
    $_ =~ s/^\W+//;
    my @Fields = split /[\:\;]/, $_;
    unless ( $Fields[2] =~ /Lat\s+([\-\.\d]+),* Long +([\-\.\d]+)/ ) {
        die "Bad position $Fields[2]";
    }
    my $Lat = $1;
    my $Lon = $2;
    my @Names;
    $Fields[0] =~ s/\s+\[.+//;
    if ( $Fields[0] =~ /(.+), (.+)/ ) { $Fields[0] =  "$2"." "." $1"; }
    $Fields[0] =~ s/\s\s+/ /g;
    push @Names, $Fields[0];
    if ( $Fields[1] =~ /\w/ ) {
        my @F2 = split /,/, $Fields[1];
        push @Names, @F2;
    }
    foreach (@Names) {
        $_ =~ s/^\s+//;
        printf "%-20s\t%5.1f\t%6.1f\n", $_, $Lat, $Lon;
    }
}
