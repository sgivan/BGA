package GENDB::Config;

#
# configure GENDB for xhc-G3 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Xanthomonas XHC (Glimmer3)";
$GENDB_DBSOURCE = "DBI:mysql:xhc-G3_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "xhc-G3";

