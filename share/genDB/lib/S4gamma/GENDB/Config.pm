package GENDB::Config;

#
# configure GENDB for S4gamma project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Chapman Sample 4 Genome Annotation";
$GENDB_DBSOURCE = "DBI:mysql:S4gamma_gendb:ircf-login-0-1";
$GENDB_CONFIG = "S4gamma";

