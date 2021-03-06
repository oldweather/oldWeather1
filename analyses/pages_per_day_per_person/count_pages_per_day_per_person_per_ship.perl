#!/opt/local/bin/perl

# Count the number of pages transcribed each day by each participant
# split the counts by ship.

use strict;
use warnings;
use MongoDB;
use MongoDB::OID;
use boolean;

# Open the database connection (default port, default server)
my $conn = MongoDB::Connection->new( query_timeout => -1 )
  or die "No database connection";

# Connect to the OldWeather1 database
my $db = $conn->get_database('oldWeather-production')
  or die "OW database not found";

# Get the ship record
my $ships = $db->get_collection('ships')->find();
my $Ship='';
while ($Ship = $ships->next) { 

    my $voyageI = $db->get_collection('voyages')->find( { "ship_id" => $Ship->{_id} } );
    my $Voyage = $voyageI->next; # only ever 1

    
    my $transcriptionsI = $db->get_collection( 'classifications' )->find( { "voyage_id" => $Voyage->{_id} } );

    my %Days;
    my %Uids;
    while ( my $Transcription = $transcriptionsI->next ) {
	unless(defined($Transcription->{zooniverse_user_id})) { next; }
	my $Uid=$Transcription->{zooniverse_user_id};
	$Uids{$Uid}++;
	my $Date = $Transcription->{created_at};
	    my $Key = sprintf "%04d-%02d-%02d",$Date->{local_c}->{year},
			      $Date->{local_c}->{month},$Date->{local_c}->{day};
	$Days{$Key}{$Uid}++;
	#if(scalar(keys(%Days))>20) { last; }
    }
    
    my $sn=$Ship->{name};
    $sn =~ s/\s+/_/g;  
    open(DOUT,sprintf(">by_ship/%s.txt",$sn)) or die;

    printf DOUT "Date ";
    foreach my $Uid (keys(%Uids)) { printf DOUT "$Uid "; }
    print DOUT "\n";
    foreach my $Day (sort(keys(%Days))) {
	printf DOUT "%s",$Day;
	foreach my $Uid (keys(%Uids)) {
	    if(defined($Days{$Day}{$Uid})) { printf DOUT " %4d",$Days{$Day}{$Uid}; }
	    else { print DOUT "   NA"; }
	}
	print DOUT "\n";
        #die;
    }
    
    close(DOUT)

}
