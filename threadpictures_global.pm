package threadpictures_global;
use strict;
use warnings;
use 5.10.0;

use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( $TP_threads @TP_all $TP_style $TP_pagevisiblename $TP_pagenumber $TP_firstthread $TP_lastthread minmax sayarray sayhash);

# TP_threads is how many segment should exist in a net
# Could be overwritten with the same name env var
our $TP_threads = $ENV{'TP_threads'} //=10;
our $TP_firstthread = $ENV{'TP_firstthread'} //=0;
our $TP_lastthread = $ENV{'TP_lastthread'} //= -1; # -1 is a special flag meaning real last one


# This variable collects everything (including all nets) to be drawn on one page
our @TP_all;

# Which style we draw nets
# 0 is normal: lines
# 1 is holes to make patterns for sewing
# all other positive numbers are future expansion
our $TP_style = $ENV{'TP_style'} //='normal';

# What should be written on the bottom of the page
# Default is not to write anything
our $TP_pagevisiblename = $ENV{'TP_pagevisiblename'} //="";

# Every page has to have a name in PS; it is an incremented number
our $TP_pagenumber = 1;

# Returns an array of two values: the minimum and the maximum of an input numerical array
sub minmax {
  return (sort { $a <=> $b } @_)[0,-1];
}

sub sayarray { say join(',',@_); return @_;}

sub sayhash {my (%a)=@_; say join(", ", map { "$_ => $a{$_}" } keys %a); ;return %a;}

# Print the PS file start
print
"%!PS-Adobe-3.0
%%DocumentData: Clean7Bit
%%EndComments

0 setlinewidth

";

1;
