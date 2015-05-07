#!/bin/bash

export PATH=/home/sgivan/projects/BGA/bin:$PATH
if [[ $1 == "-h" ]]
then
		echo "usage: annotator_bsub.pl <project name>"
		exit
fi
		
for i in `ls -1d ??`
	do
		if [ -d $i ]
		then
			echo $i
			dir=( `/bin/ls -1d $i | sed 's/^0//'` )		
			cd $i
            echo "annotator.pl -G -v -D -T -R -F annotator.out -a '1,2' -p $1 -C C$dir -z > annotator.stdout"
            bsub -J annotate$i "annotator.pl -G -v -D -T -R -F annotator.out -a '1,2' -p $1 -C C$dir -z > annotator.stdout"
            cd ..
        fi
    done


