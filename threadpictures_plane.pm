package threadpictures_plane;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( basicplane );

# rotates a vector to counterclockwise (left) by angle
# parameter: x,y,angle
# output: [newx,newy]
sub rotatevector { my ($x,$y,$angle)=@_;
  return (my_round($x*cos($angle)-$y*sin($angle),8), my_round($x*sin($angle)+$y*cos($angle),8) );
}

# creates a basic plane with 0,0 as center and 1,0 as first point
# mandatory parameter: number of sides
# optional parameters: initial angle, initial size
# test call: 
#      warnarray basicplane(4,45,sqrt(2));
# should produce the following output:
#      1,1,-1,1,-1,-1,1,-1
# returns an array of points: [x1,y1,x2,y2,...]
sub basicplane {
  my ($sides,$initialangle,$initialsize)=@_; my $angle=2*pi()/$sides;
  $initialangle//=0; $initialangle=$initialangle/180*pi(); $initialsize//=1;
  my @initialvector=rotatevector($initialsize,0,$initialangle);
  my @plane; my @basicvector=[1,0];
  for my $side (0 .. $sides-1) { push @plane,rotatevector(@initialvector,$side*$angle); }
  return @plane;
}

1;