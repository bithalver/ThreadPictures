# ThreadPictures

Under construction !

These files help to generate a very special graphic, which I call ThreadPictures (because I sew mos of them on hard paper with real needle and sewing thread).

If you are interested, all scanned pictures are visible at https://www.dropbox.com/sh/1w6j79di8yzphq6/AADA3nOPkDXy6Ndc15HN8FBLa?dl=0 .

To run:
 - if you are on linux/*nix/cygwin : ./TP -h
 - on any OS: perl ThreadPictures.pl -h

-h (or --help) will print the next text:
(I do not guarantee this README is up-to-date all the time)
----------------
Usage:
  $0 [-i INPUT_YAML_FILE] [-o OUTPUT_PS_FILE]
    # if -i is missing, reads yaml from stdin
    # if -o is missing, output goes to STDOUT
  $0 [-h|--help]      # this help
  $0 {-v|--version}   # 1 line version info
----------------

See attached yaml files for examples.

Requirements:
perl 5.10
  YAML::XS module
  Getopt::Std module
ps2pdf command (part of ghostscript)

Tested with/on:
  windows 7
  cygwin 2.880
  perl 5.22.4
  ghostscript 9.19
  bash and xterm (I do not think their version matter)
