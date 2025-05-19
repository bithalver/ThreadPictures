package threadpictures_plane;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( basicplane create_connected_plane connectplane2points grid3plane grid4plane smaller_plane_1 geometric_line shiftXYplane );

# rotates a vector counterclockwise (left) by angle
# parameter: x,y,angle
# output array: [newx,newy]
sub rotatevector { no warnings 'uninitialized'; my ($x,$y,$angle)=@_; 
  return (my_round($x*cos($angle)-$y*sin($angle)), my_round($x*sin($angle)+$y*cos($angle)) );
}

sub addvector { no warnings 'uninitialized'; my ($x1,$y1,$x2,$y2)=@_; return ($x1+$x2,$y1+$y2); }

sub scalevector { no warnings 'uninitialized'; my ($x,$y,$scale)=@_; return ($x*$scale,$y*$scale);
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
  my @plane=(0,0); # The 0th point is the center, always
  for my $side (0 .. $sides-1) { push @plane,rotatevector(@initialvector,$side*$angle); }
  return @plane;
}

sub create_connected_plane { my @AP=@_;
  # @AP should be : $TOx1,$TOy1,$TOx2,$TOy2,plane-to-connect,nth1,nth2
  # ($TOx1,$TOy1) and ($TOx2,$TOy2) could be in (planeI,J) format
  my ($TOx1,$TOy1,$TOx2,$TOy2)=pointsfromplanesordirect(splice @AP,0,4);
  my @P2C=@{$TP_planes{splice(@AP,0,1)}}; # P2C like plane-to-connect
  my ($nth1,$nth2)=splice(@AP,0,2);
  @AP=connectplane2points($TOx1,$TOy1,$TOx2,$TOy2,$nth1,$nth2,@P2C);
  return \@AP;
}

# transform a plane that way it's nth1 point goes to (x1,y1) and it's nth2 point goes to (x2,y2)
sub connectplane2points { my ($TOx1,$TOy1,$TOx2,$TOy2,$nth1,$nth2,@plane)=@_;
  my @output=@plane;
  my ($nth1x,$nth1y)=@plane[$nth1*2,$nth1*2+1]; # FROM vector BEGIN
  my ($nth2x,$nth2y)=@plane[$nth2*2,$nth2*2+1]; # FROM vector END
  my ($FROMvectorlen,$FROMangle)=to_polar(addvector(scalevector($nth1x,$nth1y,-1),$nth2x,$nth2y)); # warnarray ($FROMvectorlen,$FROMangle/pi()*180);
  my ($TOvectorlen,$TOangle)=to_polar(addvector(-$TOx1,-$TOy1,$TOx2,$TOy2));
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

# creates a triangular grid of wanted size
sub grid3plane { my ($sizeX,$sizeY)=@_;
  my @output;
  my $s3=sqrt(3)/2;
  for my $Y (0..$sizeY) {
    for my $X (0..$sizeX) {
      $output[($Y*100+$X)*2]=$X+($Y&1 ? 0.5 : 0);
      $output[($Y*100+$X)*2+1]=$Y*$s3;
    }
  }
  return @output;
}


sub grid4plane { my ($sizeX,$sizeY)=@_;
  my @output;
  for my $Y (0..$sizeY) {
    for my $X (0..$sizeX) {
      $output[($Y*100+$X)*2]=$X;
      $output[($Y*100+$X)*2+1]=$Y;
    }
  }
  return @output;
}

# creates one instance of a series of the original and list of magnified ones
# magnification / reduction will be relative to the gravity center
# rotation is not used by now
sub smaller_plane_1 { my @input=@_;
  my ($iteration,$magnification,$rotation,$centerX,$centerY)=splice @input,0,5;
  my @output;
  ($centerX,$centerY)=pointsfromplanesordirect($centerX,$centerY);
  my @originalplane;
  while (@input) { push @originalplane, pointsfromplanesordirect(splice @input,0,2) }

  my $my_magnification=$magnification**($iteration-1);
  while (@originalplane) {
    push @output, addvector(scalevector(splice(@originalplane,0,2),$my_magnification),scalevector($centerX,$centerY,1-$my_magnification));
  }
  return @output;
}

sub geometric_line { my($slices, $magnitude)=@_;
  my @output;
  # print 1024**(1/5) ; exit 0 ; # output is 4 
  my @sections=(0);
  for my $i (1 .. $slices) {
  my $AM;
    $AM=$magnitude**$i; # Actual Magnitude
    push @sections, $sections[$i-1]+$AM;
  }
#  warnarray @sections;
  for my $i (0 .. $slices) {
    my $AM=$sections[$i]/$sections[$slices] ;
    # push @output,addvector(scalevector($startX, $endX, $AM),scalevector($startY, $endY, 1-$AM));
    push @output,addvector(scalevector(0,1,$AM), 0);
  }
  return @output;
}

sub shiftXYplane { my @input=@_;
  my ($TOx,$TOy)=splice(@input,0,2);
  my @P2M=@{$TP_planes{splice(@input,0,1)}}; # P2M like plane-to-move
  return moveplane($TOx,$TOy,@P2M);
}

1;
