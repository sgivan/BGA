package GENDB::Config;

#
# configure GENDB for KB13 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "KB13 Genome Annotation";
$GENDB_DBSOURCE = "DBI:mysql:KB13_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "KB13";

