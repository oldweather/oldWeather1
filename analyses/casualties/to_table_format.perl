#!/opt/local/bin/perl

#  Make a table with all the casualty records in for the blog

use strict;
use warnings;

my @Casualties;
open(DIN,"casualties.out.edited");
while(my $Line=<DIN>) {
    chomp($Line);
    my @Fields = split /\t/,$Line;
    unless($Fields[1] =~ /\d/) {$Fields[1] = '9999'; }
    push @Casualties,\@Fields;
}
close(DIN);

@Casualties = sort {$a->[1] cmp $b->[1]} @Casualties;
for(my $i=0;$i<scalar(@Casualties);$i++) {

    if($i%7==0) { print "</tr><tr>\n"; }

    my $Rnd = int(rand(3));
    print "<td style=\"border-top: 0px solid #ddd;\">";
    if($Rnd==0) { print "&nbsp; "; }
    printf "<a href=\"%s\">",$Casualties[$i]->[3];
    print "<img src=\"https://oldweather.files.wordpress.com/2014/11/poppy-closeup.jpg\"";
    print " width=50 height=50";
    if($Casualties[$i]->[1] =~ /9999/) { $Casualties[$i]->[1]='';}
    printf " title=\"%s H.M.S. %s %s\">",$Casualties[$i]->[0],$Casualties[$i]->[2],$Casualties[$i]->[1];
    print "</a>";
    if($Rnd==2) { print "&nbsp; "; }
    print "</td>\n";
    #if($i>=35) { last; }
}
