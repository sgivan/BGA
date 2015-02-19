#!/bin/sh

### configuration area

GENDB_INSTALL_DIR=$HOME/projects/BGA/share/genDB
export PERL5LIB=${GENDB_INSTALL_DIR}/share/perl/GENDB:$PERL5LIB
module load bga

### end of config

CLUSTER_MACHINES=$1

# loop
#for i in $(seq $CLUSTER_MACHINES)# seq command is outdated
for (( i = 1; i <= ${CLUSTER_MACHINES}; i++ ))
do
   
   echo "starting GENDB daemon # $i"
   bsub -J GENDB${i} -o %J.o -e %J.e ${GENDB_INSTALL_DIR}/bin/GENDB_daemon.pl

done

module unload bga

