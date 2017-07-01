package threadpictures_global;
use strict;
use warnings;
use Exporter;

our @ISA= qw( Exporter );

our @EXPORT = qw( $TP_threads );

# TP_threads is how many segment should exist in a net
# Could be overwritten with the same name env var
our $TP_threads = $ENV{'TP_threads'} //=10;

1;

