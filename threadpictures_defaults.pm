package threadpictures_defaults;
use strict;
use warnings;
use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( $TP_threads );

# TP_threads is how many segment should exist in a net
our $TP_threads=10;

1;

