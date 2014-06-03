#!/opt/local/bin/perl

# Make basic ship history for a given voyage

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
use Scalar::Util qw(looks_like_number);

my $Ship_name  = undef;
my $Id         = undef;    # If selected, only do this page
my $Only       = undef;    # If selected, only show this transcription
my $ImageCount = 0;
my $LastFile;
GetOptions(
    "ship=s"   => \$Ship_name,
    "id=s"     => \$Id,
    "only=i"   => \$Only
);
unless ( defined($Ship_name) ) { die "Usage: --ship=<ship.name>"; }

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

my @AssetIds;    # Assets to process

# Make the output directories
my $Ship_dir = $Ship_name;
$Ship_dir =~ s/\s+/_/g;
$Ship_dir =~ s/[\(\)]//g;
my $Dir = sprintf( "%s/../../asset_files/%s/",
    $FindBin::Bin, $Ship_dir );
unless ( -d $Dir ) {
    system("mkdir -p $Dir");
}

#Default hemisphere flags
my $nS = 1;    # North
my $eW = 1;    # East

if ( !defined($Id) ) {

    # Get the ship record
    my $ships = $db->get_collection( 'ships' ) ->find( { "name" => $Ship_name } )
      or die "No such ship: $Ship_name";
    my $Ship = $ships->next;    # Assume there's only one

    # Get all the pages (assets) for this ship
    my $assetI = $db->get_collection( 'assets' )->find( { "ship_id" => $Ship->{_id} } );

    while ( my $Asset = $assetI->next ) {

        #if($Asset->{done}) { push @AssetIds, $Asset->{_id}; }
        push @AssetIds, $Asset->{_id};

    }
}
else {    # only one id - for debugging
    push @AssetIds, MongoDB::OID->new( value => $Id );
}

foreach my $AssetId (@AssetIds) {

    my $Asset = asset_read( $AssetId, $db );

    print "\n$Asset->{_id}: ";
    print "($Asset->{location})\n";

    if ( defined( $Asset->{CDate}->{data}->{date} ) ) {
        printf "\nDate: %s\n", $Asset->{CDate}->{data}->{date};
    }


    if ( defined( $Asset->{CPosition} ) ) {
        print "Position: ";
        my $LonSource = "";
        foreach my $v ( 'lng', 'raw_lng', 'portlon' ) {
            if ( defined( $Asset->{CPosition}->{data}->{$v} )
                && length( $Asset->{CPosition}->{data}->{$v} ) > 2 )
            {
                $LonSource = $v;
                last;
            }
        }
        my $LatSource = "";
        foreach my $v ( 'lat', 'raw_lat', 'portlat' ) {
            if ( defined( $Asset->{CPosition}->{data}->{$v} )
                && length( $Asset->{CPosition}->{data}->{$v} ) > 2 )
            {
                $LatSource = $v;
                last;
            }
        }
        if ( defined( $Asset->{CPosition}->{data}->{portlat} )
            && looks_like_number($Asset->{CPosition}->{data}->{portlat})
            && $Asset->{CPosition}->{data}->{portlat} < 0 )
        {
            $nS = -1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lat} )
            && lc( $Asset->{CPosition}->{data}->{raw_lat} ) =~ /s/ )
        {
            $nS = -1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lat} )
            && lc( $Asset->{CPosition}->{data}->{raw_lat} ) =~ /n/ )
        {
            $nS = 1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lat} )
            && $Asset->{CPosition}->{data}->{raw_lat} =~
            /\D*(\d+)\D*(\d+)\D*(\d*)/ )
        {
            #print "L1: $Asset->{CPosition}->{data}->{raw_lat}  ";
            $Asset->{CPosition}->{data}->{raw_lat} = $1 + $2 / 60;
            if ( defined($3) && length($3) > 0 ) {
                $Asset->{CPosition}->{data}->{raw_lat} += $3 / 360;
            }
            $Asset->{CPosition}->{data}->{raw_lat} *= $nS;
            if(looks_like_number($Asset->{CPosition}->{data}->{raw_lat})) {
                 $Asset->{CPosition}->{data}->{raw_lat} = sprintf "%6.2f",
                             $Asset->{CPosition}->{data}->{raw_lat};
            }
            #print "$Asset->{CPosition}->{data}->{raw_lat}\n";
        }
        if ( defined( $Asset->{CPosition}->{data}->{portlon} )
            && looks_like_number($Asset->{CPosition}->{data}->{portlon})
            && $Asset->{CPosition}->{data}->{portlon} < 0 )
        {
            $eW = -1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lng} )
            && lc( $Asset->{CPosition}->{data}->{raw_lng} ) =~ /w/ )
        {
            $eW = -1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lng} )
            && lc( $Asset->{CPosition}->{data}->{raw_lng} ) =~ /e/ )
        {
            $eW = 1;
        }
        if ( defined( $Asset->{CPosition}->{data}->{raw_lng} )
            && $Asset->{CPosition}->{data}->{raw_lng} =~
            /\D*(\d+)\D*(\d+)\D*(\d*)/ )
        {
            #print "L2: $Asset->{CPosition}->{data}->{raw_lng}  ";
            $Asset->{CPosition}->{data}->{raw_lng} = $1 + $2 / 60;
            if ( defined($3) && length($3) > 0 ) {
                $Asset->{CPosition}->{data}->{raw_lng} += $3 / 360;
            }
            $Asset->{CPosition}->{data}->{raw_lng} *= $eW;
            if(looks_like_number($Asset->{CPosition}->{data}->{raw_lng})) { 
               $Asset->{CPosition}->{data}->{raw_lng} = sprintf "%7.2f",
                     $Asset->{CPosition}->{data}->{raw_lng};
            }
            #print "$Asset->{CPosition}->{data}->{raw_lng}\n";
        }
        foreach my $v ( $LatSource, $LonSource, 'port' ) {
            if ( defined( $Asset->{CPosition}->{data}->{$v} )
                && length( $Asset->{CPosition}->{data}->{$v} ) > 2 )
            {
                printf "%s ", $Asset->{CPosition}->{data}->{$v};
            }
        }
        print "\n";
    }

    foreach my $Transcription ( @{ $Asset->{transcriptions} } ) {
        foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
            if ( !defined( $Annotation->{data}->{category} ) ) {
                next;
            }
            if ( defined( $Annotation->{data}->{sub_category} ) ) {
                printf "%s - ", $Annotation->{data}->{sub_category};
            }
            if ( defined( $Annotation->{data}->{category_value} ) ) {
                printf "%s\n",
                  $Annotation->{data}->{category_value};
            }
            if ( defined( $Annotation->{data}->{category_final} ) ) {
                printf "%s\n",
                  $Annotation->{data}->{category_final};
            }
	}    
    }
}
