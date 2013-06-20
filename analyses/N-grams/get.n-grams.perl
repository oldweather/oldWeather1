#!/opt/local/bin/perl

# Get the 100 most-popular N-grams for each value of N

use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;
use FindBin;
use Data::Dumper;

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

my $transcriptionsI = $db->classifications->find();
my $Count           = 0;
my @NGrams;
TS: while ( my $Transcription = $transcriptionsI->next ) {
    foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
        foreach my $Key ( 'category_value', 'category_final' ) {
            if ( defined( $Annotation->{data}->{$Key} ) ) {
                my $Text = lc( $Annotation->{data}->{$Key} );
                $Text =~ s/\W+/ /g;
                my @Fields = split /\s+/, $Text;
                for ( my $Length = 0 ; $Length < scalar(@Fields) ; $Length++ ) {
                    for (
                        my $Offset = 0 ;
                        $Offset < scalar(@Fields) - $Length ;
                        $Offset++
                      )
                    {
                        my $NG =
                          join( " ", @Fields[ $Offset .. $Offset + $Length ] );
                        $NGrams[$Length]->{$NG}++;
                    }
                }
#                if ( $Count++ > 1000 ) { last TS; }
            }
        }
    }
}

for ( my $Length = 0 ; $Length < scalar(@NGrams) ; $Length++ ) {
    printf "\n\nLength %d:\n\n", $Length + 1;
    my $Count = 0;
    foreach my $NG (
        sort { $NGrams[$Length]->{$b} <=> $NGrams[$Length]->{$a} }
        keys( %{ $NGrams[$Length] } )
      )
    {
        printf "%3d %s\n", $NGrams[$Length]->{$NG}, $NG;
        if ( ++$Count > 100 ) { last; }
    }
}
