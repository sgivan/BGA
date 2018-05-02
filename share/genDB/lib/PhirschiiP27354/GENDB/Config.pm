package GENDB::Config;

#
# configure GENDB for PhirschiiP27354 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Plasmid P27354 in P. hirschii";
$GENDB_DBSOURCE = "DBI:mysql:PhirschiiP27354_gendb:ircf-login-0-1";
$GENDB_CONFIG = "PhirschiiP27354";

