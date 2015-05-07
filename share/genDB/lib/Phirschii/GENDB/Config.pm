package GENDB::Config;

#
# configure GENDB for Phirschii project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Prosthecomicrobium hirschii Genome Assembly";
$GENDB_DBSOURCE = "DBI:mysql:Phirschii_gendb:ircf-login-0-1";
$GENDB_CONFIG = "Phirschii";

