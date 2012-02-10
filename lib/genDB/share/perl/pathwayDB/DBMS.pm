package pathwayDB::DBMS;

$VERSION=1.0;

use DBI;

require Exporter;
@ISA = qw{Exporter};
@EXPORT = qw{$pathwayDB_DBH newid};

$pathwayDB_DBH = DBI->connect("DBI:mysql:pathwaydb:pearson.science.oregonstate.local",'genDB_cluster')
#$pathwayDB_DBH = DBI->connect("DBI:mysql:pathwaydb:pearson.cgrb.oregonstate.edu",'genDB_cluster')
    || die "can't connect to database: $!\n";

sub newid {
    my ($table) = @_;
    $pathwayDB_DBH->{AutoCommit} = 0;
    $pathwayDB_DBH->do(qq {
		LOCK pathwayDB_counters
	}) || return(-1);
    my $sth = $pathwayDB_DBH->prepare(qq {
		SELECT val FROM pathwayDB_counters WHERE object='$table'
	});
    $sth->execute;
    my ($curval) = $sth->fetchrow_array;
    $sth->finish;
    $curval++;
    $pathwayDB_DBH->do(qq {
	UPDATE pathwayDB_counters SET val=$curval WHERE object='$table'
	});
    $pathwayDB_DBH->commit;
    $pathwayDB_DBH->{AutoCommit} = 1;
    return($curval);
}
