package threadpictures_draw;
use strict;
use warnings;
use threadpictures_global;
use threadpictures_plane;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( draw_all process_element);

#To optimize the whole drawing to fit the page, minimum and maximum X and Y has to be determined
our ($TP_minX,$TP_minY,$TP_maxX,$TP_maxY);


sub my_moveto {print( "$_[0] $_[1] moveto ");}
sub my_lineto {print( "$_[0] $_[1] lineto ");}
sub my_stroke {print( "stroke\n");}
sub my_fill {print( "fill \n");}

# sub my_curveto { print( "$_[0] $_[1] moveto $_[2] $_[3] $_[4] $_[5] $_[6] $_[7] curveto ");}
sub my_curveto { print( "$_[0] $_[1] $_[2] $_[3] $_[4] $_[5] curveto ");}

# draw_line waits 4 parameters: StartX, StartY, EndX, EndY
sub draw_line {
  print( "$_[0] $_[1] moveto $_[2] $_[3] lineto stroke\n");
}

# TP_weight returns an array consisting of X,Y coordinates of the weighted point between from and to coordinates; last parameter is the weight
# test: 
#    my ($a,$b)= TP_weight(10,10,20,20,3),"\n" ; print "$a,$b\n";
sub TP_weight {
  my ($fromX,$fromY,$toX,$toY,$weight,$threads)=@_;
  my $fromRate=($threads-$weight)/$threads;
  my $toRate=$weight/$threads;
  return ($fromX*$fromRate+$toX*$toRate,$fromY*$fromRate+$toY*$toRate);
}

# The basic function to add a net
# Parameters: 
#   1st line outer X,Y
#   1st line inner X,Y
#   2nd line inner X,Y
#   2nd line outer X,Y
# 8 parameters altogether
# every parameter pair could be a planename;point
# returns the index of the newly added net
sub add_net4 {
  my (@input)=@_; my @processedinput=pointsfromplanesordirect(@input);

  my ($line1oX,$line1oY,$line1iX,$line1iY,$line2iX,$line2iY,$line2oX,$line2oY)=@processedinput;
  # Let's push the new net at the end of @TP_all array (increasing it's size by one)
  $TP_all[@TP_all] = { type => 'net',
    line1oX => my_round($line1oX), line1oY => my_round($line1oY), line1iX => my_round($line1iX), line1iY => my_round($line1iY),
    line2iX => my_round($line2iX), line2iY => my_round($line2iY), line2oX => my_round($line2oX), line2oY => my_round($line2oY),
    # next lines is not needed as these are the defaults
    # style=> $TP_GLOBAL{style}, threads => $TP_GLOBAL{threads},
    # firstthread => $TP_GLOBAL{firstthread}, lastthread => $TP_GLOBAL{lastthread)==-1?$TP_GLOBAL{threads}:$TP_GLOBAL{lastthread)
  };
  return $#TP_all;
}

sub add_net3 { return add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);}

sub add_net3s { return add_net4($_[0],$_[1],$_[0],$_[2],$_[0],$_[2],$_[0],$_[3]);}

sub add_net4s { return add_net4($_[0],$_[1],$_[0],$_[2],$_[0],$_[3],$_[0],$_[4]);}

sub add_loop {
  my $planename=splice(@_,0,1);
  my $planesides=(scalar @{$TP_planes{$planename}})/2-1;
  my @points=@_;
  my $points_len=@points;
  my @AP; # Additional parameters; none by default

  # Let's decide how much loop parameters we have and how much options we got
  # loop parameters are numbers while first option should start with a digit
  # all options will be given to all nets !
  for (my $i=0;$i<@points;$i++) {
    if ( $points[$i] =~ /^[a-z]/i ) {
      $points_len=$i;
      @AP=splice @points,$i;
      last;
    }
  }
  if ($points_len < 3 ) { warn "loop has only $points_len elements; it needs at least 3 ! Ignored.\n"; return};
  
  for (my $i=0;$i<@points;$i++) {
#    warnarray($planename,$points[(($i)%@points)],$points[(($i+1)%@points)],$points[(($i+2)%@points)]);
    add_net3s($planename,$points[(($i)%$points_len)],$points[(($i+1)%$points_len)],$points[(($i+2)%$points_len)]);
    my @AP1=@AP; while (@AP1) {modify_lastelement(shift @AP1,shift @AP1)}
  }
}

