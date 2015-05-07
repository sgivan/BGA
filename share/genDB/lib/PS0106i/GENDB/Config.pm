package GENDB::Config;

#
# configure GENDB for PS0106i project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Chapman Sample 106 Re-annotation";
$GENDB_DBSOURCE = "DBI:mysql:PS0106i_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PS0106i";

