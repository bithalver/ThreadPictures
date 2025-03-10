# ThreadPictures 

Under continous construction !

These files help me to generate a very special graphic, which I call ThreadPictures (because I sew most of them on hard paper with real needle and sewing thread).

If you are interested, all scanned pictures are visible at https://www.dropbox.com/sh/1w6j79di8yzphq6/AADA3nOPkDXy6Ndc15HN8FBLa?dl=0 .

New ones will be added to dropbox but also visible on facebook: https://www.facebook.com/bithalver/media_set?set=a.10211902977983338.1073741828.1038051428&type=3

To run:
 - if you are on linux/*nix/cygwin : ./TP -h
 - on any OS: perl ThreadPictures.pl -h

 -h (or --help) will print the help:
(I do not guarantee this README is up-to-date all the time, run the program to get the latest help)
```
Usage:
  ./TP [-h|--help|-?] # this help and exit
  ./TP {-v|--version} # 1 line version info and exit
  ./TP [-i INPUT_YAML_FILE] [-o OUTPUT_PS_FILE] [-p PARAMETER_STRING]*
    # if -i is missing, reads yaml from stdin
    # if -o is missing, output goes to STDOUT
    # PARAMETER_STRING should be in the format key=value
    #   (any number of key-value pair could be specified, each one needs it's own -p )
  ./TP {-d|--debug}   # turns on debug messages EXPERIMENTAL
  ./TP --help_plane   # help on plane types and their parameters
```

See attached yaml files for examples in the 'input' folder.

Requirements:
 - perl 5.10
   - YAML::XS module
   - Switch module
   - Getopt::Long module
   - Data::Dumper (only for debug)
 - ps2pdf command (part of ghostscript): only if you want a pdf output

Tested with/on:
  - windows 7 and 10 using cygwin 2.880, 2.924, 2.932
  - perl 5.22.4, 5.32.1, 5.40.0
  - ghostscript 9.19, 9.56.1, 10.03.1
  - bash and xterm (I do not think their version matter)
