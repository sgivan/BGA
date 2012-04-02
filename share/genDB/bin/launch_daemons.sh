#!/bin/bash

export PATH=/home/sgivan/projects/BGA/share/genDB/bin:$PATH
queue=$2
echo "queue $queue"

daemon_max=$1
echo "launching $daemon_max daemons"

for n in $(seq $daemon_max)
do
    echo "launching GENDB_daemon.pl $n"
    #GENDB_daemon.pl &
    #bsub -n 1 -J GENDB$n -q bioq "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
    bsub -n 1 -J GENDB$n -q $queue "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
done

