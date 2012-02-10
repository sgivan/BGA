package GENDB::Config;

#
# configure GENDB for LA2155 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Lentisphaera araneosa";
$GENDB_DBSOURCE = "DBI:mysql:LA2155_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "LA2155";

