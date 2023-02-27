#!/usr/bin/perl

# This code is designed to use with ThreadPictures.pl
# started on 2023 01 24 ; lots of code copied from sinus.pl

use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

use List::Util qw(shuffle);

my $sides=6;
my $angle=0;
my $srand_init=0;
my $net4=0 ;
my $opts_help;
my @points;

sub HELP_MESSAGE { # TODO: meaningful help message
  warn 'This code just provides a yaml file for ThreadPictures.pl
Usage:
  $0 [-h|--help|-?]   # this help and exit
  $0 [-s|--sides number] [-a|--angle initial_angle] [-r|-srand srand_init_number] [-points|p p1,p2,p3,p4]

Defaults:
  sides: 6
  angle: 0 (first corner is to the east)
  srand: 0 (which means NOT setting the random generator; value is meaningless if points are given)
  points: no default
  
Examples:

export SIDES=6 ANGLE=-60 POINTS="1,3,5,6,4,2" STYLE=moon ; ./net.pl -s $SIDES -a $ANGLE --points $POINTS | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${STYLE}.pdf" ; rm net.ps

export SIDES=8 ANGLE=-67.5 POINTS="1,3,5,7,8,6,4,2" STYLE=normal ; ./net.pl -s $SIDES -a $ANGLE --points $POINTS | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${STYLE}.pdf" ; rm net.ps

export SIDES=10 ANGLE=-72 POINTS="1,3,5,7,9,10,8,6,4,2" STYLE=moon ; ./net.pl -s $SIDES -a $ANGLE --points $POINTS | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${STYLE}.pdf" ; rm net.ps

export SIDES=12 ANGLE=-75 POINTS="1,3,5,7,9,11,12,10,8,6,4,2" STYLE=moon ; ./net.pl -s $SIDES -a $ANGLE --points $POINTS | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${STYLE}.pdf" ; rm net.ps


unset SIDES ANGLE STYLE POINTS SRAND; export SIDES=8 ANGLE=-112.5 STYLE=moon; ./net.pl -p "2,1,5,3,4,7,8,6" --net4 -s $SIDES -a $ANGLE | ./TP -o net.ps  -p background=darkgray -p moon2=0.9 -p moon1=0.7 -p fontcolor=white -p color=lightblue -p style=$STYLE; ps2pdf net.ps "net_8_moon_-112.5_2,1,5,3,4,7,8,6__moon1_0.7_moon2_0.9.pdf" ; rm net.ps


Let the chaos flow !

export SIDES=12 ANGLE=-75 SRAND=0 STYLE=normal ; ./net.pl -s $SIDES -a $ANGLE -r $SRAND | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${SRAND}.pdf" ; rm net.ps

unset SIDES ANGLE STYLE POINTS SRAND; export SIDES=50 ANGLE=0 STYLE=hollowmoon; ./net.pl -s $SIDES -a $ANGLE | ./TP -o net.ps  -p background=darkgray -p hollowmooncolor1=yellow -p hollowmooncolor2=green -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${STYLE}.pdf" ; rm net.ps
'; 
  exit 0;
}

GetOptions(
    'sides|s=i' => \$sides,
    'angle|a=f' => \$angle,
    'srand|r=i' => \$srand_init,
    'net4!' => \$net4,
    'help|h|?' => \$opts_help,
	  'points|p=s' => \@points,
);

@points = split(/,/,join(',',@points));

if ($opts_help) {HELP_MESSAGE;}

# initialize the random generator ONLY if the srand_init is not zero.
# have no effect if points are given as parameter
if ( $srand_init ) {srand $srand_init;}

my @shuffled = (@points?@points:shuffle(1..$sides));
# printf STDERR "%d,", $_  for @shuffled[0..$#shuffled-1]; printf STDERR "%d" , $shuffled[-1]; print STDERR "\n";

# print STDERR "angle $angle \n";

# print STDERR "net4 $net4 \n";

print "# This is a generated yaml from $0
---
global:
planes:
  - b$sides;regular;$sides;$angle
pages:
  -
    - pagename;net";
print "4" if ($net4);
print " - sides $sides, angle $angle";
# if ($srand_init) { print ", srand init $srand_init"}

print ", points ",join(",",@shuffled),"\n" ;

print "    - loop";
print "4" if ( $net4 ) ;
print ";b$sides;",join(";",@shuffled),"\n";
