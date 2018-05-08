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
    #bsub -n 1 -J GENDB$n -q $queue "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
    #bsub -n 1 -R "rusage[mem=1000]" -J GENDB$n -q $queue "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
    #bsub -o %J.o -e %J.e  -n 1 -R "rusage[mem=5000]" -J GENDB$n -q $queue "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
    #bsub -o %J.o -e %J.e  -n 1 -J GENDB$n -q $queue "/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
    sbatch -o %J.o -e %J.e --mem=20G --ntasks=1 --cpus-per-task=1 -J GENDB$n -p $queue --wrap="/home/sgivan/projects/BGA/share/genDB/bin/GENDB_daemon.pl" 
done

