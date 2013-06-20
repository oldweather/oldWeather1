#!/usr/bin/perl -w

# Convert a port locations file from forum format

use strict;
use warnings;

my %Positions;
my %Alternates;
my %Notes;
my %Places;
while (<>) {
    chomp;
    unless ( $_ =~ /\w/ ) { next; }
    my @Fields = split /\t/, $_;
    $Places{ $Fields[0] } = 1;
    if ( $Fields[1] =~ /(.+)\/(.+)/ ) {
        $Positions{ $Fields[0] } = [ $1, $2 ];
    }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\w/ ) {
        if ( $Fields[3] =~ /See (.+)/ ) {
            $Alternates{ $Fields[0] } = $1;
        }
        else { $Notes{ $Fields[0] } = $Fields[3]; }
    }
}

foreach ( sort( keys(%Places) ) ) {
    printf "%-20s\t", $_;
    if ( defined( $Alternates{$_} ) ) {
        unless ( defined( $Positions{ $Alternates{$_} } ) ) {
            die "No alt for $Alternates{$_}";
        }
        printf "%5.1f\t%6.1f", @{ $Positions{ $Alternates{$_} } };
    }
    else {
        unless ( defined( $Positions{$_} ) ) {
            die "No positions for $_";
        }
        printf "%5.1f\t%6.1f", @{ $Positions{$_} };
    }
    if ( defined( $Notes{$_} ) ) {
        print "   # $Notes{$_}";
    }
    print "\n";
}
