package GENDB::Config;

#
# configure GENDB for RB2654 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Rhodobacterales bacterium HTCC2654";
$GENDB_DBSOURCE = "DBI:mysql:RB2654_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "RB2654";

