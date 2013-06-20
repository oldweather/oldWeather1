#!/opt/local/bin/perl

# Count the number of pages transcribed each day

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

my $transcriptionsI = $db->classifications->find();

my %Days;
while ( my $Transcription = $transcriptionsI->next ) {

    my $Date = $Transcription->{annotations}->[0]->{created_at};
    unless ( defined($Date) ) { next; }
    my $Key = sprintf "%04d-%02d-%02d", $Date->{local_c}->{year},
      $Date->{local_c}->{month}, $Date->{local_c}->{day};
    $Days{$Key}++;
}

foreach my $Day ( sort( keys(%Days) ) ) {
    printf "%s %d\n", $Day, $Days{$Day};
}
