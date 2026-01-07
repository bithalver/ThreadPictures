#!/usr/bin/perl -I .
use strict;
use warnings;
use 5.10.0;
# use feature "switch";
use Switch;
no warnings 'experimental::smartmatch';

use threadpictures_global;
use threadpictures_draw;
use threadpictures_plane;

use YAML::XS 'LoadFile';
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

# ---[BEGIN] test section
# on final version, the whole section should be commented out / deleted !

# ---[END] test section

sub VERSION_MESSAGE { warn "ThreadPictures version 1.2\n"; exit 0}

sub HELP_MESSAGE { # TODO: meaningful help message
  warn "Usage:
  $0 [-h|--help|-?] # this help and exit
  $0 {-v|--version} # 1 line version info and exit
  $0 [-i INPUT_YAML_FILE] [-o OUTPUT_PS_FILE] [-p PARAMETER_STRING]*
    # if -i is missing, reads yaml from stdin
    # if -o is missing, output goes to STDOUT
    # PARAMETER_STRING should be in the format key=value
    #   (any number of key-value pair could be specified, each one needs it's own -p )
  $0 {-d|--debug}   # turns on debug messages EXPERIMENTAL
  $0 --help_plane   # help on plane types and their parameters
  $0 --help_coords  # help on possible coordinate specifications
  
  Input yaml examples are in the 'input' directory.
";
  exit 0;
}

sub HELP_PLANES {
  warn "Possible plane types and their parameters:

  regular: sides (mandatory), angle (optional), size (optional)
    create a centered regular n size plane (like square)
    0th point is the center
  freeform: x1,y1,x2,y2 ... (any number of x,y pairs _and/or_ planeI,J pairs)
  connected: TO_x1,TO_y1,TO_x2,TO_y2,plane-to-connect,nth1,nth2
    (TO_x1,TO_y1) and (TO_x2,TO_y2) could be in (planeI,J) format
    two points of 'plane_to_connect' (the nth1 and nth2 ones)
      will be connected to given points 
    all parameters are mandatory
  angle: one mandatory parameter: angle in degrees (where 360 degrees is full circle)
    returns 3 points: 0,0  1,0  cos(angle),sin(angle)
  grid: regular triangles; two mandatory options: sizeX, sizeY
    result will look like when sizeX is 3, sizeY is 4:

    400   401   402   403
       300   301   302   303
    200   201   202   203
       100   101   102   103
    000   001   002   003

  circle: create a series of planes around a 'circle'
    parameters: plane-to-spin (mandatory), nth1 (mandatory), nth2 (mandatory), 
               circle_sides (mandatory), circle_initial_angle (optional), circle_size (optional)
    freshly created plane names will be planes-to-spin_01 and so on
  smaller: create a series of planes from an original one, a gravity center, magnitude and iterations count
  condensed: when you like to create the same nets but different side parameters (see examples in _test.yaml)
";
  exit 0
}

sub HELP_COORDS {
  warn "Possible coordinate specifications for one point:
    X;Y
      where both X and Y are numbers representing the X and Y coordinate
    P;I
      P is a plane name (defined already in the same yaml)
      I is the index (which point to get; starts with zero)
    *A1,A2,B1,B2,W
      remember to use commas not semicolons; leading '*' is mandatory ! no space, tab or enter please !
      A1,A2 are either numbers (direct) or Plane,Index pair (indirect)
      B1,B2 works the same way
      the point will be on the line A1,A2 - B1,B2
      W is the weight, always specified by a number
      when W is zero the point is A1,A2
      when W is one the point is B1,B2
      when W is 0.5 you got the point halfway between A1,A2 - B1,B2
      W could be outside '0 - 1' range
";
  exit 0
}


GetOptions(
    'input|i=s' => \$opts_input,
    'output|o=s' => \$opts_output,
    'param|p=s' => \%TP_PARAMS,
    'help|h|?' => \$opts_help,
    'help_plane' => \$opts_help_plane,
    'help_coords' => \$opts_help_coords,
    'version|v' => \$opts_version,
    'debug|d' => \$opts_debug,
);

if ($opts_debug) { warn "CMD params are:\n"; warnhash %TP_PARAMS; }

if ($opts_help) {HELP_MESSAGE;}
if ($opts_help_plane) {HELP_PLANES;}
if ($opts_help_coords) {HELP_COORDS;}
if ($opts_version) {VERSION_MESSAGE;}

