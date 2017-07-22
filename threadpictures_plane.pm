package threadpictures_plane;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( basicplane connectplane2points);

# rotates a vector counterclockwise (left) by angle
# parameter: x,y,angle
# output array: [newx,newy]
sub rotatevector { my ($x,$y,$angle)=@_;
  return (my_round($x*cos($angle)-$y*sin($angle)), my_round($x*sin($angle)+$y*cos($angle)) );
}

sub addvector { my ($x1,$y1,$x2,$y2)=@_; return ($x1+$x2,$y1+$y2); }

sub scalevector { my ($x,$y,$scale)=@_;
  return ($x*$scale,$y*$scale);
}

# moves a whole plane by a vector
sub moveplane { my ($xdiff,$ydiff,@plane)=@_;
  my @output;
  while (@plane) { push @output,addvector(splice(@plane,0,2),$xdiff,$ydiff); }
  return @output;
}

sub rotateplane { my ($angle,@plane)=@_;
  my @output;
  while (@plane) { push @output,rotatevector(splice(@plane,0,2),$angle); }
  return @output;
}

sub scaleplane { my ($scale,@plane)=@_;
  my @output;
  while (@plane) { push @output,scalevector(splice(@plane,0,2),$scale); }
  return @output;
}

# calculates the length and angle of the vector
sub to_polar { my ($x,$y)=@_;
  return (sqrt($x*$x+$y*$y),atan2($y,$x))
}

# creates a basic plane with 0,0 as center and 1,0 as first point
# mandatory parameter: number of sides
# optional parameters: initial angle (first point will be rotated to the left), initial size (instead of 1)
# returns an array of points: [x1,y1,x2,y2,...]
# test call: 
#      warnarray basicplane(4,45,sqrt(2));
# should produce the following output:
#      1,1,-1,1,-1,-1,1,-1
sub basicplane {
  my ($sides,$initialangle,$initialsize)=@_; my $angle=2*pi()/$sides;
  $initialangle//=0; $initialangle=$initialangle/180*pi(); $initialsize//=1;
  my @initialvector=rotatevector($initialsize,0,$initialangle);
  my @plane;
  for my $side (0 .. $sides-1) { push @plane,rotatevector(@initialvector,$side*$angle); }
  return @plane;
}

# transform a plane that way it's nth1 point goes to (x1,y1) and it's nth2 point goes to (x2,y2)
sub connectplane2points { my ($TOx1,$TOy1,$TOx2,$TOy2,$nth1,$nth2,@plane)=@_;
  my @output=@plane;
  my ($nth1x,$nth1y)=@plane[$nth1*2,$nth1*2+1]; # FROM vector BEGIN
  my ($nth2x,$nth2y)=@plane[$nth2*2,$nth2*2+1]; # FROM vector END
  my ($FROMvectorlen,$FROMangle)=to_polar(addvector(scalevector($nth1x,$nth1y,-1),$nth2x,$nth2y)); # warnarray ($FROMvectorlen,$FROMangle/pi()*180);
  my ($TOvectorlen,$TOangle)=to_polar(addvector(-$TOx1,-$TOy1,$TOx2,$TOy2)); # warnarray ($TOvectorlen,my_round $TOangle/pi()*180);
  # move plane so it's nth1 point is 0,0
  @output=moveplane(scalevector($nth1x,$nth1y,-1),@output);
  # rotate the plane that way the nth2 point is in the direction of (x2,y2)-(x1,y1)
  @output=rotateplane($TOangle-$FROMangle,@output);
  # scale the plane so it's distance between nth1 and nth2 points is exactly (x2,y2)-(x1,y1)
  @output=scaleplane($TOvectorlen/$FROMvectorlen,@output);
  # move the plane so nth1 point is (TOx1,TOy1)
  @output=moveplane($TOx1,$TOy1,@output);
  # round all the coordinates
  for my $i (0..$#output) {$output[$i]=my_round($output[$i]);}
  return @output;
}

1;
