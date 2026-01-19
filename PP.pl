#!/usr/bin/perl -I .
use strict;
use warnings;
use 5.10.0;
no warnings 'uninitialized';

srand();

my %RA; # RandomArray: named randoms are stored inside

while (my $input = <> ) {
  $input =~ s!ENV\[(\w*?)\]([a-zA-Z0-9_.-]*)!$ENV{$1} // $2!aeg ;
  no warnings 'numeric' ; $input =~ s!RANDOM\[([a-zA-Z][a-zA-Z0-9_-]*?),?([0-9.]*)\]!$ENV{$1} // $RA{$1} // ($RA{$1}=rand($2))!aeg ;
  no warnings 'numeric' ; $input =~ s!RANDOM\[([0-9.]*?)\]!rand($1)!aeg ;
#  print STDERR $input;
  print ($input);
}

exit 0 ;

=pod

Preprocessor
ENV[abc] will be replaced by the value of the env var 'abc'
ENV[abc]def is the same, but: if env var 'abc' is not defined the default value is 'def'.
env var name can contain only [a-zA-Z0-9_]
default value can contain only [a-zA-Z0-9_.-] ; set is expendable but never add the following: ",|;" !

RANDOM[value] will be replaced by a random value
  if value is given, return value is 0<= x < abc
  if not, return value is 0< x < 1

RANDOM[name,value] will be replaced by a random value _and_ stored in the hash %RA with name
  environment variable with same name always overrides
  if the name already got a random, value is discarded
  name has to start with a letter and can contain [a-zA-Z0-9_-]
  value can contain only [0-9.]
