package GENDB::Config;

#
# configure GENDB for PhirschiiUnplaced project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Unplaced contigs >3K of P hirschii genome assembly";
$GENDB_DBSOURCE = "DBI:mysql:PhirschiiUnplaced_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PhirschiiUnplaced";

