package GENDB::Config;

#
# configure GENDB for S1Bgamma project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Chapman Sample 1B";
$GENDB_DBSOURCE = "DBI:mysql:S1Bgamma_gendb:ircf-login-0-1.local";
$GENDB_CONFIG = "S1Bgamma";

