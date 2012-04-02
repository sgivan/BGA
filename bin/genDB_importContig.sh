#!/bin/bash
# $Id: genDB_importContig.sh,v 3.1 2007/07/11 20:51:32 givans Exp $
export PATH=/home/sgivan/projects/BGA/bin:$PATH
for i in `/bin/ls -1` 

	do
		#echo $i
		integer=$( /bin/ls -d $i | sed 's/^0//' )
		if [ -e $i/contig_$integer ]
		then
			echo "genDB_importContig.pl -f $i/contig_$integer -m model -p $1"
			genDB_importContig.pl -f $i/contig_$integer -m model -p $1
#			mv *.detail $i/contig.detail
      rm *.detail
			mv *.predict $i/contig.predict
		fi
	done
