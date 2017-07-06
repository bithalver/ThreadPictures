use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use threadpictures_global;
use threadpictures_draw;

use YAML::XS 'LoadFile';

# step 1: open the yaml file
if ($#ARGV == -1) {die "Please specify the yaml file as parameter !\n";}
open my $fh, '<', $ARGV[0] or die "can't open config file: $!";

# step 2: convert YAML file to perl hash ref
my $config = LoadFile($fh);
# use Data::Dumper; warn Dumper($config), "\n"; # This line is heavily for testing: prints out the whole structure from yaml
close($fh);

print_ps_header();

# read global variables form yaml
for my $AK (keys %{$config->{global}}) {
  # warn "$AK => $config->{global}->{$AK}\n";
  $TP_GLOBAL{$AK}=$config->{global}->{$AK};
}

# process every page
for (0.. @{$config->{pages}}-1) {
  for (@{$config->{pages}->[$_]}) {
    my @AE=split ','; #warnarray @AE; # AE like ActualElement
      given (splice @AE,0,1) {
      when (/^net$/i){
        add_net4(splice @AE,0,8);
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
