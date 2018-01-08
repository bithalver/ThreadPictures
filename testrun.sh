#!/bin/bash

# One parameter: input yaml file name (in 'input' directory)
# checks every second if input changed, then produces a pdf (to output directory)

# example: 
#    ./testrun.sh 20180104

INPUT=`basename $1 .yaml`

export INPUTFILE=input/$INPUT.yaml;
export OUTPUTFILE=output/$INPUT.pdf;

while sleep 1; do
  if [[ $INPUTFILE -nt $OUTPUTFILE ]]; then
    ./TP -i $INPUTFILE -o test.ps ; ps2pdf test.ps $OUTPUTFILE ; rm test.ps
    echo $OUTPUTFILE made at `date +'%Y %m %d %H:%M:%S'`
  fi
done
