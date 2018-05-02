package GENDB::Config;

#
# configure GENDB for PS0111 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Annotation of Chapman Sample 111";
$GENDB_DBSOURCE = "DBI:mysql:PS0111_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PS0111";

