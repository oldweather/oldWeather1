#!/opt/local/bin/perl

# Basic tests for the ports module

use strict;
use warnings;
use lib "../../Modules";
use Places qw(EstimateLLfromName);
use Data::Dumper;

my @Res = EstimateLLfromName( 'albert', -40, 1000, 0, 1000 );
print Dumper @Res;

