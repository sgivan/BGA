package GENDB::Config;

#
# configure GENDB for WH6 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "WH6 Genome";
$GENDB_DBSOURCE = "DBI:mysql:WH6_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "WH6";

