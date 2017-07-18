use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use threadpictures_global;
use threadpictures_draw;

use YAML::XS 'LoadFile';
use Getopt::Std; $Getopt::Std::STANDARD_HELP_VERSION=1;
my %opts;

sub VERSION_MESSAGE {
  warn "ThreadPictures version 0.6\n";
}

sub HELP_MESSAGE { # TODO: meaningful help message
  warn "Help goes here\n";
  exit 0;
}

getopts('i:o:hv',\%opts); # TODO: set input and output filenames; open output .ps to write

if ($opts{'h'}) {VERSION_MESSAGE; HELP_MESSAGE;}
if ($opts{'v'}) {VERSION_MESSAGE; exit 0;}

# open the yaml file
# if ($#ARGV == -1) {die "Please specify the yaml file as parameter !\n";}
# open my $fh, '<', $ARGV[0] or die "can't open config file: $!";
if (! defined $opts{'i'}) {die "Please specify mandatory parameter input yaml with -i !\n";}
open my $fh, '<', $opts{'i'} or die "can't open config file: $!";

# convert YAML file to perl hash ref
my $config = LoadFile($fh); # from YAML::XS module
close($fh);

# use Data::Dumper; warn Dumper($config), "\n"; # This line is heavily for testing: prints out the whole structure from yaml

print_ps_header();

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
