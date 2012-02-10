package GENDB::Config;

#
# configure GENDB for PB2503 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Parvularcula bermudensis HTCC2503";
$GENDB_DBSOURCE = "DBI:mysql:PB2503_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "PB2503";

