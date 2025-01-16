#!/usr/bin/perl -I .
use strict;
use warnings;
use 5.10.0;
no warnings 'uninitialized';

while (my $input = <> ) {
  # while ($input =~ s!ENV\[(\S*?)\](\S*)!$ENV{$1} // $2!e) { }
  while ($input =~ s!ENV\[(\w*?)\]([a-zA-Z0-9_.,]*)!$ENV{$1} // $2!e) { }
  print ($input);
}

exit 0 ;

=pod

Preprocessor
ENV[abc] will be replaced by the value of the env var 'abc'
ENV[abc]def is the same, but: if env var 'abc' is not defined the default value is 'def'.
env var name can contain only [a-zA-Z0-9_]
default value can contain only [a-zA-Z0-9_.,]
