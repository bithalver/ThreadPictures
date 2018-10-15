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
my $start_angle=0;
my $end_angle=360;
my $double_sided;

sub HELP_MESSAGE { # TODO: meaningful help message
  warn 'This code just provides a yaml file for ThreadPictures.pl
Usage:
  $0 [-h|--help|-?]   # this help and exit
  $0 [-p|--pieces pieces_number] [-i|--sides sides_number] [-s|-start_angle start_angle_number] [-e|-end_angle end_angle_number]

Examples:

export PIECES=100 ; export SIDES=100 ; export START_ANGLE=000 ; export END_ANGLE=360 ; ./sinus.pl -p $PIECES -i $SIDES -s $START_ANGLE -e $END_ANGLE | ./TP -o sinus.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf sinus.ps "sinus $PIECES $SIDES $START_ANGLE $END_ANGLE".pdf ; rm sinus.ps
export PIECES=150 ; export SIDES=100 ; export START_ANGLE=000 ; export END_ANGLE=540 ; ./sinus.pl -p $PIECES -i $SIDES -s $START_ANGLE -e $END_ANGLE | ./TP -o sinus.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf sinus.ps "sinus $START_ANGLE $END_ANGLE $PIECES $SIDES".pdf ; rm sinus.ps
export PIECES=150 ; export SIDES=100 ; export START_ANGLE=180 ; export END_ANGLE=720 ; ./sinus.pl -p $PIECES -i $SIDES -s $START_ANGLE -e $END_ANGLE | ./TP -o sinus.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf sinus.ps "output/sinus $START_ANGLE $END_ANGLE $PIECES $SIDES".pdf ; rm sinus.ps

export END_ANGLE=360 ; ./sinus.pl -p $PIECES -i $SIDES -s $START_ANGLE -e $END_ANGLE -d | ./TP -o sinus.ps  -p background=black -p color=red -p style=filledcurve; ps2pdf sinus.ps "output/sinus $START_ANGLE $END_ANGLE $PIECES $SIDES D".pdf ; rm sinus.ps
'; 
  exit 0;
}

GetOptions(
    'pieces|p=s' => \$pieces,
    'sides|i=s' => \$sides,
    'start|s=s' => \$start_angle,
    'end|e=s' => \$end_angle,
    'help|h|?' => \$opts_help,
    'd|double-sided|?' => \$double_sided,
);

if ($opts_help) {HELP_MESSAGE;}

print "# This is a generated yaml from $0
---
global:
    threads: 1
planes:
  - b;regular;$sides;0
  - s;freeform";

for my $i (0 .. $pieces) {
  my $angle=$start_angle+($end_angle-$start_angle)/$pieces*$i; print ';',-my_sin($angle),';',$angle;
#  print ';',-my_sin(360/$pieces*$i),';',360/$pieces*$i;

} print "\n";

for my $i (0 .. $pieces-1) {
  print "  - p$i;connected;s;",$i,";s;",$i+1,";b;1;2\n" ;
  if ($double_sided) {
    print "  - d$i;connected;s;",$i,";s;",$i+1,";b;2;1\n"
  }
}

print 
"pages:
  -
    - pagename;sinus - start and end angles:$start_angle-$end_angle , $pieces part, $sides sides";
if ($double_sided) {
  print ", Double"
}
print "
" ;

for my $i (0 .. $pieces-1) {
  print "    - net3;p$i;1;p$i;0;p$i;2\n";
  if ($double_sided) {
    print "    - net3;d$i;1;d$i;0;d$i;2\n";
  }
}
