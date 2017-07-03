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

# TP_weight returns an array consisting of X,Y coordinates of the weighted point between frm and to coordinates; last parameters is the weight
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
    #, firstthread => $TP_firstthread, lastthread => $TP_lastthread==-1?$TP_threads:$TP_lastthread
  };
  return $#TP_all;
}

sub add_net3 {
  return add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);
}

# This is the main function to draw a page from the collected info in @TP_all
sub draw_all {

# if @TP_all is empty, warn and return
  if (not @TP_all) {
    warn '@TP_all is empty: nothing added so nothing to draw'."\n";
    return;
  }

# page preface
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
  print "minX is $minX, maxX is $maxX, minY is $minY, maxY is $maxY\n";

# do the page transformation to fit the drawing best
# iterate over @TP_all to draw every piece
  foreach my $ATPAE (@TP_all) { # ATPAE stands for Actual TP_all Element
    my %ATPAE=%{$ATPAE};
    # print join(',',@ATPAE)."\n";
    given ($ATPAE{'type'}) {
      when (/^net$/) {
	    # print "net\n";
  	}
	  default {warn "type '$_' not implemented (yet); parameters were:\n".join(", ", map { "$_ => $ATPAE{$_}" } keys %ATPAE)."\n" ;}
    } ;
  }
# page footer
# empty @TP_all for the possible next page
  undef @TP_all;
}




1;

