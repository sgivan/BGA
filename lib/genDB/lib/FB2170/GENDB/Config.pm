package GENDB::Config;

#
# configure GENDB for FB2170 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Flavobacterium bacteriales HTCC2170";
$GENDB_DBSOURCE = "DBI:mysql:FB2170_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "FB2170";

