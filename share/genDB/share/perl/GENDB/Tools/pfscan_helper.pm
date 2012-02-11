package pfscan_helper;

# this packages is part of the tool conzept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this packages provideds methods to query and
# access the PROSITE database using pfscan

# these methods should run without any dependencies
# to tool and fact class. all information should
# be provided by parameters

# all methods starting with an underscore are 
# to be considered local methods and shouldn't
# be invoked by external modules
# (why doesn't perl provide a way to hide 
#  methods...... ? )

# $Id: pfscan_helper.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: pfscan_helper.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.2  2001/10/17 15:34:36  agoesman
# *** empty log message ***
#
# Revision 1.1  2001/06/11 15:53:38  agoesman
# Initial revision
#

use GENDB::tool;
use GENDB::fact;
use GENDB::orf;
use GENDB::Common;


######################################################
#
#      configuration area
#
# (did i mention we need a clean config conzept ?)
#
######################################################

$VERSION=0.1;

my $pfscan = "pfscan";

sub run_job {

    # get the tool...
    my $tool = shift @_;

    # decide what to do...
    my $what = shift @_;
    
    # the filenames to use
    my $dirname    = POSIX::tmpnam();

    my $infile     = $dirname."/query";
    my $dbfile;
    my $resultfile = $dirname."/pfscan.output";

    # ok this is mean, but both GENDB::fact and GENDB::orfstate got a
    # orf_id field.....

    my $orf = GENDB::orf->init_id ($what->orf_id);
    

    # create a file for the orf sequence 

    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname !";
    
    # depending on the kind of tool (dna / amino acid input),
    # we need to convert create different file content
    
    create_fasta_file ($infile, $orf->name(), $orf->aasequence());

    # there is no way to extract single entries from PROSITE
    # running pfscan for fact and orfstates is the same code
    # (except state locking etc.)

    if (ref $what eq "GENDB::orfstate") {

        # try to lock the job and bail out, if job
	# is already locked
	if ($what->lock() != 0) {
	    print STDERR "job already locked, bailing out...\n";
	    _remove_dir ($dirname);
	    return;
	}

    }

    # create the command line
    my $cmdline = $tool->command_line($infile);
    $cmdline .= " > $resultfile";
    
    # and now......do it !
    
    system ($cmdline);
    
    open (RESULT, $resultfile);

    if (ref $what eq 'GENDB::orfstate') {

	# pfscan results are single line
	
	# <normalized score> <raw score> pos. <start> <stop> <accession number>|<id> <description>

	while (<RESULT>) {
	    if (($score, $rawscore, $start, $stop, $accession, $id, $description)= /([\d.]+)\s+(\d+) pos.\s+(\d+) -\s+(\d+) ([\w\d]+)\|([\w\d]+) (.+)$/) {
		my $fact=GENDB::fact->create($orf->id);

		if ($fact < 0) {
		    die "can't save fact $fact";
		}
		
		$fact->toolresult($score);

		$fact->description($description);
		if ($start > $stop) {
		    $fact->orffrom($start);
		    $fact->orfto($stop);
		}
		else {
		    $fact->orffrom($stop);
		    $fact->orfto($stop);
		}
		$fact->tool_id($tool->id);
		$fact->dbref($id);
	    }
	}
	$what->finished(); 

	_remove_dir($dirname);
	return 1;
	
    }
    else {

	my $result;
	while (<RESULT>) { $result .= $_; };
	_remove_dir ($dirname);

	return $result;
    }
}

sub _remove_dir {

    my ($dirname) = @_;

    opendir (DIR, $dirname);
    for $file (readdir (DIR)) {
	next if ($file =~ /^(\.|\.\.)$/); # skip pseudo directories . and ..
	if (-d $file) {
	    _remove_dir ($file);
	    rmdir ($file);
	}
	else {
	    unlink ($dirname."/".$file);
	}
    }
    closedir (DIR);
    rmdir ($dirname);

}

sub command_line {
    my ($tool, $queryfile, $dbfile) = @_;

    if ($dbfile) {
	# if a database file name is given,
	# but it into the command line
	return $tool->executable_name." -f $queryfile $dbfile";
    }

    my $dbname = $tool->dbname();
    # the database name doesn't include the .fas prefix....
    # IC IC do we really need the path ??
    return $tool->executable_name." -f $queryfile $dbname";
}

sub score {
    my ($fact) = @_;
    return $fact->toolresult;
}

sub bits {
    return 0;
}