sub add_loop4 {
  my $planename=splice(@_,0,1);
  my $planesides=(scalar @{$TP_planes{$planename}})/2-1;
  my @points=@_;
  my $points_len=@points;
  my @AP; # Additional parameters; none by default

  # Let's decide how much loop parameters we have and how much options we got
  # loop parameters are numbers while first option should start with a letter
  # all options will be given to all nets !
  for (my $i=0;$i<@points;$i++) {
    if ( $points[$i] =~ /^[a-z]/i ) {
      $points_len=$i;
      @AP=splice @points,$i;
      last;
    }
  }
  if ($points_len < 4 ) { warn "loop4 has only $points_len elements; it needs at least 4 ! Ignored.\n"; return};

  for (my $i=0;$i<@points;$i++) {
    add_net4($planename,$points[(($i)%$points_len)],$planename,$points[(($i+1)%$points_len)],$planename,$points[(($i+2)%$points_len)],$planename,$points[(($i+3)%$points_len)]);
    my @AP1=@AP; while (@AP1) {modify_lastelement(shift @AP1,shift @AP1)}
  }
}

sub add_path {
  my (@input)=@_; my ($startX,$startY,$endX,$endY)=pointsfromplanesordirect(splice @input,0,4);
  my %AP; #AP like ActualPath
  
  # if ($opts_debug) { warn "'path' coordinates and then parameters are: \n"; warnarray (($startX,$startY,$endX,$endY)); }
  while (@input) { my ($key, $value)=(shift @input,shift @input); $AP{$key} = $value ;}

  $AP{slices} //= $TP_PARAMS{slices} ;
  $AP{slices} //= $TP_GLOBAL{slices} ;

  $AP{variant} //= $TP_PARAMS{path_variant} ;
  $AP{variant} //= $TP_GLOBAL{path_variant} ;

  # this parameter controls the 'param' style ; 0 is 'out'; 1 is 'stairs'; 0.5 is 'cont'
  $AP{param} //= $TP_PARAMS{path_param} ;
  $AP{param} //= $TP_GLOBAL{path_param} ;
  if ($opts_debug) { warnhash(%AP) ;}
  
  if ($AP{variant} =~ /^out$/i) {$AP{variant}='param' ; $AP{param}=0}
  if ($AP{variant} =~ /^cont/i) {$AP{variant}='param' ; $AP{param}=0.5}
  if ($AP{variant} =~ /^stair$/i) {$AP{variant}='param' ; $AP{param}=1}

  for my $weight (1 .. $AP{slices}-1) {
    ## SS like SliceStart; SM like SliceMiddle; SE like SliceEnd
    my ($SS_x,$SS_y)=TP_weight($startX,$startY,$endX,$endY,$weight-1,$AP{slices});
    my ($SM_x,$SM_y)=TP_weight($startX,$startY,$endX,$endY,$weight,$AP{slices});
    my ($SE_x,$SE_y)=TP_weight($startX,$startY,$endX,$endY,$weight+1,$AP{slices});
    
    my $LR= ($weight & 1 ?  1 : -1); # Left or Right ?

    my $OV_x=$SS_y-$SM_y; my $OV_y=$SM_x-$SS_x; #OV like OrthogonalVector
    my $OV_x2=$OV_x/2; my $OV_y2=$OV_y/2; #Half of the above

    for ($AP{variant}) {
    when (/^param$/i){
      $SM_x+=$LR*$OV_x; $SM_y+=$LR*$OV_y;
      my $C=$AP{param};

      $SS_x-=$LR*$OV_x*$C; $SS_y-=$LR*$OV_y*$C;
      $SM_x-=$LR*$OV_x*$C; $SM_y-=$LR*$OV_y*$C;
      $SE_x-=$LR*$OV_x*$C; $SE_y-=$LR*$OV_y*$C;
      my $temp=$AP{variant}; # add_net3 somehow modifies the value of $AP{variant} ...
      add_net3($SS_x,$SS_y,$SM_x,$SM_y,$SE_x,$SE_y);
      $AP{variant}=$temp;
    }
    when (/^asym/i){
      $SS_x-=$LR*$OV_x2; $SS_y-=$LR*$OV_y2;
      $SM_x+=$LR*$OV_x2; $SM_y+=$LR*$OV_y2;
      $SM_x+=$LR*$OV_x2; $SM_y+=$LR*$OV_y2;
      my $temp=$AP{variant}; # add_net3 somehow modifies the value of $AP{variant} ...
      add_net3($SS_x,$SS_y,$SM_x,$SM_y,$SE_x,$SE_y);
      $AP{variant}=$temp;
    }
    when (/^wide$/i){
      $SS_x-=$LR*$OV_x; $SS_y-=$LR*$OV_y;
      $SM_x+=$LR*$OV_x*2; $SM_y+=$LR*$OV_y*2;
      $SE_x-=$LR*$OV_x; $SE_y-=$LR*$OV_y;
      my $temp=$AP{variant}; # add_net3 somehow modifies the value of $AP{variant} ...
      add_net3($SS_x,$SS_y,$SM_x,$SM_y,$SE_x,$SE_y);
      $AP{variant}=$temp;
    }
    default {warn "path variant $AP{variant} is not (yet) implemented\nSupported ones: out, cont, asym, wide, stair, param\n";return}
    }
  }
  
}

