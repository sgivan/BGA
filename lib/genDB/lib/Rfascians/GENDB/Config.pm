package GENDB::Config;

#
# configure GENDB for Rfascians project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Rhodococcus fascians A44A";
$GENDB_DBSOURCE = "DBI:mysql:Rfascians_gendb:heyzeus.cgrb.oregonstate.edu";
$GENDB_CONFIG = "Rfascians";

