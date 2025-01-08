package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( %TP_GLOBAL %TP_PARAMS @TP_all %TP_planes global_init minmax warnarray warnhash cm min max print_ps_filestart pi my_round colorconvert $opts_input $opts_output $opts_help $opts_help_coords $opts_help_plane $opts_version $opts_debug %TP_colors weight my_random_order percent_on_line TP_weight percent_on_line pointsfromplanesordirect);

# %TP_GLOBAL holds all global variables, has lowest priority; collected from 3 "sources":
#   - built-in defaults
#   - environment variables (in the form of "TP_variablename"; case DOES matter
#   - globals specied in YAML file
our %TP_GLOBAL;

# %TP_PARAMS holds parameters specified with -p command line options; starts empty; has highest priority
our %TP_PARAMS;

our ($opts_input, $opts_output, $opts_help, $opts_version, $opts_debug)=('stdin','stdout');

our %TP_colors;

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
  $TP_GLOBAL{lastthread} = $ENV{TP_lastthread} //= '100%';

  $TP_GLOBAL{style} = $ENV{TP_style} //='normal';
  if ($opts_debug) {warn 'global style is '.$TP_GLOBAL{style}."\n\n"}

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

  # For the 'moon' style, there is a need for 2 numbers for the 2 Bezier-curves
  $TP_GLOBAL{moon1} = $ENV{TP_moon1} //=0.6666666; # this is the curve the lines draw
  $TP_GLOBAL{moon2} = $ENV{TP_moon2} //=0.5;

  $TP_GLOBAL{hollowmooncolor1} = $ENV{TP_hollowmooncolor1};
  $TP_GLOBAL{hollowmooncolor2} = $ENV{TP_hollowmooncolor2};

  # Every page has to have a name in PS; because it does not matter, it is an automatically incremented number
  $TP_GLOBAL{pagenumber} = 1;
  
  # color name -> value conversion table
  %TP_colors=(
    white => '1 1 1',
    black => '0 0 0',
    gray => '0.5 0.5 0.5',
    lightgray => '0.75 0.75 0.75',
    darkgray => '0.25 0.25 0.25',
    lightred => '1 0.5 0.5',
    red => '1 0 0',
    darkred => '0.5 0 0',
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
    pink => '1 0.08 0.57',
    lightpurple => '1 0 1',
    purple => '0.5 0 0.5',
	gold => '0.984 0.797 0.015',
	silver => '0.637 0.637 0.637',
  );

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

# creates a weighted result between $from (when $weight is 0) and $to (when $weight is 1)
sub weight {my ($from, $to, $weight)=@_ ; return ((1-$weight)*$from+$weight*$to)}

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
  if ($input =~ /^[a-zA-Z]/) { $input=$TP_colors{$input}; }
  $input=~s/,/ /g; # we want to write it to PS file like '0.5 0.5 0.5'
  return ($input);
}

# Returns numbers 1 .. $param in random order
# input parameter: length
# return value: array of integers
sub my_random_order {
  my $my_length=$_[0];
  my @RA; # ReturnArray
  my @LoN = (1..$my_length);
  for (my $i=$my_length-1;$i>=0;$i--){
    push(@RA,splice(@LoN,rand($i),1));
  }
  return @RA;
}
# print my_random_order(4);print "\n";
# print my_random_order(6);print "\n";

# TP_weight returns an array consisting of X,Y coordinates of the weighted point between from and to coordinates; last parameter is the weight
# test: 
#    my ($a,$b)= TP_weight(10,10,20,20,3),"\n" ; print "$a,$b\n";
sub TP_weight {
  my ($fromX,$fromY,$toX,$toY,$weight,$threads)=@_;
  my $fromRate=($threads-$weight)/$threads;
  my $toRate=$weight/$threads;
  return ($fromX*$fromRate+$toX*$toRate,$fromY*$fromRate+$toY*$toRate);
}

# leaves 'direct' points (number pairs) unmodified, but transforms ones defined with planes to x,y pairs
sub pointsfromplanesordirect {
  my @input=@_; my @processedinput;
  # ---[BEGIN]--- Specify points from predefined planes _or_ directly
  while (@input) {
    $_=shift @input;
    if ( /^[0-9-]/) { push(@processedinput,$_);} # direct coordinate
    else { # coordinate specified by a plane,point pair
      my $planename=$_; my $planeindex=shift @input;
      push @processedinput, ($TP_planes{$planename}[2*$planeindex],$TP_planes{$planename}[2*$planeindex+1]);
    }
  }
  # ---[END]--- Specify points from predefined planes _or_ directly
  return @processedinput;
}

sub percent_on_line {
  # if input does not start with "*" -> give it back as output
  my $I=$_[0];
  my @O;
  # return $I if (substr($I , 0, 1) ne "*")
  if (substr($I , 0, 1) ne "*") {
    push (@O, $I);
  } else {
    my ($x1, $y1, $x2, $y2, $w) = split(',',substr($I,1));
    ($x1, $y1)=pointsfromplanesordirect($x1, $y1);
    ($x2, $y2)=pointsfromplanesordirect($x2, $y2);
    push(@O,TP_weight($x1, $y1, $x2, $y2, $w, 1));
  }
  # warnarray(@O);
  return @O;
}


1;

=pod
All global(looking) variables and where can they be set:

GLOBAL means the variable has a default and can be overwritten from an environment variable and/or global parameter in YAML file
PARAM means the variable can be overwritten from command parameter (-p option)
PAGE means the variable is modifiable for every page
NET means the variable is modifiable for every net

After the colon is the default value

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
