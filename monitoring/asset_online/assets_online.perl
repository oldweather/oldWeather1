#!/opt/local/bin/perl

# Get the date each asset was put online

use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;
use Data::Dumper;

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

my $assetsI = $db->assets->find();

my %Assets;
while ( my $Asset = $assetsI->next ) {

    my $Date = $Asset->{created_at};
    unless ( defined($Date) ) { next; }
    my $Key = sprintf "%04d-%02d-%02d", $Date->{local_c}->{year},
      $Date->{local_c}->{month}, $Date->{local_c}->{day};
    $Assets{ $Asset->{_id} } = $Key;
}

foreach my $Asset ( sort { $Assets{$a} cmp $Assets{$b} } ( keys(%Assets) ) ) {
    printf "%s %10s\n", $Asset, $Assets{$Asset};
}
