#!/opt/local/bin/perl

#  Make a table with all the mentions of love in the forum

use strict;
use warnings;

my @Mentions;
open(DIN,"forum_love.txt");
while(my $Line=<DIN>) {
    chomp($Line);
    $Line =~ s/\"//g;
    my @Fields = split /\s+http/,$Line;
    push @Mentions,\@Fields;
}
close(DIN);

for(my $i=0;$i<scalar(@Mentions);$i++) {

    if($i%7==0) { print "</tr><tr>\n"; }

    print "<td style=\"border-top: 0px solid #ddd;\">";
    printf "<a href=\"http%s\">",$Mentions[$i]->[1];
    print "<img src=\"https://oldweather.files.wordpress.com/2015/02/heart.png\"";
    print " width=50 height=50";
    printf " title=\"%s\">",$Mentions[$i]->[0];
    print "</a>";
    print "</td>\n";
    #if($i>=35) { last; }
}
