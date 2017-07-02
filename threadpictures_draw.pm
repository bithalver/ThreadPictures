package threadpictures_draw;
use strict;
use warnings;
use threadpictures_global;
use Exporter;
use 5.010;
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
sub add_net4 {
  my ($line1oX,$line1oY,$line1iX,$line1iY,$line2iX,$line2iY,$line2oX,$line2oY)=@_;
  # Let's push the new net at the end of @TP_all array (increasing it's size)
  $TP_all[scalar(@TP_all)] = ['net',$TP_style,$line1oX,$line1oY,$line1iX,$line1iY,$line2iX,$line2iY,$line2oX,$line2oY,$TP_threads,$TP_firstthread,$TP_lastthread==-1?$TP_threads:$TP_lastthread];
}

sub add_net3 {
  add_net4($_[0],$_[1],$_[2],$_[3],$_[2],$_[3],$_[4],$_[5]);
}

# This is the main function to draw a page from @TP_all
sub draw_all {

# page preface
# find min and max X and Y; do the page transformation to fit the drawing best
# iterate over @TP_all
foreach my $ATPAE (@TP_all) { # ATPAE stands for Actual TP_all Element
  my @ATPAE=@{$ATPAE};
  # print join(',',@ATPAE)."\n";
  given ($ATPAE[0]) {
    when (/^net$/) {
	  # print "net\n";
	}
	default {warn "drawing element '$_' not implemented (yet); other parameters were:\n".join(' ',@ATPAE[1..scalar(@ATPAE)-1])."\n" ;}
  } ;
}
# page footer
# empty @TP_all for the possible next page
  undef @TP_all;
}

1;

