package GENDB::Config;

#
# configure GENDB for GB5015 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "GB5015 Genome Project";
$GENDB_DBSOURCE = "DBI:mysql:GB5015_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "GB5015";

