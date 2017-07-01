use strict;
use warnings;

use threadpictures_draw;
use threadpictures_global;


draw_line(1,2,3,4);

print $TP_threads,"\n";
# The 2 tests are:
#    TP_threads=2 perl test.pl   # Output is 2
#    perl test.pl                # Output is 10


