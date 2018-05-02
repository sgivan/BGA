package GENDB::Config;

#
# configure GENDB for metaTest project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Testing annotation of megenomic contigs";
$GENDB_DBSOURCE = "DBI:mysql:metaTest_gendb:ircf-login-0-1";
$GENDB_CONFIG = "metaTest";

