#!/usr/bin/perl

# This code is designed to use with ThreadPictures.pl

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

sub HELP_MESSAGE { # TODO: meaningful help message
  warn 'This code just provides a yaml file for ThreadPictures.pl
Usage:
  $0 [-h|--help|-?]   # this help and exit
  $0 [-s|--sides number] [-a|--angle initial_angle] [-r|-srand srand_init_number]

Defaults:
  sides: 6
  angle: 0 (first corner is to the east)
  srand: 0 (which means NO setting the random generator)

Example:

export SIDES=6 ANGLE=0 SRAND=0 ; ./net.pl -s $SIDES -a $ANGLE -r $SRAND | ./TP -o net.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf net.ps "net_$SIDES_$ANGLE_$SRAND".pdf ; rm net.ps

'; 
  exit 0;
}

GetOptions(
    'sides|s=i' => \$sides,
    'angle|a=i' => \$angle,
    'srand|r=i' => \$srand_init,
    'help|h|?' => \$opts_help,
);

if ($opts_help) {HELP_MESSAGE;}

if ( $srand_init ) {srand $srand_init;} # init the randm generator ONLY if the srand_init is not zero.
my @shuffled =  shuffle(1..$sides);

print "# This is a generated yaml from $0
---
global:
    threads: 20
planes:
  - b;regular;$sides;$angle
pages:
  -
    - pagename;net - sides $sides, angle $angle";
if ($srand_init) {
  print ", srand init $srand_init"
}
print ", [";
printf "%d ", $_  for @shuffled;
print "]
" ;

for my $i (1 .. $sides) {
  print "    - net3s;b;",$shuffled[($i-1) % $sides],";",$shuffled[$i % $sides],";",$shuffled[($i+1) % $sides],"\n";
}
