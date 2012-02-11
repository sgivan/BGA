package GENDB::Config;

#
# configure GENDB for JNB project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Janibacter HTCC2649";
$GENDB_DBSOURCE = "DBI:mysql:JNB_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "JNB";

