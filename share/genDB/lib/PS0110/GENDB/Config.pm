package GENDB::Config;

#
# configure GENDB for PS0110 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Annotation of Chapman Sample 110";
$GENDB_DBSOURCE = "DBI:mysql:PS0110_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PS0110";

