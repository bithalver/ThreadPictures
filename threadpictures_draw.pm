package threadpictures_draw;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.10.0;
no warnings 'experimental::smartmatch';

our @ISA= qw( Exporter );
our @EXPORT = qw( draw_all draw_line add_net4 add_net3 );

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
  my ($fromX,$fromY,$toX,$toY,$weight)=@_;
  my $fromRate=($TP_threads-$weight)/$TP_threads;
  my $toRate=$weight/$TP_threads;
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
  $TP_all[@TP_all] = { type => 'net', style=> $TP_style,
    line1oX => $line1oX, line1oY => $line1oY, line1iX => $line1iX, line1iY => $line1iY,
    line2iX => $line2iX, line2iY => $line2iY, line2oX => $line2oX, line2oY => $line2oY,
    threads => $TP_threads
    # ext line is not needed as these are the defaults
    #, firstthread => $TP_firstthread, lastthread => $TP_lastthread==-1?$TP_threads:$TP_lastthread
  };
  return $#TP_all;
}

sub add_net3 {
  return add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);
}

# To draw one element of the 'net' type
sub draw_net {
  my (%AN)=@_; # AN like Actual Net
  $AN{firstthread} //= 0; $AN{lastthread} //= $AN{threads} //= $TP_threads;
  given ($AN{'style'}) {
  when (/^normal$/i){
    for my $weight ($AN{'firstthread'} .. $AN{'lastthread'}) {
      # my ($fromX,$fromY,$toX,$toY);
      #($fromX,$fromY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight);
      #($toX,$toY)    =TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight); draw_line($fromX,$fromY,$toX,$toY);
      draw_line(TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight),TP_weight($AN{line2iX},$AN{line2iY},$AN{line2oX},$AN{line2oY},$weight));
	}
  }
  when (/^holes$/i) {
    my ($firstX,$firstY)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},1);
    my ($line1vectorX,$line1vectorY) = ($firstY-$AN{line1oY}, $AN{line1oX}-$firstX);
    ($firstX,$firstY)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},1);
    my ($line2vectorX,$line2vectorY) = ($firstY-$AN{line2oY}, $AN{line2oX}-$firstX);

    draw_line($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY});
    draw_line($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY});

    for my $weight (1 .. $AN{'threads'}-1) {
      my ($X,$Y);
      ($X,$Y)=TP_weight($AN{line1oX},$AN{line1oY},$AN{line1iX},$AN{line1iY},$weight);
      draw_line($X+$line1vectorX,$Y+$line1vectorY,$X-$line1vectorX,$Y-$line1vectorY);
      ($X,$Y)=TP_weight($AN{line2oX},$AN{line2oY},$AN{line2iX},$AN{line2iY},$weight);
      draw_line($X+$line2vectorX,$Y+$line2vectorY,$X-$line2vectorX,$Y-$line2vectorY);
    }
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

# page preface
say "%%Page: \"$TP_pagenumber\" $TP_pagenumber";
say "gsave";
# find min and max X and Y
  my ($minX,$maxX,$minY,$maxY);

  foreach my $ATPAE_ (@TP_all) { # ATPAE stands for Actual TP_all Element
    my %ATPAE=%{$ATPAE_};
    # sayhash %ATPAE;
    given ($ATPAE{'type'}) {
      when (/^net$/) {
        $minX//=$TP_all[0]{line1oX}; $maxX//=$TP_all[0]{line1oX}; $minY//=$TP_all[0]{line1oY}; $maxY//=$TP_all[0]{line1oY};
	    ($minX,$maxX)=minmax($minX,$maxX,$ATPAE{line1oX},$ATPAE{line1iX},$ATPAE{line2oX},$ATPAE{line2iX});
        ($minY,$maxY)=minmax($minY,$maxY,$ATPAE{line1oY},$ATPAE{line1iY},$ATPAE{line2oY},$ATPAE{line2iY});
      }
    }
  }
  # print "minX is $minX, maxX is $maxX, minY is $minY, maxY is $maxY\n";
  if ($minX == $maxX or $minY == $maxY ) {
    warn "even X or Y minimum or maximum values are the same, can not draw\n";
    return;
  }

# do the page transformation to fit the drawing best

=begin comment

  

  /rr xA4size rightmargin sub def % realright
  /ru yA4size topmargin sub def   % realtop
  /rxhf rr leftmargin add 2 div def   % real x halfpoint
  /ryhf ru bottommargin add 2 div def % real y halfpoint
  /wxhf maxx minx add 2 div def % wanted x halfpoint
  /wyhf maxy miny add 2 div def % wanted y halfpoint
wtf {[rxhf ryhf (translate)] wss } if
  /rxs rr leftmargin sub def % real x size
  /rys ru bottommargin sub def % real y size
  /wxs maxx minx sub def % wanted x size
  /wys maxy miny sub def % wanted y size
  /xscale rxs wxs div def
  /yscale rys wys div def
  /wscale xscale yscale lt {xscale} {yscale} ifelse def
wtf {[wscale (dup) (scale)] wss} if
wtf { [wxhf (neg) wyhf (neg) (translate)] wsl } if

=end comment

=cut


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
say "%%EndPage: \"$TP_pagenumber\" $TP_pagenumber";

# prepare for the next page:empty @TP_all and increase page number
  undef @TP_all; $TP_pagenumber++;
}




1;