# read from yaml file (specified by '-i' switch) _or_ STDIN
my $fh;
if ( $opts_input =~ /stdin/i ) { $fh=*STDIN; }
else {open $fh, '<', $opts_input or die "can't open yaml file: $!";}

# convert YAML file to %config
my $config = LoadFile($fh); # from YAML::XS module
close($fh);

# all output goes to file (specified by '-o' switch) _or_ STDOUT
if ( $opts_output !~ /stdout/i ) { open $fh, '>', $opts_output or die "can't open output file for writing: $!"; select $fh}

if ($opts_debug) {use Data::Dumper; warn "Full input structure ---[BEGIN]---\n"; warn Dumper($config), "\n"; warn "Full input structure ---[END]---\n\n";}

# command line options processing have to be AFTER global parameters processed
# priority is (lowest to highest):
#   - defaults (set in global_init) %TP_GLOBAL
#   - environment variables start with TP_ (also set in global_init) %TP_GLOBAL
#   - global parameters from yaml file (scroll down ~9 lines) %TP_GLOBAL
#   - "local" parameters for each net stored in %TP_ALL one-by-one
#   - options specified with -p (set in GetOptions) %TP_PARAMS
# priority is a WiP

global_init;

for my $AK (keys %{$config->{global}}) {
  $TP_GLOBAL{$AK}=$config->{global}->{$AK}; # Always overwrite values defined as defaults or by environment variables
  # if ($opts_debug) { warn "TP_GLOBAL{$AK} => $TP_GLOBAL{$AK}\n";} # These are written with Data::Dumper ~17 lines earlier ...
}

print_ps_filestart();

if ($TP_PARAMS{BW}) {$TP_GLOBAL{BW}=1;} # Being black'n'white is global: even all pages are BW or not

# define a list of colors creating a gradient
for my $k ( grep { $_ =~ /^colorgradient/i } keys %TP_GLOBAL ) {
  my @A=split(';',$TP_GLOBAL{$k});
  while (my ($namebase,$gradientcount,$startcolor,$endcolor)=splice @A,0,4 ) { ; # mandatory options: namebase, gradient count, start color, end color
    my @startcolor=split(' ',colorconvert($startcolor));
    my @endcolor=  split(' ',colorconvert($endcolor));
    for (0 .. $gradientcount) {my $i=$_; my $g=$i/$gradientcount;
      $TP_colors{sprintf("%s_%02d",$namebase,$i)}=sprintf("%f %f %f",weight($startcolor[0],$endcolor[0],$g),weight($startcolor[1],$endcolor[1],$g),weight($startcolor[2],$endcolor[2],$g));
    }
  }
}

# process possible definecolor(s)
for my $k ( grep { $_ =~ /^definecolor/i } keys %TP_GLOBAL ) {
    my @my_colors=split(';',$TP_GLOBAL{$k}) ;
    while (@my_colors) { my ($i,$v)=(shift @my_colors, shift @my_colors);  $TP_colors{$i}=colorconvert($v)}
}

# define a list of colors; creates a list like colorgradient but colors are defined freeform
for my $k ( grep { $_ =~ /^colorarray/i } keys %TP_GLOBAL ) {
  my @A=split(';',$TP_GLOBAL{$k}); my $i=0; my $namebase=splice @A,0,1 ;
  while (my $l=splice @A,0,1) { $TP_colors{sprintf("%s_%02d",$namebase,$i++)} = colorconvert($l); }
}


#if ($TP_PARAMS{definecolor}) {
#  my @my_colors=split(';',$TP_PARAMS{definecolor}) ;
#}

if ($opts_debug) {  warn "Colors data (including predefined ones)\n" ;
  for my $i (keys %TP_colors) { warn "color name: '",$i,"' value: $TP_colors{$i}\n"; }
  warn "\n";
}

