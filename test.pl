use strict;
use warnings;

use threadpictures_global;
use threadpictures_draw;


# draw_line(1,2,3,4);

# The 2 tests are:
#    TP_threads=2 perl test.pl   # Output is 2
#    perl test.pl                # Output is 10
# print $TP_threads,"\n";

#print scalar @TP_all,"\n"; # Number of elemets in TP_all

add_net4(1,2,3,4,5,6,7,8); # foreach my $i (2..9) {print $TP_all[scalar(@TP_all)-1][$i]," ";} print "\n";
add_net3(11,22,33,44,55,66);

print join(',',@{$TP_all[0]})."\n";                  # Elements of the 1st piece in TP_all
my @a=@{$TP_all[scalar(@TP_all)-1]} ; print join(',',@a)."\n";  # Elements of the last piece in TP_all, copied to a temp array
#print scalar @{$TP_all[scalar(@TP_all)-1]}."\n"; # Length of the last piece in TP_all
#print scalar @TP_all,"\n"; # Number of elemets in TP_all

# Adding a not-yet-known element:
#$TP_all[scalar(@TP_all)] = ['NotExist','blah',1.23,3,4.5];

draw_all;

#array of arrays test
#my @blah=(1.2.3);
#$blah[scalar(@blah)]= ['line',5,6];
#print @blah,"\n";
#print $blah[scalar(@blah)-1][0],"\n";

# exit 3;
