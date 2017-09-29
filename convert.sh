#!/bin/bash

path=$1
hemi=$2
surf=$3
parc=$4

mkdir ${path}/3dp
mris_convert ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.asc

#convert ctab to better format

mris_convert --annot ${path}/label/${hemi}.${parc} --parcstats ${path}/3dp/${hemi}.${parc}.24bit.ctab ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.${parc}.asc

#need to paste together the two files to get both vertex/face info and color info since the second mris_convert doesn't output the same format as the first

#now convert that to a wavefile obj file