sub add_recursive {
# parameters should include:
#  - plane name : should be already defined
#  - level of recursion: positive integer
#  - which points should be the one we connect FROM (for next level)
#  - which points should be the one we connect TO   (for next level)
#  - nets in plane (just indexes to points like 1,2,3 ; any amount ! )
#  - optional: generic options to all nets ( like style;filledcurve )
#       these options could be mixed up in order with nets
#  - examples:
#      - recursive;r4;4;1;2;0;1;style;filledcurve;1,2,3
#      - recursive;r4;4;1;2;0;1;1,2,3;2,3,4;style;filledcurve
  if ($opts_debug) { warn "Type recursive; parameters are:\n" ; warnarray @_ ; }

  my @AP=@{$TP_planes{splice @_,0,1}} ; # @AP like Actual Plane; plane name is needed only to get the plane X,Y info
  my ($level,$fromA,$fromB,$toA,$toB) = splice @_,0,5;

  my @nets; my @options;
  while (@_) {
    my $AE=shift @_;
    if ($AE =~ /^[0-9]/) { push @nets,$AE } # a net is like 1,2,3 (one field)
    else { push @options, $AE, shift @_ ; } # an option is like style;curve (two fields)
  }
  for my $i (1..$level) { # Recursivity level is counted from one, we are humans :)
    my @AN=@nets;
    while (@AN) { # add nets based on @AP; add optional parameters, too
      my @AO=@options;
      my ($F,$M,$L)=split(",",splice(@AN,0,1)); # First,Middle,Last point
      add_net3(@AP[2*$F],@AP[2*$F+1],@AP[2*$M],@AP[2*$M+1],@AP[2*$L],@AP[2*$L+1]);
      while (@AO) {modify_lastelement(shift @AO,shift @AO)}
    }
    # calculate new @AP
    # connectplane2points($TOx1,$TOy1,$TOx2,$TOy2,$nth1,$nth2,@plane)
    @AP=connectplane2points(@AP[2*$toA],@AP[2*$toA+1],@AP[2*$toB],@AP[2*$toB+1],$fromA,$fromB,@AP)
  }
}

