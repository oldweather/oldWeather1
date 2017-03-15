#!/usr/bin/perl

# Get Positions from edited ship history

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use MarineOb::IMMA;
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
$nhn =~ s/[\r\n]/ /gm; # strip newlines
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

    if($nhn[$i] =~ /(........................):\s+\(\<a href=\"http:/) {
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
    if($nhn[$i] =~ /lat\s+(\-*\d+\.*\d*)/) {
        $Lat{$PageID} = $1;
    }
    if($nhn[$i] =~ /long\s+(\-*\d+\.*\d*)/) {
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

# Get the old IMMA data
my @Old;
open(DIN,$Imma_file) or die "Can't open $Imma_file";
while ( my $Record = imma_read( \*DIN ) ) { push @Old,$Record; }
close(DIN);

# Delete the positions and replace them with edited ones
my @Imma;
foreach my $Record (@Old) {
    $Record->{LAT}=undef;
    $Record->{LON}=undef;
    if($Record->{SUPD} =~ /\d\d\d\d\D\d\d\D\d\d\D12/ &&   # Noon ob
       $Record->{SUPD} =~ /(4caf\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S\S)/ ) {
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

# Fill in the position gaps by interpolation
fill_gaps('LAT');
fill_gaps('LON');

# If infill needed - fill in missing positions from the old data
if($Infill) {
    for(my $i=0;$i<scalar(@Imma);$i++) {
	if(!defined($Imma[$i]->{LAT}) && defined($Old[$i]->{LAT})) {
	    $Imma[$i]->{LAT}=$Old[$i]->{LAT};
	}
	if(!defined($Imma[$i]->{LON}) && defined($Old[$i]->{LON})) {
	    $Imma[$i]->{LON}=$Old[$i]->{LON};
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

    # Give up if the gap is too long
    if (
        IMMA_Delta_Seconds( $Previous, $Next ) > $Max_days*86400
        && (   abs( $Previous->{LON} - $Next->{LON} ) > 5
            || abs( $Previous->{LAT} - $Next->{LAT} ) > 5 )
      )
    {
        return;
    }

    # Deal with any logitude wrap-arounds
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
    if(defined( $Ob->{YR}) &&
       defined( $Ob->{MO}) &&
       defined( $Ob->{DY}) &&
       defined( $Ob->{HR}) &&
       check_date($Ob->{YR},$Ob->{MO},$Ob->{DY}) &&
       check_time(int($Ob->{HR}/100),30,30)) { return(1); }
    return;
}
# Difference between 2 records in seconds
sub IMMA_Delta_Seconds {
    my $First = shift;
    my $Last  = shift;
    my ( $Dd, $Dh, $Dm, $Ds ) = Delta_DHMS(
        $First->{YR},
        $First->{MO},
        $First->{DY},
        int( $First->{HR} ),
        int( ( $First->{HR} - int( $First->{HR} ) ) * 60 ),
        0,
        $Last->{YR},
        $Last->{MO},
        $Last->{DY},
        int( $Last->{HR} ),
        int( ( $Last->{HR} - int( $Last->{HR} ) ) * 60 ),
        0
    );
    return $Dd * 86400 + $Dh * 3600 + $Dm * 60 + $Ds;
}
