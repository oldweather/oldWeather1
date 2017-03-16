#!/usr/bin/perl

# Get Positions from edited ship history

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fxmmmb fwbpgv fxtftc ix32dd ixdcdd fxbfms
     fwbptf fwbptc);
use Date::Calc qw(check_date check_time Delta_DHMS);

my $Imma_file;
my $Url;
my $Last=0;   # If==1 - use positions from the last page as well
my $Next=0;   # If==1 - use positions from the next page as well
my $Infill=0; # If==1 - edited history incomplete - infill missing positions from original records 
GetOptions(
    "imma=s"         => \$Imma_file,
    "url=s"          => \$Url,
    "lastpage=i"     => \$Last,
    "nextpage=i"     => \$Next,
    "infill=i"       => \$Infill
);
unless ( defined($Imma_file) &&
         defined($Url) ) { die "Usage: --imma=<imma_file> --url=<edited_history_url>"; }

# Set an output file name
my $OPFile = $Imma_file;
$OPFile =~ s/\.\.\/\.\.\/imma/imma_new/;

my $nhn=`curl $Url`;
$nhn =~ s/[\r\n]/ /g; # strip newlines
my @nhn = split /\<\/p\>/,$nhn; # split on paragraphs

#print Dumper @nhn;
#die;

my %Lat;
my %Lon;

my $PageID;
my @PageIDx;
my $PageCount=0;
my %PrevP;
my %NextP;

for(my $i=0;$i<scalar(@nhn);$i++) {

    if($nhn[$i] =~ /([0-9a-f]{24}):/) {
      	$PageID = $1;
        $PageIDx[$PageCount]=$PageID;
        if($PageCount>0) { 
           $NextP{$PageIDx[$PageCount-1]}=$PageID;
           $PrevP{$PageID}=$PageIDx[$PageCount-1];
        }
        $PageCount++;
    #    print "$PageID\n";
    }
    $nhn[$i] = lc($nhn[$i]);
    if($nhn[$i] =~ /lat\s+(\-*\d+\.*\d*)/ && !defined($Lat{$PageID})) {
        $Lat{$PageID} = $1;
    }
    if($nhn[$i] =~ /long\s+(\-*\d+\.*\d*)/ && !defined($Lon{$PageID})) {
        $Lon{$PageID} = $1;
        unless(defined($Lat{$PageID})) { 
           $Lat{$PageID} = undef;
        }
    }
}
#foreach $PageID (sort(keys(%Lat))) {
#    unless(defined($Lat{$PageID})) { $Lat{$PageID}='NA'; }
#    unless(defined($Lon{$PageID})) { $Lon{$PageID}='NA'; }
#    printf "%s,%s,%s\n",$PageID,$Lat{$PageID},$Lon{$PageID};
#}
#die;

# Get the old IMMA data
my @Old;
open(DIN,$Imma_file) or die "Can't open $Imma_file";
while ( my $Record = imma_read( \*DIN ) ) { 
   # Extract the ship date and time
    if($Record->{SUPD} =~ /(\d\d\d\d)\/(\d\d)\/(\d\d):(\d\d)/) {
       $Record->{YR2} = $1;
       $Record->{MO2} = $2;
       $Record->{DY2} = $3;
       $Record->{HR2} = $4;
       if($Record->{HR2}==24) { $Record->{HR2}=23.99; }
    }
   push @Old,$Record;
}
close(DIN);

# Delete the positions and replace them with edited ones
my @Imma;
foreach my $Record (@Old) {
    $Record->{LAT}=undef;
    $Record->{LON}=undef;
    if($Record->{HR2}==12 &&   # Noon ob
       $Record->{SUPD} =~ /([0-9a-f]{24})/ ) {
	if(defined($Lat{$1})) { 
           $Record->{LAT}=$Lat{$1};
        } else {
	    if($Last && defined($PrevP{$1}) &&
               defined($Lat{$PrevP{$1}})) { $Record->{LAT}=$Lat{$PrevP{$1}}; }
	    if($Next && defined($NextP{$1}) &&
               defined($Lat{$NextP{$1}})) { $Record->{LAT}=$Lat{$NextP{$1}}; }
	}					    
        if(defined($Lon{$1})) { 
           $Record->{LON}=$Lon{$1}; 
       } else {
	    if($Last && defined($PrevP{$1}) &&
               defined($Lon{$PrevP{$1}})) { $Record->{LON}=$Lon{$PrevP{$1}}; }
	    if($Next && defined($NextP{$1}) &&
               defined($Lon{$NextP{$1}})) { $Record->{LON}=$Lon{$NextP{$1}}; }
	}
    }
    push @Imma,$Record      
}

