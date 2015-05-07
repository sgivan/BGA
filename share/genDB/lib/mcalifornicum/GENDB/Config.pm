package GENDB::Config;

#
# configure GENDB for mcalifornicum project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 4;
$GENDB_PROJECT = "Mycoplasma californicum Genome Annotation Project";
$GENDB_DBSOURCE = "DBI:mysql:mcalifornicum_gendb:ircf-login-0-1";
$GENDB_CONFIG = "mcalifornicum";

