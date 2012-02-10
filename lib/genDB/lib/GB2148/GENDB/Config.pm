package GENDB::Config;

#
# configure GENDB for GB2148 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "HTCC2148 Annotation Project";
$GENDB_DBSOURCE = "DBI:mysql:GB2148_gendb:pearson.science.oregonstate.local";
$GENDB_CONFIG = "GB2148";