# QC check - filter out 1-off hemisphere errors
if(0) { # Don't
my @Threepoint;
for(my $i=0;$i<scalar(@Imma);$i++) {
    if(defined($Imma[$i]->{LAT})) {
	if(defined($Threepoint[1])) { $Threepoint[0]=$Threepoint[1]; }
	if(defined($Threepoint[2])) { $Threepoint[1]=$Threepoint[2]; }
	$Threepoint[2]=$i;
        if(defined($Threepoint[0])) {
	    if($Imma[$Threepoint[0]]->{LAT}*$Imma[$Threepoint[2]]->{LAT}>0) {
		if($Imma[$Threepoint[1]]->{LAT}*$Imma[$Threepoint[2]]->{LAT}<0) {
		    $Imma[$Threepoint[1]]->{LAT} *= -1;
		}
	    }
	}
    }
}
@Threepoint=undef;
for(my $i=0;$i<scalar(@Imma);$i++) {
    if(defined($Imma[$i]->{LON})) {
	if(defined($Threepoint[1])) { $Threepoint[0]=$Threepoint[1]; }
	if(defined($Threepoint[2])) { $Threepoint[1]=$Threepoint[2]; }
	$Threepoint[2]=$i;
        if(defined($Threepoint[0])) {
	    if($Imma[$Threepoint[0]]->{LON}*$Imma[$Threepoint[2]]->{LON}>0) {
		if($Imma[$Threepoint[1]]->{LON}*$Imma[$Threepoint[2]]->{LON}<0) {
		    $Imma[$Threepoint[1]]->{LON} *= -1;
		}
	    }
	}
    }
}
}		   

# Fill in the position gaps by interpolation
fill_gaps('LAT');
fill_gaps('LON');

# Update UTC dates given new position
foreach my $Record (@Imma) {
   if(defined($Record->{LAT}) && defined($Record->{LON}) &&
      defined($Record->{YR2}) && defined($Record->{MO2}) &&
      defined($Record->{DY2}) && defined($Record->{HR2}) &&
      IMMA_check_date($Record)) {
	my $elon=$Record->{LON};
	if ( $elon < 0 ) { $elon += 360; }
        if( $elon<0.1 ) { $elon=0.1; } # Buggy around 0/360
        if( $elon>359.9 ) { $elon=359.9; } 
	my ( $uhr, $udy ) = rxltut(
	    $Record->{HR2} * 100,
	    ixdtnd( $Record->{DY2}, $Record->{MO2}, $Record->{YR2} ),
	    $elon * 100
	);
	$Record->{HR} = $uhr / 100;
	( $Record->{DY}, $Record->{MO}, $Record->{YR} ) = rxnddt($udy);
   }
}

# If infill needed - fill in missing positions from the old data
if($Infill) {
    
    my @Inf;
    open(DIN,$Imma_file) or die "Can't open $Imma_file";
    while ( my $Record = imma_read( \*DIN ) ) { 
       push @Inf,$Record;
    }
    close(DIN);
    
    for(my $i=0;$i<scalar(@Imma);$i++) {
	if(!defined($Imma[$i]->{LAT}) && defined($Inf[$i]->{LAT})) {
	    $Imma[$i]->{LAT}=$Inf[$i]->{LAT};
	}
	if(!defined($Imma[$i]->{LON}) && defined($Inf[$i]->{LON})) {
	    $Imma[$i]->{LON}=$Inf[$i]->{LON};
	}
    }
}

# Done - output the new obs
open(DOUT,">$OPFile") or die "Can't write to $OPFile";
for(my $i=0;$i<scalar(@Imma);$i++) {
    $Imma[$i]->write(\*DOUT);
}
close(DOUT);

