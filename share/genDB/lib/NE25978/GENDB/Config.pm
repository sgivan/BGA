package GENDB::Config;

#
# configure GENDB for NE25978 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Nitrosomas europaea NE25978";
$GENDB_DBSOURCE = "DBI:mysql:NE25978_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "NE25978";

