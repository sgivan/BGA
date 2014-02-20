#!/bin/bash
# $Id: genDB_contigs_setup.sh,v 3.1 2007/07/11 20:50:19 givans Exp $
#

export PATH=/home/sgivan/projects/BGA/bin:$PATH
for file in `ls contig_*`;
	do
		#echo $file;
		dir=$(echo $file | sed 's/contig_//');
		if (( $dir < 10 ))
			then
					dir="0"$dir
		fi
		#echo $dir
		mkdir $dir
		cp $file $dir
		cd $dir
		ln -s $file contig.nfa
		cd ..
		rm $file
	done
ln -sf ../orf.00.model ./model
