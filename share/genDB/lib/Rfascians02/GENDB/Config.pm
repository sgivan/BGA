package GENDB::Config;

#
# configure GENDB for Rfascians02 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Genom Annotations of R. fasicans";
$GENDB_DBSOURCE = "DBI:mysql:Rfascians02_gendb:heyzeus.cgrb.oregonstate.edu";
$GENDB_CONFIG = "Rfascians02";