# read planes data
if (defined $config->{planes}) {
  for (0 .. @{$config->{planes}}-1) {
    my @AP1=split(';',$config->{planes}[$_]); # @AP like ActualPlane
    my $planename=splice @AP1,0,1;
    my @AP;
#    my @AP=@AP1;
    while (@AP1) {push(@AP,percent_on_line(splice(@AP1,0,1)));}

    
    if ( $planename !~ /^[a-z]/i ) { warn "Invalid plane name: $planename (should start with a letter), skipped\n"; next;} ;
    switch (splice @AP,0,1) {
      case (/^r/i){ # regular: sides (mandatory), angle (optional), size (optional)
        my @w=basicplane(@AP); $TP_planes{$planename}=\@w;
      }
      case (/^f/i){ # freeform: x1,y1,x2,y2 ... (any number of x,y pairs _and/or_ planeI,J pairs)
        @AP=pointsfromplanesordirect(@AP); $TP_planes{$planename}=\@AP;
      }
      case (/^co/i){ # connected:
        # @AP should be : $TOx1,$TOy1,$TOx2,$TOy2,plane-to-connect,nth1,nth2
        $TP_planes{$planename}=create_connected_plane(@AP);
      }
      case (/^gr/i){ # grid for triangles; two mandatory options: sizeX, sizeY
        my @w=grid3plane(@AP); $TP_planes{$planename}=\@w;
      }
      case (/^4/i){ # grid for squares; two mandatory options: sizeX, sizeY
        my @w=grid4plane(@AP); $TP_planes{$planename}=\@w;
      }
      case (/^sm/i){ # smaller: create a series from points , gravity point and magnification
        my $iterations=splice @AP,0,1;
	      for my $i (1..$iterations) {
          my @w=smaller_plane_1($i,@AP);
          $TP_planes{sprintf("%s_%02d",$planename,$i)}=\@w;
  	    }
      }
      case (/^a/i){ # angle: one mandatory option: angle in degrees (one full circle is 360 degrees)
        my $angle=$AP[0]/180*pi();
        $TP_planes{$planename}=[0,0,1,0,cos($angle),sin($angle)];
      }
      case (/^ci/i){ # circle: plane-to-spin (mandatory), nth1 (mandatory), nth2 (mandatory), circle_sides (mandatory), circle_initial_angle (optional), circle_size (optional)
	    # create a series of planes around a "circle"; freshly created plane names will be planes-to-spin_01 and so on
	      my ($plane_to_spin, $nth1, $nth2)=@AP;
  	    my @basicplaneinfo=splice @AP,3;  my @mybasicplane=basicplane(@basicplaneinfo);
	      for my $i (1..$basicplaneinfo[0]) { # 1 .. sides
	      my $i1=( $i ==  $basicplaneinfo[0] ? 1 : $i+1);
          $TP_planes{sprintf("%s_%02d",$planename,$i)}=create_connected_plane($mybasicplane[$i*2] , $mybasicplane[$i*2+1], $mybasicplane[$i1*2] , $mybasicplane[$i1*2+1], $plane_to_spin, $nth1, $nth2);
  	    }
      }
      case (/^spin/i){ # spin: plane-to-spin (mandatory), nth1 (mandatory), nth2 (mandatory), circle_sides (mandatory), circle_initial_angle (optional), circle_size (optional)
	      # create a series of planes around a "circle"; freshly created plane names will be planes-to-spin_01 and so on
	      my ($plane_to_spin, $nth1, $nth2)=@AP;
  	    my @basicplaneinfo=splice @AP,3;  my @mybasicplane=basicplane(@basicplaneinfo);
  	    for my $i (1..$basicplaneinfo[0]) { # 1 .. sides
          $TP_planes{sprintf("%s_%02d",$planename,$i)}=create_connected_plane($mybasicplane[0] , $mybasicplane[1], $mybasicplane[$i*2] , $mybasicplane[$i*2+1], $plane_to_spin, $nth1, $nth2);
    	  }
      }
      case (/^ge/i){ # geometric_line; startX, startY, endX, endY, sections, magnitude (for 1 section)
        my @w=geometric_line(@AP); $TP_planes{$planename}=\@w;
      }
      case (/^shiftXY/i){ # shift an already existing plane;  X,Y,original_plane
        my @w=shiftXYplane(@AP);
        $TP_planes{$planename}=\@w;
      }
      else {warn "plane type '$_' is not (yet) supported (but processing goes on)\n";}
    }
  }
  if ($opts_debug) {  warn "Planes data\n" ;
    for my $i (keys %TP_planes) { warn "plane name: '",$i,"' content:\n"; warnarray @{$TP_planes{$i}}; }
  }
}

# process every page
for (0 .. @{$config->{pages}}-1) {
  for (@{$config->{pages}->[$_]}) {
	process_element(split ';');
  }
  draw_all;
}


# print possible ps footer; none by default
