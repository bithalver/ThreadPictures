package threadpictures_draw;
use strict;
use warnings;
use threadpictures_global;
use threadpictures_plane;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( draw_all add_net4 add_net3 modify_lastelement add_path );

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
    line1oX => $line1oX, line1oY => $line1oY, line1iX => $line1iX, line1iY => $line1iY,
    line2iX => $line2iX, line2iY => $line2iY, line2oX => $line2oX, line2oY => $line2oY,
    # next lines is not needed as these are the defaults
    # style=> $TP_GLOBAL{style}, threads => $TP_GLOBAL{threads},
    # firstthread => $TP_GLOBAL{firstthread}, lastthread => $TP_GLOBAL{lastthread)==-1?$TP_GLOBAL{threads}:$TP_GLOBAL{lastthread)
  };
  return $#TP_all;
}

sub add_net3 { return add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);}

sub add_path {
  my (@input)=@_; my ($startX,$startY,$endX,$endY)=pointsfromplanesordirect(splice @input,0,4);
  my %AP; #AP like ActualPath
  
  if ($opts_debug) { warn "'path' coordinates and then parameters are: \n"; warnarray (($startX,$startY,$endX,$endY)); }
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

# To draw one element of the 'net' type
sub draw_net {
  my (%AN)=@_; # AN like Actual Net
  # warnhash %AN;
  $AN{threads} //= $TP_GLOBAL{threads};
  $AN{firstthread} //= $TP_GLOBAL{firstthread};
  $AN{lastthread} //= $TP_GLOBAL{lastthread};
  $AN{lastthread} //= $AN{threads};
  $AN{color} //= $TP_GLOBAL{color}; if ($TP_PARAMS{color}) {$AN{color}=$TP_PARAMS{color}} ; $AN{color}=colorconvert($AN{color});
  my $color_changed=0; if (! $TP_GLOBAL{BW} and $AN{color} ne '0,0,0' ) { say "currentrgbcolor\n$AN{color} setrgbcolor\n"; $color_changed=1}
  
  if ($TP_PARAMS{style}) {$AN{'style'}=$TP_PARAMS{style};}
  for ($AN{'style'}//=$TP_GLOBAL{style}) { # warn $AN{'style'},"\n";
  when (/^normal$/i){ # old style was 0
    for my $weight ($AN{'firstthread'} .. $AN{'lastthread'}) {
      # my ($fromX,$fromY,$toX,$toY);
      #($fromX,$fromY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight);
      #($toX,$toY)    =TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight); draw_line($fromX,$fromY,$toX,$toY);
      draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads}),TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight,$AN{threads}));
	}
  }
  when (/^holes$/i) { # old style was 1
    # This kind is interested in the value of firstthread, lastthread
    # Cross lines are 1/20 of the full lenght of the line    
    my ($firstX,$firstY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},1,20);
    my ($line1vectorX,$line1vectorY) = ($firstY-$AN{line1oY}, $AN{line1oX}-$firstX);
    ($firstX,$firstY)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},1,20);
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
  default {warn "style $AN{'style'} is not (yet) implemented\nSupported ones: normal, holes, border, triangle, filledtriangle, curve, filledcurve, inversefilledcurve, parallel, selected\n";return}
  }
  if ($color_changed) {say "setrgbcolor\n"}
}

# This is the main function to draw a page from the collected info in @TP_all
sub draw_all {

# if @TP_all is empty, warn and return
  if (not @TP_all) {
    warn '@TP_all is empty: nothing added so nothing to draw'."\n";
    return;
  }

# find min and max X and Y
  my ($minX,$maxX,$minY,$maxY);
  foreach my $ATPAE_ (@TP_all) { # ATPAE stands for Actual TP_all Element
    my %ATPAE=%{$ATPAE_};
    # if ($opts_debug) { warn "Actual TP_all element is:\n"; warnhash %ATPAE };
    for ($ATPAE{'type'}) {
      when (/^net$/) {
        $minX//=$TP_all[0]{line1oX}; $maxX//=$TP_all[0]{line1oX}; $minY//=$TP_all[0]{line1oY}; $maxY//=$TP_all[0]{line1oY};
	    ($minX,$maxX)=minmax($minX,$maxX,$ATPAE{line1oX},$ATPAE{line1iX},$ATPAE{line2oX},$ATPAE{line2iX});
        ($minY,$maxY)=minmax($minY,$maxY,$ATPAE{line1oY},$ATPAE{line1iY},$ATPAE{line2oY},$ATPAE{line2iY});
      }
    }
  }
  if ($minX == $maxX or $minY == $maxY ) {
    warn "even X or Y minimum or maximum values are the same, can not draw\n";
    exit 1;
  }

# page preface
  say "\n%%Page: \"$TP_GLOBAL{pagenumber}\" $TP_GLOBAL{pagenumber}";
  say "gsave";

  # drawing the background, if needed (white BG is the default, so we do not draw it)
  if (! $TP_GLOBAL{BW}) {
    my $bg=$TP_GLOBAL{background};
    foreach my $ATPAE (@TP_all) { # ATPAE stands for Actual TP_all Element
      my %ATPAE=%{$ATPAE};
      given ($ATPAE{'type'}) { when (/^background$/) { $bg=$ATPAE{'color'} ;} }
    }
    if (defined $TP_PARAMS{background}) {$bg=$TP_PARAMS{background};}

    if ($bg ne '1 1 1') {
      # warn "bg is: $bg\n";
      say "currentrgbcolor\n$bg setrgbcolor\n0 0 $TP_GLOBAL{pageXsize} $TP_GLOBAL{pageYsize} rectfill stroke\nsetrgbcolor\n";
    }
  }

# Print the pagename before the transformation
  if ($TP_GLOBAL{pagename} !~ /^\s*$/) { # print pagename only if it contains a non-whitespace character
    say "/Times-Roman 12 selectfont";
    say  cm(10.5)," ",cm(1.5)," moveto"; my $color_changed=0;
    if (! $TP_GLOBAL{BW} ) {
      my $color=$TP_GLOBAL{color}; if ($TP_PARAMS{color}) {$color=$TP_PARAMS{color}}
      if ($color ne '0 0 0') { say "currentrgbcolor\n$color setrgbcolor\n"; $color_changed=1}
    }
    say "($TP_GLOBAL{pagename}) dup stringwidth pop neg 2 div 0 rmoveto show\n";
    if ($color_changed) { say "setrgbcolor\n"; $color_changed=0;}
    $TP_GLOBAL{pagename}=''; # pagename is only for actual page; next one starts with empty one
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
	  default {warn "type '$_' not implemented (yet); parameters were:\n".join(", ", map { "$_ => $ATPAE{$_}" } keys %ATPAE)."\n" ;}
    } ;
  }
# page footer
  say "showpage grestore";
  say "%%EndPage: \"$TP_GLOBAL{pagenumber}\" $TP_GLOBAL{pagenumber}";
# prepare for the next page:empty @TP_all and increase page number
  undef @TP_all; $TP_GLOBAL{pagenumber}++;
}

# adds/replaces attributes to the last element in TP_all
sub modify_lastelement {
  # @adds contains the new key/value pairs (should contain elements in key1,value1,key2,value2,... order)
  my @adds=@_;
  while (@adds) { my ($key, $value)=(shift @adds,shift @adds); $TP_all[-1]{$key} = $value ;}
}

1;

