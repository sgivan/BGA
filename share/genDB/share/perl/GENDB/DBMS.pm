package GENDB::DBMS;

use DBI;

use GENDB::Config;

require Exporter;
@ISA = qw{Exporter};
@EXPORT = qw{$GENDB_DBH newid};

$GENDB_DBH = DBI->connect($GENDB_DBSOURCE,'genDB_cluster')
    || die "can't connect to database: $!";

sub newid {
    my ($table) = @_;
    $GENDB_DBH->do(qq {
		LOCK TABLES GENDB_counters WRITE
	}) || return(-1);
    my $sth = $GENDB_DBH->prepare(qq {
		SELECT val FROM GENDB_counters WHERE object='$table'
	});
    $sth->execute;
    my ($curval) = $sth->fetchrow_array;
    $sth->finish;
    $curval++;
    $GENDB_DBH->do(qq {
	UPDATE GENDB_counters SET val=$curval WHERE object='$table'
	});
    $GENDB_DBH->do(qq {
		UNLOCK TABLES
    }) || return(-1);
    return($curval);
}

sub switch_db {
  my $dbsource = shift;

#  print "\$dbsource = '$dbsource'\n";
  $GENDB_DBH = DBI->connect($dbsource,'genDB_cluster') || die "can't connect to database: $!";

}
