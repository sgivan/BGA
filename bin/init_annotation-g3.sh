#!/bin/tcsh
~/dev/glimmer3.02/bin/long-orfs -n -t 1.15 -l concat.nfa concat.coord
~/dev/glimmer3.02/bin/extract -t concat.nfa concat.coord > concat.extract
~/dev/glimmer3.02/bin/build-icm -r orf.00.model < concat.extract
#~/dev/glimmer3.02/bin/glimmer3 -l concat.nfa orf.00.model concat
~/dev/glimmer3.02/bin/glimmer3 --max_olap 30 --gene_len 100 -l concat.nfa orf.00.model concat
extractSeq.pl -f concat.nfa -F concat.predict -o concat_orf30.nfa -p 30 -v -S 2 -E 3
