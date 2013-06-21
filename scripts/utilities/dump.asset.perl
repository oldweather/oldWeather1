#!/opt/local/bin/perl

# Dump a selected asset

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

my $Id = undef;
GetOptions( "id=s" => \$Id );
unless ( defined($Id) ) { die "Usage: dump.asset.prl --id=<oid>"; }

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW1 database not found";

my $Asset = asset_read( MongoDB::OID->new( value => $Id ), $db );
print Dumper $Asset;
open( DOUT, ">tst.js" ) or die "Can't open JS file";
print DOUT $Asset->to_JSON();
close(DOUT);

