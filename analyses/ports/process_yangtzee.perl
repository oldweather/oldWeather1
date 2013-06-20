#!/usr/bin/perl -w

# Convert a port locations file from forum format

use strict;
use warnings;

while (<>) {
    $_ =~ s/^\W+//;
    $_ =~ s/\?//g;
    $_ =~ s/No reference found, //;
    my @Fields = split /\t/, $_;
    unless ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) { next; }
    unless ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) { next; }
    my $Lat = $Fields[3];
    my $Lon = $Fields[4];
    printf "%-20s\t%5.1f\t%6.1f\n", $Fields[0], $Lat, $Lon;
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\w/ ) {
        my @Fields = split /, /, $Fields[1];
        foreach my $Alt (@Fields) {
            $Alt =~ s/^\s+//;
            printf "%-20s\t%5.1f\t%6.1f\n", $Alt, $Lat, $Lon;
        }
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\w/ ) {
            $Fields[2] =~ s/^\s+//;
        printf "%-20s\t%5.1f\t%6.1f\n", $Fields[2], $Lat, $Lon;
    }
}
