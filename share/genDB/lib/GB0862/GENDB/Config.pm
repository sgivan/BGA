package GENDB::Config;

#
# configure GENDB for GB0862 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "GB0862 Genome Project";
$GENDB_DBSOURCE = "DBI:mysql:GB0862_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "GB0862";

