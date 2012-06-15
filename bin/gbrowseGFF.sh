#!/bin/bash
#export PERL5LIB=/home/sgivan/projects/COGDB:/home/sgivan/projects/genDB/share/perl:$PERL5LIB
export PERL5LIB=/home/sgivan/projects/COGDB:/home/sgivan/projects/BGA/share/genDB/share/perl:$PERL5LIB
export PATH=/home/sgivan/projects/BGA/bin:$PATH
echo $PERL5LIB
echo "makeGFF.pl -p $1"
makeGFF.pl -p $1
echo "makeGFF.pl -p $1 -D"
makeGFF.pl -p $1 -D
echo "novelcogGFF.pl -o $1"
novelcogGFF.pl -o $1
echo "novelcogGFF.pl -o $1 -O"
novelcogGFF.pl -o $1 -O
