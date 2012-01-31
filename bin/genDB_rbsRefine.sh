#!/bin/bash
# $Id: genDB_rbsRefine.sh,v 3.1 2007/07/12 17:23:02 givans Exp $
#
if [[ $1 == "-h" ]]
then
		echo "usage:  genDB_rbsRefine.sh <RBS sequence, ie. AGGAG> <GenDB Project Code, ie. PU7211>"
		exit
fi
		
for i in `ls -1`
	do
		if [ -d $i ]
		then
			echo $i
			dir=( `/bin/ls -1d $i | sed 's/^0//'` )		
			cd $i
#			glimmer2 contig.nfa ../model -X -l | get-putative > contig.coord
#      echo "~/dev/glimmer3.02/bin/glimmer3 -l contig.nfa ../model contig"
#			~/dev/glimmer3.02/bin/glimmer3 -l contig.nfa ../model contig
#			rbs_finder.pl contig.nfa contig.coord contig.rbs.coord 30 $1
      echo "rbs_finder.pl contig.nfa contig.predict contig.rbs.coord 30 $1"
			rbs_finder.pl contig.nfa contig.predict contig.rbs.coord 30 $1
#     for glimmer2
#			genDB_orfAdjust.pl -f contig.rbs.coord -p $2 -c C$dir -a -A -v
#     for glimmer3
      echo "genDB_orfAdjust.pl -f contig.rbs.coord -p $2 -c C$dir -a -v"
			genDB_orfAdjust.pl -f contig.rbs.coord -p $2 -c C$dir -a -v
			cd ..
		fi
	done