sub add_circular {
  my @E=@_; # warn "Element circular input: \n"; warnarray @E; warn "\n"; # AP like Element
  my ($from,$to)=splice @E,0,2;
  for my $i ($from .. $to) { my $I=sprintf("%02d",$i);
    my @AE; # AE like ActualElement
	for my $j (0 .. $#E) { push @AE, $E[$j] =~ s/{}/$I/r; } # warnarray @AE;
	process_element(@AE);
  }
}

# To draw one element of the 'net' type
sub draw_net {
  my (%AN)=@_; # AN like Actual Net
  $AN{threads} //= $TP_GLOBAL{threads}; if ($TP_PARAMS{threads}) {$AN{threads}=$TP_PARAMS{threads};}
  $AN{firstthread} //= $TP_GLOBAL{firstthread}; if ($TP_PARAMS{firstthread}) {$AN{firstthread}=$TP_PARAMS{firstthread};}
  $AN{lastthread} //= $TP_GLOBAL{lastthread}; if ($TP_PARAMS{lastthread}) {$AN{lastthread}=$TP_PARAMS{lastthread};}
  $AN{firstthread} //= 0;
  $AN{lastthread} //= $AN{threads};
  $AN{style}//=$TP_GLOBAL{style}; if ($TP_PARAMS{style}) {$AN{style}=$TP_PARAMS{style};}
  $AN{color} //= $TP_GLOBAL{color}; if ($TP_PARAMS{color}) {$AN{color}=$TP_PARAMS{color}} ; $AN{color}=colorconvert($AN{color});
  if (! $TP_GLOBAL{BW} and $AN{color} ne $TP_GLOBAL{lastcolor} ) { say "$AN{color} setrgbcolor\n"; $TP_GLOBAL{lastcolor}=$AN{color}}

  $AN{moon1}//=$TP_GLOBAL{moon1}; if ($TP_PARAMS{moon1}) {$AN{moon1}=$TP_PARAMS{moon1};}
  $AN{moon2}//=$TP_GLOBAL{moon2}; if ($TP_PARAMS{moon2}) {$AN{moon2}=$TP_PARAMS{moon2};}

  { # Handling shiftX and shiftY parameters for a net
    no warnings 'uninitialized';
    ($AN{line1oX},$AN{line1iX},$AN{line2oX},$AN{line2iX})=($AN{line1oX}+$AN{shiftX},$AN{line1iX}+$AN{shiftX},$AN{line2oX}+$AN{shiftX},$AN{line2iX}+$AN{shiftX});
    ($AN{line1oY},$AN{line1iY},$AN{line2oY},$AN{line2iY})=($AN{line1oY}+$AN{shiftY},$AN{line1iY}+$AN{shiftY},$AN{line2oY}+$AN{shiftY},$AN{line2iY}+$AN{shiftY});
  }

  if ($TP_GLOBAL{xymirror}) {
    ($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY}) = ($AN{line1oY},$AN{line1oX},$AN{line1iY},$AN{line1iX}) ;
    ($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY}) = ($AN{line2oY},$AN{line2oX},$AN{line2iY},$AN{line2iX}) ;
  }

  for ($AN{'style'}) { # if ($opts_debug) { warn 'AN style: ',$AN{'style'},"\n";}
  when (/^normal$/i){ # old style was 0
    for my $weight ($AN{'firstthread'} .. $AN{'lastthread'}) {
      # my ($fromX,$fromY,$toX,$toY);
      #($fromX,$fromY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight);
      #($toX,$toY)    =TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight); draw_line($fromX,$fromY,$toX,$toY);
      draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads}),TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight,$AN{threads}));
	}
  }
  when (/^holes$/i) { # old style was 1
    # This kind is NOT interested in the value of firstthread, lastthread
    # Cross lines are 1/20 of the full length of the line EXCEPT if threads<6 then they are 1/10
    my $laddersize = $AN{'threads'} < 6 ? 10 : 20;
    my ($firstX,$firstY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},1,$laddersize);
    my ($line1vectorX,$line1vectorY) = ($firstY-$AN{line1oY}, $AN{line1oX}-$firstX);
    ($firstX,$firstY)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},1,$laddersize);
    my ($line2vectorX,$line2vectorY) = ($firstY-$AN{line2oY}, $AN{line2oX}-$firstX);

    draw_line($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY});
    draw_line($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY});

    for my $weight (0 .. $AN{'threads'}) {
      my ($X,$Y);
      ($X,$Y)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads});
      draw_line($X+$line1vectorX,$Y+$line1vectorY,$X-$line1vectorX,$Y-$line1vectorY);
      ($X,$Y)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$weight,$AN{threads});
      draw_line($X+$line2vectorX,$Y+$line2vectorY,$X-$line2vectorX,$Y-$line2vectorY);
    }
  }
  when (/^border$/i) { # old style was 4
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    draw_line($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY});
    draw_line($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY});
  }
  when (/^triangle$/i) { # old style was 8
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line2oX},$AN{line2oY});
    my_lineto($AN{line2iX},$AN{line2iY});
    if ($AN{line1iX} != $AN{line2iX} or $AN{line1iY} != $AN{line2iY} ) {my_lineto($AN{line1iX},$AN{line1iY});}
    my_lineto($AN{line1oX},$AN{line1oY});
    my_lineto($AN{line2oX},$AN{line2oY}); my_stroke;
  }
  when (/^filledtriangle$/i) { # old style was 7
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line2oX},$AN{line2oY});
    my_lineto($AN{line2iX},$AN{line2iY});
    if ($AN{line1iX} != $AN{line2iX} or $AN{line1iY} != $AN{line2iY} ) {my_lineto($AN{line1iX},$AN{line1iY});}
    my_lineto($AN{line1oX},$AN{line1oY});
    my_lineto($AN{line2oX},$AN{line2oY}); my_fill; my_stroke;
  }
  when (/^curve$/i) { # old style was 9, originally added on 20030312
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line1oX},$AN{line1oY});
    my_curveto(
      TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},2,3),
      TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},2,3),
      $AN{line2oX},$AN{line2oY}); my_stroke;
  }
  when (/^filledcurve$/i) { # old style was 10
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line2oX},$AN{line2oY});
    my_lineto($AN{line2iX},$AN{line2iY});
    if ($AN{line1iX} != $AN{line2iX} or $AN{line1iY} != $AN{line2iY} ) {my_lineto($AN{line1iX},$AN{line1iY});}
    my_lineto($AN{line1oX},$AN{line1oY});
    my_curveto(
      TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},2,3),
      TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},2,3),
      $AN{line2oX},$AN{line2oY}); my_fill; my_stroke;
  }
  when (/^inversefilledcurve$/i) { # new
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line1oX},$AN{line1oY});
    my_curveto(
      TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},2,3),
      TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},2,3),
      $AN{line2oX},$AN{line2oY}); my_fill; my_stroke;
  }
  when (/^parallel$/i){ # old style was 2
    for my $weight ($AN{'firstthread'} .. $AN{'lastthread'}) {
      draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads}),TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$weight,$AN{threads}));
	}
  }
  when (/^selected$|^[0-9-]/i){ # draw lines like normal, but only selected ones
    # This kind is NOT interested in the value of firstthread, lastthread
     foreach my $weight (split(',',/selected/?$AN{'selection'}:$AN{'style'}))
       {draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads}),TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight,$AN{threads}));}
  }
  when (/^moon$/i) { # added on 20200621; based on style 'curve'
    # This kind is NOT interested in the value of threads, firstthread, lastthread
    my_moveto($AN{line1oX},$AN{line1oY});
    my_curveto(
      TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$AN{moon1},1),
      TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$AN{moon1},1),
      $AN{line2oX},$AN{line2oY});
    my_curveto(
      TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$AN{moon2},1),
      TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$AN{moon2},1),
      $AN{line1oX},$AN{line1oY});
    my_fill; my_stroke;
  }
  default {warn "style $AN{'style'} is not (yet) implemented (but processing goes on)\n";return}
  }
}

