use strict;
use warnings;

use threadpictures_global;
use threadpictures_draw;


# draw_line(1,2,3,4);

# The 2 tests are:
#    TP_threads=2 perl test.pl   # Output is 2
#    perl test.pl                # Output is 10
# print $TP_threads,"\n";

net4(1,2,3,4,5,6,7,8);
foreach my $i (2..9) {print $TP_all[scalar(@TP_all)-1][$i]," ";} print "\n";

net3(11,22,33,44,55,66);
foreach my $i (2..9) {print $TP_all[scalar(@TP_all)-1][$i]," ";} print "\n";

#array of arrays test
#my @blah=(1.2.3);
#$blah[scalar(@blah)]= ['line',5,6];
#print @blah,"\n";
#print $blah[scalar(@blah)-1][0],"\n";
