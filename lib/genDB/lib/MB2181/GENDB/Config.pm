package GENDB::Config;

#
# configure GENDB for MB2181 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Methylophilales bacterium";
$GENDB_DBSOURCE = "DBI:mysql:MB2181_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "MB2181";

