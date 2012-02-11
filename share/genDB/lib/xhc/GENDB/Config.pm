package GENDB::Config;

#
# configure GENDB for xhc project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Pseudomonas XHC Annotation";
$GENDB_DBSOURCE = "DBI:mysql:xhc_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "xhc";

