package GENDB::Config;

#
# configure GENDB for GB2207 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Gammaproteobacteria sp. HTCC2207";
$GENDB_DBSOURCE = "DBI:mysql:GB2207_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "GB2207";

