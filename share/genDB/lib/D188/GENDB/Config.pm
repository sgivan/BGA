package GENDB::Config;

#
# configure GENDB for D188 project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_CODON $GENDB_PROJECT $GENDB_DBSOURCE $GENDB_CONFIG $USER $PSSWD);

$GENDB_CODON = 0;
$GENDB_PROJECT = "D188 Annotation Project";
$GENDB_DBSOURCE = "DBI:mysql:D188_gendb:lewis2.rnet.missouri.edu;port=53307";
$GENDB_CONFIG = "D188";
$USER = 'genDB_cluster';
$PSSWD = 'microbes';

