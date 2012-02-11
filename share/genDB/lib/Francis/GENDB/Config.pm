package GENDB::Config;

#
# configure GENDB for Francis project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Francisella tularensis";
$GENDB_DBSOURCE = "DBI:mysql:Francis_gendb:littlgac.science.oregonstate.local";
$GENDB_CONFIG = "Francis";

