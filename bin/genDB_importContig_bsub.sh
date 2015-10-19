#!/bin/bash

export PATH=/home/sgivan/projects/BGA/bin:$PATH
for i in `/bin/ls -1v` 

	do
		integer=$( /bin/ls -d $i | sed 's/^0//' )
		if [ -e $i/contig_$integer ]
		then
            cd $i
			echo "genDB_importContig.pl -f contig_$integer -m model -p $1"
			rslt=$( bsub -J $i -o ${i}.o -e ${i}.e genDB_importContig.pl -f contig_$integer -m ../model -p $1 )
            echo $rslt
			#rslt=$( /opt/openlava-2.2/bin/bsub 'genDB_importContig.pl -f contig_$integer -m ../model -p $1')
            #rm *.detail
			#mv *.predict $i/contig.predict
            cd ..
		fi
	done


