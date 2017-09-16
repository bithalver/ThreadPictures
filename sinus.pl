#!/usr/bin/perl

# This code is designed to use with ThreadPictures.pl

use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

use threadpictures_global;

sub my_sin {return  my_round(sin($_[0]/180*pi()))*90};
my $pieces=6;
my $sides=6;
my $opts_help;

sub HELP_MESSAGE { # TODO: meaningful help message
  warn 'This code just provides a yaml file for ThreadPictures.pl
Usage:
  $0 [-h|--help|-?]   # this help and exit
  $0 [-p|--pieces pieces_number] [-s|--sides sides_number]

Example:

export PIECES=100 ; export SIDES=100 ; ./sinus.pl --pieces $PIECES -s $SIDES| ./TP -o sinus.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf sinus.ps "sinus $PIECES $SIDES".pdf ; rm sinus.ps',"\n";
  exit 0;
}

GetOptions(
    'pieces|p=s' => \$pieces,
    'sides|s=s' => \$sides,
    'help|h|?' => \$opts_help,
);

if ($opts_help) {HELP_MESSAGE;}

print "# This is a generated yaml from $0
---
global:
    threads: 20
planes:
  - b;regular;$sides;0
  - s;freeform";

for my $i (0 .. $pieces) {
  print ';',-my_sin(360/$pieces*$i),';',360/$pieces*$i;
} print "\n";

for my $i (0 .. $pieces-1) {
#  print "  - p$i;connected;b;1;b;2;s;",$i,";",$i+1,"\n"
  print "  - p$i;connected;s;",$i,";s;",$i+1,";b;1;2\n"
}

print 
"pages:
  -
    - pagename;sinus - $pieces part, $sides sides start
" ;

for my $i (0 .. $pieces-1) {
#  print "    - net3;plane2;1;plane2;2;plane2;3\n";
  print "    - net3;p$i;1;p$i;0;p$i;2\n";
}
