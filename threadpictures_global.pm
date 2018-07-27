package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( %TP_GLOBAL %TP_PARAMS @TP_all %TP_planes global_init minmax warnarray warnhash cm min max print_ps_filestart pi my_round colorconvert $opts_input $opts_output $opts_help $opts_help_plane $opts_version $opts_debug);

# %TP_GLOBAL holds all global variables, has lowest priority; collected from 3 "sources":
#   - built-in defaults
#   - environment variables (in the form of "TP_variablename"; case DOES matter
#   - globals specied in YAML file
our %TP_GLOBAL;

# %TP_PARAMS holds parameters specified with -p command line options; starts empty; has highest priority
our %TP_PARAMS;

our ($opts_input, $opts_output, $opts_help, $opts_version, $opts_debug)=('stdin','stdout');

sub global_init {
  # page defaults, all in cm
  # default is A4 (I live in Europe ;) )
  $TP_GLOBAL{pageXsize} = cm($ENV{'TP_pageXsize'}//=21),
  $TP_GLOBAL{pageYsize} = cm($ENV{'TP_pageYsize'}//=29.7),
  $TP_GLOBAL{leftmargin} = cm($ENV{'TP_leftmargin'}//=2),
  $TP_GLOBAL{rightmargin} = cm($ENV{'TP_rightmargin'}//=2),
  $TP_GLOBAL{topmargin} = cm($ENV{'TP_topmargin'}//=2.5),
  $TP_GLOBAL{bottommargin} = cm($ENV{'TP_bottommargin'}//=2.5),

  $TP_GLOBAL{pagename} = $ENV{'TP_pagename'} //="";

  # 'threads' is how many segment should exist in a net
  $TP_GLOBAL{threads} = $ENV{TP_threads} //=20;
  $TP_GLOBAL{firstthread} = $ENV{TP_firstthread} //=0;
  $TP_GLOBAL{lastthread} = $ENV{TP_lastthread} //= $TP_GLOBAL{threads};

  $TP_GLOBAL{style} = $ENV{TP_style} //='normal';
  if ($opts_debug) {warn 'global style is '.$TP_GLOBAL{style}."\n"}

  $TP_GLOBAL{BW} = $ENV{TP_BW} //=0;

  $TP_GLOBAL{background} = $ENV{TP_background} //='white';
  $TP_GLOBAL{color} = $ENV{TP_color} //='black';
  $TP_GLOBAL{fontcolor} = $ENV{TP_color} //='black';

  # How many slices do we use in a path ?
  $TP_GLOBAL{slices} = $ENV{TP_slices} //=20;

  # Which path variant do we use ? possible values are 'out' 'crossed'
  $TP_GLOBAL{path_variant} = $ENV{TP_path_variant} //='out';
  
  # For the 'param' path, what is the numerical parameter ? Default is zero, which is 'out'
  $TP_GLOBAL{path_param} = $ENV{TP_path_param} //=0;

  # Every page has to have a name in PS; because it does not matter, it is an automatically incremented number
  $TP_GLOBAL{pagenumber} = 1;
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

sub round { $_[0] > 0 ? int($_[0] + .5) : -int(-$_[0] + .5) ;}
sub round_digits{  my ($number,$digits)=@_; return round($number * 10**$digits) / 10**$digits; }
sub my_round{my ($number)=@_; return round_digits($number,8)};

sub cm { my ($i)=@_; return $i*28.34645;}

sub pi {return 4 * atan2(1, 1);}

# %TP_planes holds data for regular and not regular planes; points of planes are used to build nets
our %TP_planes;

# @TP_all array collects everything (including all nets) to be drawn on one page
# most important array !
our @TP_all;

# Returns an array of two values: the minimum and the maximum of an input numerical array
sub minmax { return (sort { $a <=> $b } @_)[0,-1]; }

sub warnarray { no warnings 'uninitialized'; warn join(';',@_),"\n"; return @_;}

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
#   - a color name (like 'white') , which is converted to last format
#   - 3 comma-separated number (like '0.1,1,0.9') all numbers should be 0<=x<=1
#   - 3 space-separated number (like '0.1 1 0.9') all numbers should be 0<=x<=1
sub colorconvert { my ($input)=@_;
  my %colornames=(
    white => '1 1 1',
    black => '0 0 0',
    gray => '0.5 0.5 0.5',
    lightgray => '0.75 0.75 0.75',
    darkgray => '0.25 0.25 0.25',
    red => '1 0 0',
    lightgreen => '0 1 0',
    green => '0 0.8 0',
    darkgreen => '0 0.4 0',
    darkblue => '0 0 0.65',
    blue => '0 0 1',
    lightblue => '0.12 0.5625 1',
    yellow => '1 1 0',
    orange => '1 0.7 0',
    cyan => '0 1 1',
    brown => '0.52 0.34 0.137',
  );
  if ($input =~ /^[a-z]/) { $input=$colornames{$input}; }
  $input=~s/,/ /g; # we want to write it to PS file like '0.5 0.5 0.5'
  return ($input);
}

1;

=pod
All global(looking) variables and where can they be set:

GLOBAL means the variable has a default and can be overwritten from an environment variable and/or global parameter in YAML file
PARAM means the variable can be overwritten from command parameter (-p option)
PAGE means the variable is modifiable for every page
NET means the variable is modifiable for every net

After the colon there is the default value

Automatic variables, should not me modified by hand:
# Every page has to have a name in PS; because it does not matter, it is an automatically incremented number
pagenumber: 1 # Automatically incremented

GLOBAL level only:
pageXsize: 21 cm
pageYsize: 29.7 cm
leftmargin: 2 cm
rightmargin 2 cm
topmargin: 2.5 cm
bottommargin: 2.5 cm

GLOBAL and PARAM level:
pagename: "" # What should be written on the bottom of the page; variable is deleted after used for first page
threads: 20 # 'threads' is how many segment should exist in a net
firstthread: 0
lastthread: threads}
BW: 0 # Do we want to ignore all color specificaion ? BW is just white background, black drawings, black pagename

GLOBAL PARAM and NET level:
# Which style we draw nets
# possible values: normal, holes, border, triangle, filledtriangle, curve, filledcurve, inversefilledcurve, parallel, selected
# all other strings are future expansion; you will get a warning on STDERR for using a nonimplemented one but processing goes on
style: 'normal'
slices: 20 # How many slices do we use in a path ?
path_variant: 'out' # Which path variant do we use ? possible values are 'out' 'crossed' 'param'
path_param: 0 # For the 'param' path, what is the numerical parameter ? Default is zero, which is 'out'

GLOBAL PARAM and PAGE level:
background: 'white'
fontcolor: black # What color do we use to write the pagename at the bottom of the page ?

GLOBAL PARAM PAGE and NET level:
color: 'black' # Which color do we use to draw the elements of a net
=cut
