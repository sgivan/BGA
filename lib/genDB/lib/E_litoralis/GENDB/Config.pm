package GENDB::Config;

#
# configure GENDB for E_litoralis project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Erythrobacter litoralis";
$GENDB_DBSOURCE = "DBI:mysql:E_litoralis_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "E_litoralis";

