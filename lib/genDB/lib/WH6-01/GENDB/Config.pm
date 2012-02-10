package GENDB::Config;

#
# configure GENDB for WH6-01 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Annotation for WH6 Genome";
$GENDB_DBSOURCE = "DBI:mysql:WH6-01_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "WH6-01";

