#!/bin/sh

# stop all GENDB daemon running at cluster hosts

# $Id: kill_GENDB_daemons.sh,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: kill_GENDB_daemons.sh,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2002/01/29 16:05:42  blinke
# added path to clusterlist
#
# Revision 1.1  2002/01/29 15:42:11  blinke
# Initial revision
#
### configuration area

# root dir of gendb installation
GENDB_INSTALL_DIR=/local/cluster/genDB

### end of config area
#. $GENDB_INSTALL_DIR/share/exec/clusterlist

# loop
#for i in $CLUSTER_MACHINES
#do
#	echo $i
#	(pid=`rsh $i ps -A | fgrep GENDB_da | awk ' { print $1 } '`
#	 if [ ! -z "$pid" ]
#	 then
#	 	rsh $i kill $pid
#		echo "killed GENDB daemon on host $i"
#	 fi)&
#done
qdel -u genDB
