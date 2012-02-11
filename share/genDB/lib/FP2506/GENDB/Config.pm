package GENDB::Config;

#
# configure GENDB for FP2506 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Fulvimarina pelagi HTCC2506";
$GENDB_DBSOURCE = "DBI:mysql:FP2506_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "FP2506";

