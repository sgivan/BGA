package GENDB::Config;

#
# configure GENDB for RB2150 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Rhodobacterales bacterium HTCC2150";
$GENDB_DBSOURCE = "DBI:mysql:RB2150_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "RB2150";

