#!/opt/local/bin/perl

# There are two typs of page location:
# top and abs_top & left and abs_left
# I don't understand the difference - compare them

use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;
use FindBin;
use File::Basename;
use lib "$FindBin::Bin/../../Modules";
use Asset;
use Getopt::Long;
use Data::Dumper;

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

my $transcriptionsI = $db->classifications->find();
my $Count           = 0;

while ( my $Transcription = $transcriptionsI->next ) {
    foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
	    unless(defined($Annotation->{page_info}->{top})) { next; }
        if ( $Annotation->{page_info}->{top} !=
            $Annotation->{page_info}->{abs_top} )
        {
            printf "%d %d %d %d\n", $Annotation->{page_info}->{top},
              $Annotation->{page_info}->{abs_top},
              $Annotation->{page_info}->{left},
              $Annotation->{page_info}->{abs_left};
        }
     if($Count++>10000) { die; }
    }
}
