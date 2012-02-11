package GENDB::Config;

#
# configure GENDB for AB2255 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Alphaproteobacterium sp. HTCC2255";
$GENDB_DBSOURCE = "DBI:mysql:AB2255_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "AB2255";

