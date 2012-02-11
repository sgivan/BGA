package GENDB::Config;

#
# configure GENDB for PU1002 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Pelagibacter ubique HTCC1002";
$GENDB_DBSOURCE = "DBI:mysql:PU1002_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "PU1002";

