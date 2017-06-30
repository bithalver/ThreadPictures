package threadpictures_draw;
use strict;
use warnings;
use Exporter;

our @ISA= qw( Exporter );

# our @EXPORT_OK = qw( draw_line );
our @EXPORT = qw( draw_line );

# draw_line waits 4 parameters: StartX, StartY, EndX, EndY
sub draw_line {
  print( "$_[0] $_[1] moveto $_[2] $_[3] lineto stroke\n") ;
}

1;

