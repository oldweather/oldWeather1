#!/opt/local/bin/perl

# Make transcription images for a voyage

use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;
use FindBin;
use File::Basename;
use lib "$FindBin::Bin/../../Modules";
use Places qw(EstimateLLfromName);
use Getopt::Long;
use Data::Dumper;

my $Ship_name  = undef;
my $ImageCount = 0;
my $LastFile;
GetOptions( "ship=s" => \$Ship_name );
unless ( defined($Ship_name) ) { die "Usage: --ship=<ship.name>"; }

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

# Get the ship record
my $ships = $db->ships->find( { "name" => $Ship_name } )
  or die "No such ship: $Ship_name";
my $Ship = $ships->next;    # Assume there's only one

# Get all the pages (assets) for this voyage
my $assetI = $db->assets->find( { "ship_id" => $Ship->{_id} } );

my @AssetIds;               # Buffer to avoid mongodb timeout
while ( my $Asset = $assetI->next ) {

    if ( $Asset->{done} ) { push @AssetIds, $Asset->{_id}; }

}

foreach my $AssetId (@AssetIds) {

    my $transcriptionsI =
      $db->classifications->find( { "asset_ids" => $AssetId } );

    while ( my $Transcription = $transcriptionsI->next ) {
        foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
            if ( defined( $Annotation->{data}->{category} )
                && $Annotation->{data}->{category} eq 'Place' )
            {
                printf "Place: %s\n", $Annotation->{data}->{category_value};
                print Dumper ((
                    EstimateLLfromName(
                        $Annotation->{data}->{category_value},
                        0, 90, 0, 180
                    )
                )[0]);
            }
            if ( defined( $Annotation->{data}->{port} )
                && $Annotation->{data}->{port} =~ /\w+/ )
            {
                printf "Port: %s\n", $Annotation->{data}->{port};
                print Dumper ((
                    EstimateLLfromName(
                        $Annotation->{data}->{port},
                        0, 90, 0, 180
                    )
                )[0]);
            }
        }
    }
}
