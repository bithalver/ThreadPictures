#!/bin/bash


export NAME=$1

perl ThreadPictures.pl -i input/${NAME}.yaml -o output/${NAME}.ps ; ps2pdf output/${NAME}.ps output/${NAME}.pdf; rm -f output/${NAME}.ps