# adds/replaces attributes to the last element in TP_all
sub modify_lastelement {
  # @adds contains the new key/value pairs (should contain elements in key1,value1,key2,value2,... order)
  my @adds=@_;
  while (@adds) { my ($key, $value)=(shift @adds,shift @adds); $TP_all[-1]{$key} = $value ;}
}

sub process_element {
  my @AE=@_; # AE like ActualElement
      given (splice @AE,0,1) {
      when (/^net$|^net4$/i){ # first line (startX startY endX endY) ; second line (startX startY endX endY)
        add_net4(splice @AE,0,8);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net3$/i){ # start X and Y; center X and Y; end X and Y
        add_net3(splice @AE,0,6);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net3s$/i){ # plane; first point, center point, last point
        add_net3s(splice @AE,0,4);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^net4s$/i){ # plane; first line start and end point, second  line start and end point
        add_net4s(splice @AE,0,5);
        while (@AE) {modify_lastelement(shift @AE,shift @AE)}
      }
      when (/^loop$/i){ # plane; point list (0th point will not be used from plane !)
        add_loop(@AE); # Provide the whole thing
        # Lot of nets, additional parameters handled inside
      }
      when (/^loop4$/i){ # plane; point list (0th point will not be used from plane !)
        add_loop4(@AE); # Provide the whole thing
        # Lot of nets, additional parameters handled inside
      }
      when (/^pagename$/i){
        $TP_all[@TP_all] = { type => 'pagename', string => splice(@AE,0,1) }
      }
      when (/^background$/i){
        $TP_all[@TP_all] = { type => 'background', color => splice(@AE,0,1) }
      }
      when (/^color$/i){
        $TP_all[@TP_all] = { type => 'color', color => splice(@AE,0,1) }
      }
      when (/^fontcolor$/i){
        $TP_all[@TP_all] = { type => 'fontcolor', color => splice(@AE,0,1) }
      }
      when (/^path$/i){
        add_path(@AE);
      }
      when (/^recursive$/i){
        add_recursive(@AE);
      }
      when (/^circular$/i){
        add_circular(@AE);
      }
      when (/^style$/i){
        $TP_all[@TP_all] = { type => 'style', string => splice(@AE,0,1) }
	    }
      when (/^xymirror$/i){
        $TP_all[@TP_all] = { type => 'xymirror', string => splice(@AE,0,1) }
	    }
      default {warn "element '$_' is not (yet) supported (but processing goes on)\n";}
      }
}

