#!/bin/sh
# $Id: start_daemons.sh,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: start_daemons.sh,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2002/01/29 16:05:58  blinke
# added path to clusterlist
#
# Revision 1.1  2002/01/29 15:42:03  blinke
# Initial revision
#
# Revision 1.1  2000/05/19 16:10:39  blinke
# Initial revision
#

### configuration area

GENDB_INSTALL_DIR=$HOME/projects/BGA/share/genDB

### end of config

# load list of cluster machines

. $GENDB_INSTALL_DIR/share/exec/clusterlist
#. /mnt$ENV{HOME}/projects/BGA/share/sge/cgrb/common/settings.sh
. $HOME/projects/BGA/share/sge/cgrb/common/settings.sh

# loop
for i in $CLUSTER_MACHINES
#for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
do
   
#   rsh $i $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
#   qrsh $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
#   qsub -p -50 $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
#   qsub $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
#   qsub -q pseudo $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
   qsub -q 'pseudo0.q,pseudo' $GENDB_INSTALL_DIR/bin/GENDB_daemon.pl
   echo "started GENDB daemon on host $i"

done