sub interpolate {
    my $Var      = shift;
    my $Previous = shift;
    my $Next     = shift;
    my $Target   = shift;
    my $Max_days = shift;
    my $Max_var  = shift;

    unless(defined($Previous) && defined($Next)) { return; }

    # Give up if the gap is too long
    if (
        IMMA_Delta_Seconds( $Previous, $Next ) > $Max_days*86400
        && (   abs( $Previous->{LON} - $Next->{LON} ) > 5
            || abs( $Previous->{LAT} - $Next->{LAT} ) > 5 )
      )
    {
        return;
    }

    # Deal with any lnogitude wrap-arounds
    my $Next_var = $Next->{$Var};
    if( $Var eq 'LON') {
       if ( $Next_var - $Previous->{LON} > 180 ) { $Next_var -= 360; }
       if ( $Next_var - $Previous->{LON} < -180 ) { $Next_var += 360; }
    }

    # Give up if the separation is too great
    if (   abs( $Next_var - $Previous->{$Var} ) > $Max_var ) { return; }

    # Do the interpolation
    if ( IMMA_Delta_Seconds( $Target, $Next ) <= 0 ) { return; }
    if ( IMMA_Delta_Seconds( $Previous, $Next ) <= 0 ) { return; }
    my $Weight = IMMA_Delta_Seconds( $Target, $Next ) / 
                 IMMA_Delta_Seconds( $Previous, $Next );
    if ( $Weight < 0 || $Weight > 1 ) { return ( undef, undef ); }
    my $Target_var = $Next_var * ( 1 - $Weight ) + $Previous->{$Var} * $Weight;
    if( $Var eq 'LON') {
       if ( $Target_var < -180 ) { $Target_var += 360; }
       if ( $Target_var > 180 ) { $Target_var -= 360; }
    }
    return ( $Target_var );
}
# Find the last previous ob that has a date
sub find_previous {
    my $Var = shift;
    my $Point = shift;
    for ( my $j = $Point - 1 ; $j >= 0 ; $j-- ) {
        if ( defined( $Imma[$j]->{$Var}) &&
             IMMA_check_date($Imma[$j])) { return($j); }
    }
    return;
}
# Find the next subsequent ob that has a valid date and
#  value of $Var;
sub find_next {
    my $Var = shift;
    my $Point = shift;
    for ( my $j = $Point + 1 ; $j < scalar(@Imma) ; $j++ ) {
        if ( defined( $Imma[$j]->{$Var}) &&
             IMMA_check_date($Imma[$j])) { return($j); }
    }
   return;
}

sub fill_gaps {
    my $Var = shift;
    for ( my $i = 0 ; $i < scalar(@Imma) ; $i++ ) {
        unless(IMMA_check_date($Imma[$i])) { next; }
	if ( defined( $Imma[$i]->{$Var} ) ) {
	    next;
	}
	my $Previous = find_previous($Var,$i);
	my $Next     = find_next($Var,$i);
	if (   defined($Previous)
	    && defined($Next) )
	{
	    $Imma[$i]->{$Var} = interpolate( $Var, $Imma[$Previous],
                                                   $Imma[$Next],
                                                   $Imma[$i],
                                             30,100);
	}
    }
}

# Check that a record has a good date & time
sub IMMA_check_date {
    my $Ob = shift;
    if(defined( $Ob->{YR2}) &&
       defined( $Ob->{MO2}) &&
       defined( $Ob->{DY2}) &&
       defined( $Ob->{HR2}) &&
       check_date($Ob->{YR2},$Ob->{MO2},$Ob->{DY2}) &&
       check_time(int($Ob->{HR2}/100),30,30)) { return(1); }
    return;
}
# Difference between 2 records in seconds
sub IMMA_Delta_Seconds {
    my $First = shift;
    my $Last  = shift;
    my ( $Dd, $Dh, $Dm, $Ds ) = Delta_DHMS(
        $First->{YR2},
        $First->{MO2},
        $First->{DY2},
        int( $First->{HR2} ),
        int( ( $First->{HR2} - int( $First->{HR2} ) ) * 60 ),
        0,
        $Last->{YR2},
        $Last->{MO2},
        $Last->{DY2},
        int( $Last->{HR2} ),
        int( ( $Last->{HR2} - int( $Last->{HR2} ) ) * 60 ),
        0
    );
    return $Dd * 86400 + $Dh * 3600 + $Dm * 60 + $Ds;
}

