package threadpictures_draw;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( draw_all draw_line add_net4 add_net3 modify_lastelement );

#To oprimize the whole drawing to fit the page, minimum and maximum X and Y has to be determined
our ($TP_minX,$TP_minY,$TP_maxX,$TP_maxY);

# draw_line waits 4 parameters: StartX, StartY, EndX, EndY
sub draw_line {
  print( "$_[0] $_[1] moveto $_[2] $_[3] lineto stroke\n") ;
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
# returns the index of the newly added net
sub add_net4 {
  my ($line1oX,$line1oY,$line1iX,$line1iY,$line2iX,$line2iY,$line2oX,$line2oY)=@_;
  # Let's push the new net at the end of @TP_all array (increasing it's size)
  $TP_all[@TP_all] = { type => 'net',
    line1oX => $line1oX, line1oY => $line1oY, line1iX => $line1iX, line1iY => $line1iY,
    line2iX => $line2iX, line2iY => $line2iY, line2oX => $line2oX, line2oY => $line2oY,
    # next lines is not needed as these are the defaults
    # style=> $TP_GLOBAL{style}, threads => $TP_GLOBAL{threads},
    # firstthread => $TP_GLOBAL{firstthread}, lastthread => $TP_GLOBAL{lastthread)==-1?$TP_GLOBAL{threads}:$TP_GLOBAL{lastthread)
  };
  return $#TP_all;
}

sub add_net3 {
  return add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);
}

# To draw one element of the 'net' type
sub draw_net {
  my (%AN)=@_; # AN like Actual Net
  # warnhash %AN;
  $AN{threads} //= $TP_GLOBAL{threads};
  $AN{firstthread} //= $TP_GLOBAL{firstthread};
  $AN{lastthread} //= $TP_GLOBAL{lastthread};
  $AN{lastthread} //= $AN{threads};
  given ($AN{'style'}//=$TP_GLOBAL{style}) {
  when (/^normal$/i){
    for my $weight ($AN{'firstthread'} .. $AN{'lastthread'}) {
      # my ($fromX,$fromY,$toX,$toY);
      #($fromX,$fromY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight);
      #($toX,$toY)    =TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight); draw_line($fromX,$fromY,$toX,$toY);
      draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads}),TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight,$AN{threads}));
	}
  }
  when (/^holes$/i) {
    my ($firstX,$firstY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},1,$AN{threads});
    my ($line1vectorX,$line1vectorY) = ($firstY-$AN{line1oY}, $AN{line1oX}-$firstX);
    ($firstX,$firstY)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},1,$AN{threads});
    my ($line2vectorX,$line2vectorY) = ($firstY-$AN{line2oY}, $AN{line2oX}-$firstX);

    draw_line($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY});
    draw_line($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY});

    for my $weight (1 .. $AN{'threads'}-1) {
      my ($X,$Y);
      ($X,$Y)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight,$AN{threads});
      draw_line($X+$line1vectorX,$Y+$line1vectorY,$X-$line1vectorX,$Y-$line1vectorY);
      ($X,$Y)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$weight,$AN{threads});
      draw_line($X+$line2vectorX,$Y+$line2vectorY,$X-$line2vectorX,$Y-$line2vectorY);
    }
  }
  when (/^border$/i) {
    draw_line($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY});
    draw_line($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY});
  }
  default {warn "style $AN{'style'} is not (yet) supported.\n";return}
  }
}

sub fitto1page{
  my ($minX,$maxX,$minY,$maxY)=@_;
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
    # warnhash %ATPAE;
    given ($ATPAE{'type'}) {
      when (/^net$/) {
        $minX//=$TP_all[0]{line1oX}; $maxX//=$TP_all[0]{line1oX}; $minY//=$TP_all[0]{line1oY}; $maxY//=$TP_all[0]{line1oY};
	    ($minX,$maxX)=minmax($minX,$maxX,$ATPAE{line1oX},$ATPAE{line1iX},$ATPAE{line2oX},$ATPAE{line2iX});
        ($minY,$maxY)=minmax($minY,$maxY,$ATPAE{line1oY},$ATPAE{line1iY},$ATPAE{line2oY},$ATPAE{line2iY});
      }
    }
  }
  # warn "minX is $minX, maxX is $maxX, minY is $minY, maxY is $maxY\n";
  if ($minX == $maxX or $minY == $maxY ) {
    warn "even X or Y minimum or maximum values are the same, can not draw\n";
    exit 1;
  }

# page preface
  say "%%Page: \"$TP_GLOBAL{pagenumber}\" $TP_GLOBAL{pagenumber}";
  say "gsave";

# Print the pagename before the transformation - TODO
  # warn $TP_GLOBAL{pagename},"\n"; $TP_GLOBAL{pagename}='';

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
    # print join(',',@ATPAE)."\n";
    given ($ATPAE{'type'}) {
      when (/^net$/) {
	    # print "net\n";
		draw_net(%ATPAE);
    }
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

