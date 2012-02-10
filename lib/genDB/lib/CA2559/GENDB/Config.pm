package GENDB::Config;

#
# configure GENDB for CA2559 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Croceibacter atlanticus";
$GENDB_DBSOURCE = "DBI:mysql:CA2559_gendb:littlegac.science.oregonstate.local";
$GENDB_CONFIG = "CA2559";

