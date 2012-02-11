package GENDB::Config;

#
# configure GENDB for GB2080 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Gammaproteobacterium HTCC2080";
$GENDB_DBSOURCE = "DBI:mysql:GB2080_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "GB2080";

