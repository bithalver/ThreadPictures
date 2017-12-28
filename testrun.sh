#!/bin/bash

# One parameter: input yaml file
# checks every second if input changed, then produces test.pdf

# example: 
#    ./testrun.sh input/20171119_path.yaml

export INPUTFILE=$1;

while sleep 1; do
  if [[ $INPUTFILE -nt test.pdf ]]; then
    ./TP -i $INPUTFILE -o test.ps ; ps2pdf test.ps test.pdf ; rm test.ps
    echo $INPUTFILE made at `date +'%Y %m %d %H:%M:%S'`
  fi
done
