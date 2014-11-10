#!/opt/local/bin/perl

# Get all the event types

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

my %Categories;
my %SubCategories;
my $transcriptionsI = $db->get_collection('classifications')->find();

while ( my $Transcription = $transcriptionsI->next ) {
    foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
        unless ( defined( $Annotation->{data}->{category} ) ) { next; }
        if (
            defined( $Categories{ $Annotation->{data}->{category} } )
            && (
                !defined( $Annotation->{data}->{sub_category} )
                || defined(
                    $SubCategories{ $Annotation->{data}->{sub_category} }
                )
            )
          )
        {
            next;
        }
        print Dumper $Annotation->{data};
        $Categories{ $Annotation->{data}->{category} } = 1;
        if ( defined( $Annotation->{data}->{sub_category} ) ) {
            $SubCategories{ $Annotation->{data}->{sub_category} } = 1;
        }
    }
}
