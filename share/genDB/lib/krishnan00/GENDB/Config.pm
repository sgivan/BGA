package GENDB::Config;

#
# configure GENDB for krishnan00 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Krishnan bacterial genome";
$GENDB_DBSOURCE = "DBI:mysql:krishnan00_gendb:login-0-7";
$GENDB_CONFIG = "krishnan00";

