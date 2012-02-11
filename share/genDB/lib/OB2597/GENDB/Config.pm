package GENDB::Config;

#
# configure GENDB for OB2597 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Oceanicola batsensis HTCC2597";
$GENDB_DBSOURCE = "DBI:mysql:OB2597_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "OB2597";

