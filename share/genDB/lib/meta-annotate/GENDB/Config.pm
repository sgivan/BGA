package GENDB::Config;

#
# configure GENDB for meta-annotate project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG);

$GENDB_CODON = 0;
$GENDB_PROJECT = "Annotation of metagenomic data";
$GENDB_DBSOURCE = "DBI:mysql:meta-annotate_gendb:ircf-login-0-1";
$GENDB_CONFIG = "meta-annotate";

