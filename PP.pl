#!/usr/bin/perl -I .
use strict;
use warnings;
use 5.10.0;
no warnings 'uninitialized';

srand();

my %RA; # RandomArray: named randoms are stored inside

while (my $input = <> ) {
#  print STDERR $input;
  no warnings 'numeric' ; $input =~ s!ENV\[([a-zA-Z][a-zA-Z0-9_-]*),([0-9.\-_ a-zA-Z ,]+)\]!$ENV{$1} // $2!aeg ;
  no warnings 'numeric' ; $input =~ s!RANDOM\[([a-zA-Z][a-zA-Z0-9_-]*),?([0-9.]*)\]!$ENV{$1} // $RA{$1} // ($RA{$1}=int(rand($2) * 10**6) / 10**6)!aeg ;
#  print STDERR $input;
  print ($input);
}

exit 0 ;

=pod

Preprocessor

ENV[abc,def] will be replaced by the value of the env var 'abc', if that ENV var exists, def, otherwise
  both parameters are mandatory
  env var name has to start with a letter and can contain [a-zA-Z0-9_-]
  default value can contain only [0-9.\-_ a-zA-Z ,] ; set is expendable but never add the following: "|;" !

RANDOM[name,value] will be replaced by a random value _and_ stored in the hash %RA with name
  name is mandatory, value is optional
  environment variable with same name always overrides with hihest priority
  if the name already got a random, value is discarded
  generates a random number between 0<= x < value ; if value is omitted, end is '1'
  name has to start with a letter and can contain [a-zA-Z0-9_-]
  value can contain only [0-9.]
