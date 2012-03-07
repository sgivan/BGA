package GENDB::Config;

#
# configure GENDB for TEST project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "";
$GENDB_DBSOURCE = "DBI:mysql:TEST_gendb:pearson.cgrb.oregonstate.edu";
$GENDB_CONFIG = "TEST";

