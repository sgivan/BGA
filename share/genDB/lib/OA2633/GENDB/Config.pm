package GENDB::Config;

#
# configure GENDB for OA2633 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Oceanicaulis alexandrii HTCC2633";
$GENDB_DBSOURCE = "DBI:mysql:OA2633_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "OA2633";

