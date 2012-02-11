package GENDB::Config;

#
# configure GENDB for R2601 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Roseovarius sp. HTCC2601";
$GENDB_DBSOURCE = "DBI:mysql:R2601_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "R2601";

