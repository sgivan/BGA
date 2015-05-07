package GENDB::Config;

#
# configure GENDB for PS0106 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Pseudoalteromonas sp. Genome, Chapman Sample 106";
$GENDB_DBSOURCE = "DBI:mysql:PS0106_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PS0106";

