package GENDB::Config;

#
# configure GENDB for ENI-11 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Nitrosomonas europaea ENI-11";
$GENDB_DBSOURCE = "DBI:mysql:ENI-11_gendb:heyzeus.science.oregonstate.local";
$GENDB_CONFIG = "ENI-11";

