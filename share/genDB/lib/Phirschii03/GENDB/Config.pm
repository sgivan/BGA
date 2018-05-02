package GENDB::Config;

#
# configure GENDB for Phirschii03 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Assembly of Phirshcii genome after taxonomy analysis";
$GENDB_DBSOURCE = "DBI:mysql:Phirschii03_gendb:login-0-7";
$GENDB_CONFIG = "Phirschii03";

