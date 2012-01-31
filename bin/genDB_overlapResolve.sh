#!/bin/bash
# $Id$

for i in `ls -1`
	do
		if [ -d $i ]
		then
			echo $i
			dir=( `/bin/ls -1d $i | sed 's/^0//'` )		
			cd $i
			genDB_overlapResolve.pl -p $1 -c C$dir -v | tee overlapResolve.stdout 2>&1
			cd ..
		fi
	done