# This is the main function to draw a page from the collected info in @TP_all
sub draw_all {

  if ($opts_debug) { warn "\nStarting to draw page $TP_GLOBAL{pagenumber} \n\n"; }

# if @TP_all is empty, warn and return
  if (not @TP_all) { warn "@TP_all is empty: nothing added so nothing to draw\n"; return; }

  my $pagename=$TP_GLOBAL{pagename};
  my $bg=$TP_GLOBAL{background};
  # $TMP_color is a hack: if there is a color directive for the page we temporarily overwrite $TP_GLOBAL{color}
  my $TMP_color=$TP_GLOBAL{color}; my $TMP_fontcolor=$TP_GLOBAL{fontcolor};
  # same hack for style
  my $TMP_style=$TP_GLOBAL{style};

# find min and max X and Y; get the page name, if set; get background color, if set; get the page-wide color and fontcolor, if set
  my ($minX,$maxX,$minY,$maxY);
  if ($opts_debug) { warn "TP_all elements are:\n"};
  foreach my $ATPAE_ (@TP_all) { # ATPAE stands for Actual TP_all Element
    my %ATPAE=%{$ATPAE_};
    if ($opts_debug) { warnhash %ATPAE };
    for ($ATPAE{'type'}) {
      when (/^net$/) {
        no warnings 'uninitialized';  # Handling shiftX and shiftY parameters for a net; they are default to zero.
        $minX//=$ATPAE{line1oX}+$ATPAE{shiftX}; $maxX//=$ATPAE{line1oX}+$ATPAE{shiftX}; $minY//=$ATPAE{line1oY}+$ATPAE{shiftY}; $maxY//=$ATPAE{line1oY}+$ATPAE{shiftY};
	    ($minX,$maxX)=minmax($minX,$maxX,$ATPAE{line1oX}+$ATPAE{shiftX},$ATPAE{line1iX}+$ATPAE{shiftX},$ATPAE{line2oX}+$ATPAE{shiftX},$ATPAE{line2iX}+$ATPAE{shiftX});
        ($minY,$maxY)=minmax($minY,$maxY,$ATPAE{line1oY}+$ATPAE{shiftY},$ATPAE{line1iY}+$ATPAE{shiftY},$ATPAE{line2oY}+$ATPAE{shiftY},$ATPAE{line2iY}+$ATPAE{shiftY});
      }
      when (/^pagename$/) { $pagename=$ATPAE{string} ;}
      when (/^background$/) { $bg=$ATPAE{color} ;}
      when (/^color$/) { $TP_GLOBAL{color}=$ATPAE{color}}
      when (/^fontcolor$/) { $TP_GLOBAL{fontcolor}=$ATPAE{color}}
      when (/^style$/) { $TP_GLOBAL{style}=$ATPAE{string}}
      when (/^xymirror$/) { $TP_GLOBAL{xymirror}=$ATPAE{string}}
    }
  }
#  if (defined $TP_GLOBAL{xymirror}) { ($minX, $maxX, $minY, $maxY)=($minY, $maxY, $minX, $maxX) }
  if ($TP_GLOBAL{xymirror} ) { ($minX, $maxX, $minY, $maxY)=($minY, $maxY, $minX, $maxX) }
  if (defined $TP_PARAMS{pagename}) {$pagename=$TP_PARAMS{pagename};}
  if (defined $TP_PARAMS{background}) {$bg=$TP_PARAMS{background};} $bg=colorconvert($bg);
  if ($minX == $maxX or $minY == $maxY ) {
    warn "even X or Y minimum and maximum values are the same, can not draw\n";
    exit 1;
  }

# page preface
  say "\n%%Page: \"$TP_GLOBAL{pagenumber}\" $TP_GLOBAL{pagenumber}";
  say "gsave";

  # What is the last color we used ? Page always starts with black
  $TP_GLOBAL{lastcolor}='0 0 0';

  # drawing the background, if needed (white BG is the default, so we do not draw it); also no background in black-and-white mode
  if (! $TP_GLOBAL{BW}  &&  $bg ne '1 1 1') { say "$bg setrgbcolor 0 0 $TP_GLOBAL{pageXsize} $TP_GLOBAL{pageYsize} rectfill stroke 0 0 0 setrgbcolor\n"; }

# Print the pagename before the transformation
  if ($pagename !~ /^\s*$/) { # print pagename only if it contains a non-whitespace character
    say "/Times-Roman 12 selectfont";
    say  $TP_GLOBAL{pageXsize}/2," ",cm(1.5)," moveto";
    if (! $TP_GLOBAL{BW} ) {
      my $fontcolor=$TP_GLOBAL{fontcolor}; if ($TP_PARAMS{fontcolor}) {$fontcolor=$TP_PARAMS{fontcolor}} ; $fontcolor=colorconvert($fontcolor);
      if ($fontcolor ne $TP_GLOBAL{lastcolor}) { say "$fontcolor setrgbcolor\n"; $TP_GLOBAL{lastcolor}=$fontcolor}
    }
    say "($pagename) dup stringwidth pop neg 2 div 0 rmoveto show\n";
    delete $TP_GLOBAL{pagename}; delete $TP_PARAMS{pagename}; # pagename is only for actual page; next page starts with empty name
  }

 # Original PS code to write a multi-line pagename:
 #  1 1 PN length { /i exch def
 #    10.5 cm 2 cm moveto 0 PN length i sub 12 mul rmoveto
 #    PN i nth dup stringwidth pop neg 2 div 0 rmoveto show
 #  } for

# do the page transformation to fit the drawing best
  say(
    ($TP_GLOBAL{pageXsize}-$TP_GLOBAL{rightmargin}+$TP_GLOBAL{leftmargin})/2," ",
    ($TP_GLOBAL{pageYsize}-$TP_GLOBAL{topmargin}+$TP_GLOBAL{bottommargin})/2," translate");
  say(min(
    ($TP_GLOBAL{pageXsize}-$TP_GLOBAL{leftmargin}-$TP_GLOBAL{rightmargin})/($maxX-$minX),
    ($TP_GLOBAL{pageYsize}-$TP_GLOBAL{topmargin}-$TP_GLOBAL{bottommargin})/($maxY-$minY))," dup scale");
  say(($maxX+$minX)/2," neg ",($maxY+$minY)/2," neg translate");

  # iterate over @TP_all to draw every piece
  foreach my $ATPAE (@TP_all) { # ATPAE stands for Actual TP_all Element
    my %ATPAE=%{$ATPAE};
    given ($ATPAE{'type'}) {
      when (/^net$/) { draw_net(%ATPAE); }
      when (/^background$/) { }
      when (/^pagename$/) { }
      when (/^color$/) { }
      when (/^fontcolor$/) { }
      when (/^style$/) { }
      when (/^xymirror$/) { }
	  default {warn "type '$_' not implemented (yet); parameters were:\n".join(", ", map { "$_ => $ATPAE{$_}" } keys %ATPAE)."\n" ;}
    } ;
  }
  $TP_GLOBAL{color}=$TMP_color; $TP_GLOBAL{fontcolor}=$TMP_fontcolor;
  $TP_GLOBAL{style}=$TMP_style;

# page footer
  say "showpage grestore";
  say "%%EndPage: \"$TP_GLOBAL{pagenumber}\" $TP_GLOBAL{pagenumber}";
# prepare for the next page:empty @TP_all and increase page number
  undef @TP_all; $TP_GLOBAL{pagenumber}++;
  delete $TP_GLOBAL{xymirror}; # mirroring is always for one page only
}

1;

