#
# default annotator values
#
# initial version taken from cgdeg_gendb and modified
#
# $Id: annotator_defaults.sql,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $
#
# $Log: annotator_defaults.sql,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.3  2001/12/13 16:01:59  fm
# added tRNAscan-SE
#
# Revision 1.2  2001/06/26 11:28:17  tk
# fixed syntax error
#
# Revision 1.1  2001/05/30 15:45:10  blinke
# Initial revision
#
#

INSERT INTO annotator VALUES ('glimmer','Glimmer ORF finder',0);
INSERT INTO annotator VALUES ('tRNAscan-SE','tRNA finder',1);
## CGRB
INSERT INTO annotator VALUES ('orfAdjust','Adjust ORF START site based upon potential RBS',2);
INSERT INTO annotator VALUES ('orfCoord','Adjust ORF coordinates based upon homologs',3);
INSERT INTO annotator VALUES ('overlapResolve','Resolve overlaps between adjacent ORFs',4);
INSERT INTO annotator VALUES ('auto','auto-annotation',5);

# also the following line is unnessary,
# it is added as a template for further entries...
# remember to increas val according to the number of 
# elements in annotator table.....
update GENDB_counters set val=6 where object='annotator';
