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

# process every page
for (0 .. @{$config->{pages}}-1) {
  for (@{$config->{pages}->[$_]}) {
    my @AE=split ';'; # warnarray @AE; # AE like ActualElement
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
