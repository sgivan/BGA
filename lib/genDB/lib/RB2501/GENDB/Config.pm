package GENDB::Config;

#
# configure GENDB for RB2501 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Robiginitalea biformata HTCC2501";
$GENDB_DBSOURCE = "DBI:mysql:RB2501_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "RB2501";

