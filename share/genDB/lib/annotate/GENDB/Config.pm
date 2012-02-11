package GENDB::Config;

#
# configure GENDB for annotate project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "temporary annotation";
$GENDB_DBSOURCE = "DBI:mysql:annotate_gendb:pearson.science.oregonstate.local";
#$GENDB_DBSOURCE = "DBI:mysql:annotate_gendb:pearson.cgrb.oregonstate.edu";
$GENDB_CONFIG = "annotate";

