#$ -o /home/cgrb/genDB/cluster
#$ -e /home/cgrb/genDB/cluster
#$ -N GENDB 
#$ -S /usr/bin/perl
# $Id: GENDB_daemon.pl,v 1.4 2006/07/13 19:02:47 genDB Exp $
####################################################
#
# GENDB job processing daemon
#
####################################################

use lib '/local/cluster/genDB/share/perl';

use strict 'refs';

use GENDB::GENDB_CONFIG;
use Job;
use Projects;
use POSIX;
use FileHandle;

my $runtool = "$GENDB_INSTALL_DIR/bin/runtool";

my $start_wait_timeout = 10;
my $wait_timeout = 10;

my $hostname=`hostname`;

chomp $hostname;

# start daemon child
# $pid = fork;
$pid = $$;

# end parent process
#exit if $pid;       

die "Cannot fork: $!" unless defined ($pid);

# don't rely on working directory....
chdir ("/");

# create new process group
#POSIX::setsid() or die "Could not start new session: $!";

# close standard filehandles
close (STDOUT);
close (STDERR);
close (STDIN);

# log facilities....

# create new filehandles and dup STDOUT and STDERR
open (LOGOUT, ">/var/tmp/GENDB_daemon.$$.log");
#open (LOGOUT, ">/tmp/GENDB_daemon.log");
autoflush LOGOUT 1;
open (STDOUT, ">&LOGOUT");
autoflush STDOUT 1;
open (STDERR, ">&LOGOUT");
autoflush STDERR 1;

# adjust signal handlers.... 
$time_to_die = 0;

sub signal_handler {
    $time_to_die = 1;
}


$SIG{INT} = $SIG{TERM} = $SIG{HUP} = \&signal_handler;
$SIG{PIPE} = 'IGNORE';

print STDOUT "Daemon started\n";

# start the loop
until($time_to_die) {
  my $ltime = scalar(localtime());
    my $newjob = Job->fetchnextjob();
    if ($newjob != -1) {
	print STDOUT "$ltime:  there is a new job\n";
	print STDOUT "check if we know what to do with this job\n";
	print "project name:  '", $newjob->project_name(), "'\n";
#
#	use methods in modified Projects class
#
	my $projects = Projects->new($newjob->project_name());
	my $perllib = $projects->project_lib($newjob->project_name());
    print STDOUT "\$perllib = '$perllib'\n";
#
#	old way
#
#	my $perllib = Projects::project_lib($newjob->project_name);
#	print "\$perllib = '$perllib'\n";
#	exit();
	if (!defined ($perllib)) {
	    print STDOUT "Unknown project name : ",$newjob->project_name()," !\n";
	    next;
	}
	$newjob->lock($hostname);
	if ($perllib) {
	    $ENV{'PERL5LIB'}=$perllib.":$GENDB_INSTALL_DIR/share/perl";
	}
	else {
	    $ENV{'PERL5LIB'}="/$GENDB_INSTALL_DIR/share/perl";
	}
#	print STDOUT "using perl library location '$ENV{PERLLIB}'\n";
	print STDOUT "Starting runtool for ".$newjob->project_name.", job ".$newjob->job_info."\n";
	# run the job
    print STDOUT "running this command:\n$runtool '" . $newjob->job_info . "'\n";
	my $exitcode = 0xffff & system ($runtool, $newjob->job_info);
	if ($exitcode == 0) {
	    print STDOUT "Job finished\n";
	    $newjob->finish;
	    $newjob->delete;
	    next;
	}
	print STDOUT "Job failed !\n";
	if ($exitcode == 0xff00) {
	    print STDERR "Command $runtool ".$newjob->job_info." failed: $!\n";
	}
	elsif ($exitcode > 0x80) {
	    $exitcode >>= 8;
	    print STDERR "Command $runtool ".$newjob->job_info." got non-zero exit status $exitcode\n";
	}
	else  {
	    print STDERR "Command $runtool ".$newjob->job_info." was finished ";
	    if ($exitcode & 0x80) {
		$exitcode &= 0x80;
		print STDERR "with coredump ";
	    }
	    print "signal $exitcode\n";
	}
    }	
    else {
      print STDOUT "$ltime:  no new job in queue\n";
	$wait_timeout = $start_wait_timeout;
	until($time_to_die) {
	    sleep $wait_timeout;
	    if (Job->fetchnextjob() != -1) {
		last;
	    }
	    # prolong wait_timeout, 2 mins max
	    $wait_timeout *= 2 if ($wait_timeout < 120);
#	    print "waiting for $wait_timeout seconds\n";
	}
    }
}
