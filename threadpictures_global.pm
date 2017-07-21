package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( %TP_GLOBAL @TP_all minmax warnarray warnhash cm min max print_ps_filestart pi my_round);

# %TP_GLOBAL holds all global variables
our %TP_GLOBAL;

# TP_threads is how many segment should exist in a net
# Could be overwritten with the same name env var
$TP_GLOBAL{threads} = $ENV{TP_threads} //=10;
$TP_GLOBAL{firstthread} = $ENV{TP_firstthread} //=0;
if (defined $ENV{TP_lastthread}) {$TP_GLOBAL{lastthread} = $ENV{TP_lastthread};}

# Every page has to have a name in PS; it is an automatically incremented number
$TP_GLOBAL{pagenumber} = 1;
# Which style we draw nets
# possible values: 'normal', 'holes'
# all other strings are future expansion; you will get a warning on STDERR for using a nonimplemented one
$TP_GLOBAL{style} = $ENV{TP_style} //='normal';

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

sub round { $_[0] > 0 ? int($_[0] + .5) : -int(-$_[0] + .5) ;}
sub round_digits{  my ($number,$digits)=@_; return round($number * 10**$digits) / 10**$digits; }
sub my_round{my ($number)=@_; return round_digits($number,8)};

sub cm { my ($i)=@_; return $i*28.34645;}

sub pi {return 3.14159265359;}

# page defaults, all in cm
$TP_GLOBAL{pageXsize} = cm($ENV{'TP_pageXsize'}//=21),
$TP_GLOBAL{pageYsize} = cm($ENV{'TP_pageYsize'}//=29.7),
$TP_GLOBAL{leftmargin} = cm($ENV{'TP_leftmargin'}//=2),
$TP_GLOBAL{rightmargin} = cm($ENV{'TP_rightmargin'}//=2),
$TP_GLOBAL{topmargin} = cm($ENV{'TP_topmargin'}//=2.5),
$TP_GLOBAL{bottommargin} = cm($ENV{'TP_bottommargin'}//=2.5),

# This variable collects everything (including all nets) to be drawn on one page
our @TP_all;

# What should be written on the bottom of the page
# Default is not to write anything
# not yet implemented !
$TP_GLOBAL{pagename} = $ENV{'TP_pagename'} //="";

# Returns an array of two values: the minimum and the maximum of an input numerical array
sub minmax { return (sort { $a <=> $b } @_)[0,-1]; }

sub warnarray { warn join(',',@_),"\n"; return @_;}

sub warnhash {my (%a)=@_; warn join(", ", map { "$_ => $a{$_}" } keys %a),"\n"; return %a; }

sub print_ps_filestart{
# Print the PS file start
print
"%!PS-Adobe-3.0
%%DocumentData: Clean7Bit
%%EndComments

<< /PageSize [$TP_GLOBAL{pageXsize} $TP_GLOBAL{pageYsize}] >> setpagedevice
0 setlinewidth

";
}
1;
