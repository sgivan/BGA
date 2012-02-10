package GENDB::Config;

#
# configure GENDB for OG2516 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Oceanicola granulosis HTCC2516";
$GENDB_DBSOURCE = "DBI:mysql:OG2516_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "OG2516";

