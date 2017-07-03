use strict;
use warnings;
use 5.10.0;

use threadpictures_global;
use threadpictures_draw;

# draw_line(1,2,3,4);

# The 2 tests are:
#    TP_threads=2 perl test.pl   # Output is 2
#    perl test.pl                # Output is 10
# print $TP_threads,"\n";

# print 'length of @TP_all is ',scalar @TP_all,"\n"; # Number of elemets in TP_all

# my $a=add_net4(1,2,3,4,5,6,7,8); # print $TP_all[$a]{'type'},"\n";
# add_net4(1,2,3,4,5,6,7,8);
# add_net3(11,22,33,44,55,66);
# add_net3(1,11,1,1,11,1);
# add_net4(-20,20,0,0,1,1,11,21);$TP_all[-1]{'style'}='holes';
add_net3(2,12,2,2,12,2);# $TP_all[-1]{'style'}='holes';
# print the last element in @TP_all
# my %a = %{$TP_all[scalar(@TP_all)-1]}; foreach my $b (keys %a) {print "$b => $a{$b}\n"}

# Adding a not-yet-known type:
#$TP_all[@TP_all] = {type=>'NotExist', param1=>'blah',param2=>1.23,param3=>4.5,firstthread=>4};
# Adding/modifying a parameters for an already added net:
#$TP_all[-1]{'firstthread'}=3; $TP_all[-1]{'lastthread'}=8;

# print 'length of @TP_all is ',scalar @TP_all,"\n"; # Number of elemets in TP_all
draw_all;
# print 'length of @TP_all is ',scalar @TP_all,"\n"; # Number of elemets in TP_all

# my @a=(2,3,4,9,8,7,1,6,5); my ($b,$c)=minmax(@a); print "$b $c\n";

# my %a=(a=>1, b=>2); sayhash %a; say $a{a}; say $a{'a'};
