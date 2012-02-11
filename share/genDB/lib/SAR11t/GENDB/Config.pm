package GENDB::Config;

#
# configure GENDB for SAR11t project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "SAR11test";
$GENDB_DBSOURCE = "DBI:mysql:SAR112_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "SAR11t";

