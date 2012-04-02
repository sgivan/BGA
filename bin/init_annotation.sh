#!/bin/tcsh
setenv PATH /home/sgivan/projects/BGA/bin:$PATH
long-orfs concat.nfa -g 500 -l -o 30 | get-putative > concat.coord
extract concat.nfa concat.coord > concat.extract
build-icm < concat.extract > orf.00.model
glimmer2 concat.nfa orf.00.model -l -X | get-putative > concat.glimmer.coord
extractSeq.pl -f concat.nfa -F concat.glimmer.coord -o concat_orf30.nfa -p 30 -v
