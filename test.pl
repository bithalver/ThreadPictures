use strict;
use warnings;
use 5.10.0;
no warnings 'experimental::smartmatch';

use threadpictures_global;
use threadpictures_draw;

use YAML::XS 'LoadFile';

# step 1: open file
open my $fh, '<', $ARGV[0] or die "can't open config file: $!";

# step 2: convert YAML file to perl hash ref
my $config = LoadFile($fh);
# use Data::Dumper; warn Dumper($config), "\n"; # This line is heavily for testing: prints out the whole structure from yaml
close($fh);

print_ps_header();

for my $AK (keys %{$config->{global}}) {
  # warn "$AK => $config->{global}->{$AK}\n";
  $TP_GLOBAL{$AK}=$config->{global}->{$AK};
}

for my $AP (0.. @{$config->{pages}}-1) { # AP like ActualPage
  for (@{$config->{pages}->[$AP]}) {
    my @AN=split ','; #warnarray @AN;
      given (splice @AN,0,1) {
      when (/^net$/i){
        add_net4(splice @AN,0,8);
        while (@AN) {modify_lastelement(shift @AN,shift @AN)}
      }
      when (/^pagename$/i){
        $TP_GLOBAL{pagename}=splice @AN,0,1
      }
      default {warn "element '$_' is not (yet) supported\n";}
      }
  }
  draw_all;
}
