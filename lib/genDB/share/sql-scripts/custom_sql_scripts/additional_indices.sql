#
# additional indices to GENDB
#
# these indices are not necessary, but speed up
# the whole system
#
# $Id: additional_indices.sql,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $
#
# $Log: additional_indices.sql,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.2  2002/03/26 14:28:12  blinke
# added indices for orfstate, fact and orf
#
# Revision 1.1  2001/05/30 15:37:40  blinke
# Initial revision
#
# Revision 1.1  2001/05/30 15:34:25  blinke
# Initial revision
#
#

# speed up annotation to orf selects
CREATE INDEX annotation_orf_id_key ON annotation (orf_id);

# speed up fact retrieval
CREATE INDEX fact_orf_id ON fact (orf_id);
CREATE INDEX fact_tool_id ON fact (tool_id);

# speed up links between orfstate and tool/orf
CREATE INDEX orfstate_tool_id ON orfstate (tool_id);
CREATE INDEX orfstate_orf_id ON orfstate (orf_id);

# speed up orf lookup
CREATE INDEX orf_contig_id ON orf (contig_id);