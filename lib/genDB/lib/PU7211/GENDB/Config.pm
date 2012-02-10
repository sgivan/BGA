package GENDB::Config;

#
# configure GENDB for PU7211 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "HTCC7211 Genome Project";
$GENDB_DBSOURCE = "DBI:mysql:PU7211_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "PU7211";

