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

Let the chaos flow !

export SIDES=12 ANGLE=-75 SRAND=0 STYLE=normal ; ./net.pl -s $SIDES -a $ANGLE -r $SRAND | ./TP -o net.ps  -p background=darkgray -p color=yellow -p fontcolor=yellow -p style=$STYLE; ps2pdf net.ps "net_${SIDES}_${ANGLE}__${POINTS}__${SRAND}.pdf" ; rm net.ps
'; 
  exit 0;
}

GetOptions(
    'sides|s=i' => \$sides,
    'angle|a=f' => \$angle,
    'srand|r=i' => \$srand_init,
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

print "# This is a generated yaml from $0
---
global:
    threads: 20
planes:
  - b;regular;$sides;$angle
pages:
  -
    - pagename;net - sides $sides, angle $angle";
# if ($srand_init) { print ", srand init $srand_init"}

print ", points ";
printf "%d,", $_  for @shuffled[0..$#shuffled-1]; printf "%d" , $shuffled[-1];
print "\n" ;

for my $i (1 .. $sides) {
  print "    - net3s;b;",$shuffled[($i-1) % $sides],";",$shuffled[$i % $sides],";",$shuffled[($i+1) % $sides],"\n";
}