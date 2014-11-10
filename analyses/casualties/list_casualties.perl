#!/opt/local/bin/perl

# Get all the casualty reports

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


my @Ships;
my $ships = $db->get_collection( 'ships' ) ->find(); 
while ( my $Ship = $ships->next ) { push @Ships,$Ship; }

foreach my $Ship (@Ships) {

  my @Assets;
  my $assetI = $db->get_collection('assets')->find( {"ship_id" => $Ship->{_id}});
  while ( my $Asset = $assetI->next ) { push @Assets,$Asset; }
  
  foreach my $Asset (@Assets) {

     my $transcriptionsI = $db->get_collection('classifications')->find( {"asset_ids" => $Asset->{_id}});
     while ( my $Transcription = $transcriptionsI->next ) {
	 my %Tdata;
	 foreach my $Annotation ( @{ $Transcription->{annotations} } ) {
	     if(defined($Annotation->{kind}) && $Annotation->{kind} eq 'date') {
                 if($Annotation->{data}->{year} !~ /\d/) { $Annotation->{data}->{year}=0; }
                 if($Annotation->{data}->{month} !~ /\d/) { $Annotation->{data}->{month}=0; }
                 if($Annotation->{data}->{day} !~ /\d/) { $Annotation->{data}->{day}=0; }
		 $Tdata{date} = sprintf "%04d-%02d-%02d",$Annotation->{data}->{year},
				    $Annotation->{data}->{month},$Annotation->{data}->{day};
	     }
	     if(defined( $Annotation->{data}->{category} ) &&
			 $Annotation->{data}->{category} eq 'Person' &&
		defined( $Annotation->{data}->{sub_category} ) &&
			 $Annotation->{data}->{sub_category} eq 'Died' ) {
		 $Tdata{casualty} = $Annotation->{data}->{category_value};
	     }
	 }
	 if(defined($Tdata{casualty})) {
	     print "$Tdata{casualty}\t";
	     if(defined($Tdata{date})) {
		 print "$Tdata{date}\t";
	     }
	     else { print "        NA\t"; }
	     print "$Ship->{name}\t";
	     print "$Asset->{location}\n";
	 }
     }
         
  }
  #die;
}
