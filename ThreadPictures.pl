#!/usr/bin/perl -I .
use strict;
use warnings;
use 5.10.0;
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

sub VERSION_MESSAGE { warn "ThreadPictures version 1.1\n"; exit 0}

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

";
  exit 0
}

GetOptions(
    'input|i=s' => \$opts_input,
    'output|o=s' => \$opts_output,
    'param|p=s' => \%TP_PARAMS,
    'help|h|?' => \$opts_help,
    'help_plane' => \$opts_help_plane,
    'version|v' => \$opts_version,
    'debug|d' => \$opts_debug,
);

if ($opts_debug) { warn "CMD params are:\n"; warnhash %TP_PARAMS; }

if ($opts_help) {HELP_MESSAGE;}
if ($opts_help_plane) {HELP_PLANES;}
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

if ($opts_debug) {use Data::Dumper; warn "Full input structure ---[BEGIN]---\n"; warn Dumper($config), "\n"; warn "Full input structure ---[END]---\n";}

# command line options processing have to be AFTER global parameters processed
# priority is (lowest to highest):
#   - defaults (set in global_init) %TP_GLOBAL
#   - environment variables start with TP_ (also set in global_init) %TP_GLOBAL
#   - global parameters from yaml file (scroll down ~9 lines) %TP_GLOBAL
#   - "local" parameters for each net stored in %TP_ALL one-by-one
#   - options specified with -p (set in GetOptions) %TP_PARAMS
# priority is a WiP

global_init;

print_ps_filestart();

for my $AK (keys %{$config->{global}}) {
  $TP_GLOBAL{$AK}=$config->{global}->{$AK}; # Always overwrite values defined as defaults or by environment variables
  # if ($opts_debug) { warn "TP_GLOBAL{$AK} => $TP_GLOBAL{$AK}\n";} # These are written with Data::Dumper ~17 lines earlier ...
}

if ($TP_PARAMS{BW}) {$TP_GLOBAL{BW}=1;} # Being black'n'white is global: even all pages are BW or not

# read planes data
if (defined $config->{planes}) {
  for (0 .. @{$config->{planes}}-1) {
    my @AP=split(';',$config->{planes}[$_]); # @AP like ActualPlane
    my $planename=splice @AP,0,1;
    if ( $planename !~ /^[a-z]/i ) { warn "Invalid plane name: $planename , skipped\n"; next;} ;
    given (splice @AP,0,1) {
    when (/^r/i){ # regular: sides (mandatory), angle (optional), size (optional)
      my @w=basicplane(@AP); $TP_planes{$planename}=\@w;
    }
    when (/^f/i){ # freeform: x1,y1,x2,y2 ... (any number of x,y pairs _and/or_ planeI,J pairs)
      @AP=pointsfromplanesordirect(@AP); $TP_planes{$planename}=\@AP;
    }
    when (/^c/i){ # connected:
      # @AP should be : $TOx1,$TOy1,$TOx2,$TOy2,plane-to-connect,nth1,nth2
      # ($TOx1,$TOy1) and ($TOx2,$TOy2) could be in (planeI,J) format
      my ($TOx1,$TOy1,$TOx2,$TOy2)=pointsfromplanesordirect(splice @AP,0,4);
      my @P2C=@{$TP_planes{splice(@AP,0,1)}}; # P2C like plane-to-connect
      my ($nth1,$nth2)=splice(@AP,0,2);
      @AP=connectplane2points($TOx1,$TOy1,$TOx2,$TOy2,$nth1,$nth2,@P2C); $TP_planes{$planename}=\@AP;
    }
    when (/^g/i){ # grid for triangles; two mandatory options: sizeX, sizeY
      my @w=grid3plane(@AP); $TP_planes{$planename}=\@w;
    }
    when (/^a/i){ # angle: one mandatory option: angle in degrees (one full is 360 degrees)
      my $angle=$AP[0]/180*pi();
      $TP_planes{$planename}=[0,0,1,0,cos($angle),sin($angle)];
    }
    default {warn "plane type '$_' is not (yet) supported (but processing goes on)\n";}
    }
  }
  if ($opts_debug) {  warn "Planes data\n" ;
    for my $i (keys %TP_planes) { warn "plane name: '",$i,"' content:\n"; warnarray @{$TP_planes{$i}}; }
  }
}

# process every page
for (0 .. @{$config->{pages}}-1) {
  for (@{$config->{pages}->[$_]}) {
    my @AE=split ';'; # AE like ActualElement
      given (splice @AE,0,1) {
      when (/^net$|^net4$/i){ # first line (startX startY endX endY) ; second line (startX startY endX endY)
        add_net4(splice @AE,0,8);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net3$/i){ # start X and Y; center X and Y; end X and Y
        add_net3(splice @AE,0,6);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net3s$/i){ # plane; first point, center point, last point
        add_net3s(splice @AE,0,4);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net4s$/i){ # plane; first line start and end point, second  line start and end point
        add_net4s(splice @AE,0,5);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^loop$/i){ # plane; point list (0th point will not be used from plane !)
        add_loop(@AE); # Provide the whole thing
        # Lot of nets, additional parameters handled inside
      }
      when (/^loop4$/i){ # plane; point list (0th point will not be used from plane !)
        add_loop4(@AE); # Provide the whole thing
        # Lot of nets, additional parameters handled inside
      }
      when (/^pagename$/i){
        $TP_all[@TP_all] = { type => 'pagename', string => splice(@AE,0,1) }
      }
      when (/^background$/i){
        $TP_all[@TP_all] = { type => 'background', color => splice(@AE,0,1) }
      }
      when (/^path$/i){
        add_path(@AE);
      }
      when (/^recursive$/i){
        add_recursive(@AE);
      }
      default {warn "element '$_' is not (yet) supported (but processing goes on)\n";}
      }
  }
  draw_all;
}

# print possible ps footer; none by default
