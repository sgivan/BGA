package GENDB::Config;

#
# configure GENDB for login-0-7 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "-u";
$GENDB_DBSOURCE = "DBI:mysql:login-0-7_gendb:ircf-login-0-1";
$GENDB_CONFIG = "login-0-7";

