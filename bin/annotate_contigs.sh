#!/bin/bash
# $Id: genDB_importContig.sh,v 3.1 2007/07/11 20:51:32 givans Exp $
export PATH=/home/sgivan/projects/BGA/bin:$PATH

project=$1
echo "Annotating contigs for project "$1

if [ "$project" ]
then
    echo "Annotating contigs for project "$1
else
    echo 'must provide a project name'
    exit
fi

for i in `/bin/ls -1v` 
	do
		#echo $i
		integer=$( /bin/ls -d $i | sed 's/^0//' )
		if [ -e $i/contig_$integer ]
		then
			echo "annotator.pl -p $project -a '1,2' -G -g T -v -D -T -R -F C${integer}.out -C C${integer}"
			bsub -J C${integer} annotator.pl -p $project -a '1,2' -G -g T -v -D -T -R -F C${integer}.out -C C${integer}
		fi
	done
