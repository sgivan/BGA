#!/bin/sh
# $Id: remove_daemon_log.sh,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: remove_daemon_log.sh,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.4  2002/03/13 13:11:49  blinke
# rewrote code to clean up all temporary files
#
# Revision 1.3  2002/01/29 16:06:06  blinke
# added path to clusterlist
#
# Revision 1.2  2002/01/29 15:42:47  blinke
# list of cluster machines has been exported to "clusterlist"
#

. /vol/gendb-1.0.5/share/exec/clusterlist

# loop
for i in $CLUSTER_MACHINES
do
	echo cleaning up $i
	rsh $i 'cd /var/tmp; /vol/gnu/bin/find -user blinke -depth -exec rm -rf {} \;'
done
