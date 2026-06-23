#!/bin/sh
set -e
#clang -o gen-data gen-data.c
#./gen-data
./build.sh -c
openFPGALoader -b cmoda7_35t build/cmod_a7/graphics.bit
