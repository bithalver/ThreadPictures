package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( $TP_threads @TP_all $TP_style $TP_pagevisiblename $TP_pagenumber $TP_firstthread $TP_lastthread minmax warnarray warnhash cm %PageSizeMargins min max);

# TP_threads is how many segment should exist in a net
# Could be overwritten with the same name env var
our $TP_threads = $ENV{'TP_threads'} //=10;
our $TP_firstthread = $ENV{'TP_firstthread'} //=0;
our $TP_lastthread = $ENV{'TP_lastthread'} //= -1; # -1 is a special flag meaning real last one

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

sub cm {
  my ($i)=@_; return $i*28.34645;
}

# page defaults, all in cm
our %PageSizeMargins=(
pageXsize => cm($ENV{'TP_pageXsize'}//=21),
pageYsize => cm($ENV{'TP_pageYsize'}//=29.7),

leftmargin => cm($ENV{'TP_leftmargin'}//=2),
rightmargin => cm($ENV{'TP_rightmargin'}//=2),
topmargin => cm($ENV{'TP_topmargin'}//=2.5),
bottommargin => cm($ENV{'TP_bottommargin'}//=2.5),
);
# warnhash(%PageSizeMargins);

# This variable collects everything (including all nets) to be drawn on one page
our @TP_all;

# Which style we draw nets
# possible values: 'normal', 'holes'
# all other stringss are future expansion; you will get a warning on STDERR for using a nonimplemented one
our $TP_style = $ENV{'TP_style'} //='normal';

# What should be written on the bottom of the page
# Default is not to write anything
our $TP_pagevisiblename = $ENV{'TP_pagevisiblename'} //="";

# Every page has to have a name in PS; it is an automatically incremented number
our $TP_pagenumber = 1;

# Returns an array of two values: the minimum and the maximum of an input numerical array
sub minmax { return (sort { $a <=> $b } @_)[0,-1]; }

sub warnarray { say join(',',@_); return @_;}

sub warnhash {my (%a)=@_; warn join(", ", map { "$_ => $a{$_}" } keys %a),"\n"; return %a; }

# Print the PS file start
print
"%!PS-Adobe-3.0
%%DocumentData: Clean7Bit
%%EndComments

<< /PageSize [$PageSizeMargins{pageXsize} $PageSizeMargins{pageYsize}] >> setpagedevice
0 setlinewidth

";

1;
