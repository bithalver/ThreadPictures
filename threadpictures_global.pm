package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( %TP_GLOBAL %TP_PARAMS @TP_all %TP_planes global_init minmax warnarray warnhash cm min max print_ps_filestart pi my_round colorconvert $opts_input $opts_output $opts_help $opts_version $opts_debug);

# %TP_GLOBAL holds all global variables (even built-in defaults _or_ environment variable values
our %TP_GLOBAL;

# %TP_PARAMS holds parameters specified with -p command line options; starts empty
our %TP_PARAMS;

our ($opts_input, $opts_output, $opts_help, $opts_version, $opts_debug)=('stdin','stdout');

sub global_init {
  # 'threads' is how many segment should exist in a net
  # Could be overwritten with the same name env var
  $TP_GLOBAL{threads} = $ENV{TP_threads} //=20;
  $TP_GLOBAL{firstthread} = $ENV{TP_firstthread} //=0;
  if (defined $ENV{TP_lastthread}) {$TP_GLOBAL{lastthread} = $ENV{TP_lastthread};}

  # Every page has to have a name in PS; it is an automatically incremented number
  $TP_GLOBAL{pagenumber} = 1;
  # Which style we draw nets
  # possible values: normal, holes, border, triangle, filledtriangle, curve, filledcurve, inversefilledcurve, parallel, selected
  # all other strings are future expansion; you will get a warning on STDERR for using a nonimplemented one
  $TP_GLOBAL{style} = $ENV{TP_style};
  if ($opts_debug) {warn 'global style is '.$TP_GLOBAL{style}."\n"}

  # Do we want to ignore all color specificaion ? BW is just white background, black drawings
  $TP_GLOBAL{BW} = $ENV{TP_BW};

  $TP_GLOBAL{background} //= $ENV{TP_background};
  $TP_GLOBAL{color} //= $ENV{TP_color};

  # How many slices do we use in a path ?
  $TP_GLOBAL{slices} //= $ENV{TP_slices};

  # Which path variant do we use ? possible values are 'out' 'crossed'
  $TP_GLOBAL{path_variant} //= $ENV{TP_path_variant};
  
  # For the 'param' path, what is the numerical parameter ? Default is zero, which is 'out'
  $TP_GLOBAL{path_param} //= $ENV{TP_path_param};
}

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

# %TP_planes holds data for regular and not regular planes; points of planes are used to build nets
our %TP_planes;

# @TP_all array collects everything (including all nets) to be drawn on one page
# most important array !
our @TP_all;

# What should be written on the bottom of the page
# Default is not to write anything
$TP_GLOBAL{pagename} = $ENV{'TP_pagename'} //="";

# Returns an array of two values: the minimum and the maximum of an input numerical array
sub minmax { return (sort { $a <=> $b } @_)[0,-1]; }

sub warnarray { warn join(',',@_),"\n"; return @_;}

sub warnhash {my (%a)=@_; warn join(", ", map { "$_ => $a{$_}" } keys %a),"\n"; return %a; }

# Print the mandatory PS file start
sub print_ps_filestart{
print
"%!PS-Adobe-3.0
%%DocumentData: Clean7Bit
%%EndComments

<< /PageSize [$TP_GLOBAL{pageXsize} $TP_GLOBAL{pageYsize}] >> setpagedevice
0 setlinewidth
";
}

# converts color names to 3 number as required in postscript
# input is one string containing even 
#   - a color name (like 'white')
#   - 3 comma-eparated number (like '0.1,1,0.9') all numbers should be 0<=x<=1
sub colorconvert { my ($input)=@_;
  my %colornames=(
    white => '1,1,1',
    black => '0,0,0',
    gray => '0.5,0.5,0.5',
    lightgray => '0.75,0.75,0.75',
    darkgray => '0.25,0.25,0.25',
    red => '1,0,0',
    green => '0,1,0',
    blue => '0,0,1',
    lightblue => '0.12,0.5625,1',
    yellow => '1,1,0',
    orange => '1,0.7,0',
    cyan => '0,1,1',
  );
  if ($input =~ /^[a-z]/) { $input=$colornames{$input}; }
  $input=~s/,/ /g; # we want to write it to PS file like '0.5 0.5 0.5'
  return ($input);
}

1;
