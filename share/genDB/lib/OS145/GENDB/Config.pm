package GENDB::Config;

#
# configure GENDB for OS145 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Idiomarina baltica";
$GENDB_DBSOURCE = "DBI:mysql:OS145_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "OS145";

