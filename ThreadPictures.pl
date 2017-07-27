#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use threadpictures_global;
use threadpictures_draw;
use threadpictures_plane;

use YAML::XS 'LoadFile';
use Getopt::Std; $Getopt::Std::STANDARD_HELP_VERSION=1;
my %opts;

# ---[BEGIN] test section
# on final version, the whole section should be commented out / deleted !

# warnarray basicplane(4,45,sqrt(2)); exit 0;

# my @a=(1,2,3,4); warnarray moveplane (1,2,@a); exit 0

# warnarray to_polar(-1,0); exit 0;

# my @a=(1,1,2,1,2,2,1,2);
# my @a=(0,0,1,0,1,1,0,1);
# warnarray @a; warnarray connectplane2points(10,10,10,12,0,2,@a); exit 0;

# warn colorconvert('white'),"\n"; warn colorconvert('black'),"\n"; warn colorconvert('orange'),"\n"; exit 0;

# ---[END] test section


sub VERSION_MESSAGE { warn "ThreadPictures version 1.0\n"; }

sub HELP_MESSAGE { # TODO: meaningful help message
  warn "
Usage:
  $0 [-i INPUT_YAML_FILE] [-o OUTPUT_PS_FILE]
    # if -i is missing, reads yaml from stdin
    # if -o is missing, output goes to STDOUT
  $0 [-h|--help]      # this help
  $0 {-v|--version}   # 1 line version info
\n";
  exit 0;
}

getopts('i:o:hv',\%opts);
# --help and --version handled by getopts automatically like 'h' and 'v'

if ($opts{'h'}) {VERSION_MESSAGE; HELP_MESSAGE;}
if ($opts{'v'}) {VERSION_MESSAGE; exit 0;}

# read from yaml file (specified by '-i' switch) _or_ STDIN
my $fh;
if (! defined $opts{'i'} ) { $fh=*STDIN; }
else {open $fh, '<', $opts{'i'} or die "can't open yaml file: $!";}

# convert YAML file to %config
my $config = LoadFile($fh); # from YAML::XS module
close($fh);

# all output goes to file (specified by '-o' switch) _or_ STDOUT
if (defined $opts{'o'} ) { open $fh, '>', $opts{'o'} or die "can't open output file for writing: $!"; select $fh}

# use Data::Dumper; warn Dumper($config), "\n"; # This line is heavily for testing: prints out the whole structure from yaml

# Do the main thing: process %config to make output
print_ps_filestart();

# read global variables form yaml
for my $AK (keys %{$config->{global}}) {
  # warn "$AK => $config->{global}->{$AK}\n";
  $TP_GLOBAL{$AK}=$config->{global}->{$AK};
}
$TP_GLOBAL{background} = colorconvert($TP_GLOBAL{background});
$TP_GLOBAL{color} = colorconvert($TP_GLOBAL{color});

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
    default {warn "plane type '$_' is not (yet) supported (but processing goes on)\n";}
    }
  }
  # Debug print of planes data
  # for my $i (keys %TP_planes) { warn $i,"\n"; warnarray @{$TP_planes{$i}}; }
}

# process every page
for (0 .. @{$config->{pages}}-1) {
  for (@{$config->{pages}->[$_]}) {
    my @AE=split ';'; # AE like ActualElement
      given (splice @AE,0,1) {
      when (/^net$|^net4$/i){
        add_net4(splice @AE,0,8);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net3$/i){
        add_net3(splice @AE,0,6);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^pagename$/i){
        $TP_GLOBAL{pagename}=splice @AE,0,1
      }
      default {warn "element '$_' is not (yet) supported (but processing goes on)\n";}
      }
  }
  draw_all;
}

# print possible ps footer; none by default
