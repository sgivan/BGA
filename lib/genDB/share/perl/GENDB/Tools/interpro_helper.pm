package interpro_helper;
# $Id: interpro_helper.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $
# this packages is part of the tool conzept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this package provides methods for InterProScan

# these methods should run without any dependencies
# to tool and fact class. all information should
# be provided by parameters

# all methods starting with an underscore are 
# to be considered local methods and shouldn't
# be invoked by external modules
# (why doesn't perl provide a way to hide 
#  methods...... ? )

use GENDB::tool;
use GENDB::fact;
use GENDB::GENDB_CONFIG qw($GENDB_INTERPRO_DIR $GENDB_INTERPRO_TRUE_RESULT $GENDB_INTERPRO_UNKNOWN_RESULT);
use GENDB::Common;
use POSIX qw (tmpnam);
#use File::Temp;
use Carp qw (croak);

use vars qw($VERSION);
use strict;

($VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

1;

##### CONFIG AREA

# number of parallel applications to be run by InterPro
my $parallel_jobs=10;

## END OF CONFIG AREA

# runs the command and parsers the blast output to
# generate facts 
sub run_job {
    my ($tool, $what) = @_;

    # check whether we support this type of 
    # calling parameter
    if ((!ref $what eq "GENDB::fact") &&
	(!ref $what eq "GENDB::orfstate")) {
	return "Unknown kind of parameter (".ref $what.") in blast_helper::run_jobs!\n";
    }

    # the filenames to use
    my $dirname    = POSIX::tmpnam();
    $dirname = "/local/cluster" . "$dirname";
    my $infile     = $dirname."/query";

    print "infile = '$infile'\n";

    # ok this is mean, but both GENDB::fact and GENDB::orfstate got a
    # orf_id field.....

    my $orf = GENDB::orf->init_id ($what->orf_id);
    

    # create a file for the orf sequence 

    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname: $!";
    
    # create a temporary file for storing the aa sequence
    create_fasta_file ($infile, $orf->name(), $orf->aasequence());

    # InterPro creates a temporary dir storing the 
    # query sequence, several parsers and the results
    my $tmp_interpro_dir = _create_interpro_dir($infile);
    print "tmp_interpro_dir = '$tmp_interpro_dir'\n";

    if (ref $what eq "GENDB::fact") {

	# run InterPro for a given fact

	# there is no way to get a single db sequence
	# for InterPro. so run the complete scanning
	# although this may take some time

	# execute the makefile in the temporary interpro dir

	my $cmdline = "cd $tmp_interpro_dir; make txt -j$parallel_jobs -k";

	system ("$cmdline 2>/dev/null 1>/dev/null");

	open (INTERPRORESULT, "$tmp_interpro_dir/merged.txt");
	
	my $result;
	while (<INTERPRORESULT>) {
	    $result .= $_;
	}
	
	close (INTERPRORESULT);
    }
    elsif (ref $what eq "GENDB::orfstate") {

	# we need to run a scheduled job

        # try to lock the job and bail out, if job
	# is already locked
	if ($what->lock() != 0) {
	    print STDERR "job already locked, bailing out...\n";
	}
	else {
	    # executing interpro for an orfstate is
	    # similar to executing it for a fact

	    # execute the makefile in the temporary interpro dir
	    
	    # this time, create raw output
	    my $cmdline = "cd $tmp_interpro_dir; make raw -j$parallel_jobs -k";
	    
	    system ("$cmdline 2>/dev/null 1>/dev/null");
	    
	    open (INTERPRORESULT, "$tmp_interpro_dir/merged.raw");
	    
	    my @results = <INTERPRORESULT>;
	    close (INTERPRORESULT);
	    my $ipr={};
	    my $go={};

	    foreach (@results) {
		# parse each single result line 
		# format:
		# query name
		# checksum
		# length
		# tool
		# acc-number
		# ID
		# from
		# to
		# tool score
		# interpro result (either "T" or "?")
		# date
		# InterPro ID
		# description
		chomp;
		my (undef,undef,undef,$used_tool,
		    $acc_number,$sub_id,$from,$to,$tool_result, $ipr_result,
		    undef,$ipr_id,$description,$go_entries) = split /\t/;

                next if (lc($ipr_result) ne "t");
		if (!$description || ($description eq "NULL")) {
		    print STDERR "skipping result due to insufficent information:\n$_\n";
		    next;
		}

		# store interpro information
		if (!defined ($ipr->{$ipr_id})) {
		    $ipr->{$ipr_id}->{description} = $description;
		    $ipr->{$ipr_id}->{from} = $from;
		    $ipr->{$ipr_id}->{to} = $to;
		}
		else {
		    $ipr->{$ipr_id}->{from} = _min($from,$ipr->{$ipr_id}->{from});
		    $ipr->{$ipr_id}->{to} = _max($to,$ipr->{$ipr_id}->{to});
		}

		# split up the $go_entries
		foreach (split /,\s*/, $go_entries) {
		    chomp;
		    next if ($_ eq "");
		    my ($class, $description, $go_number) = /^(.+): (.+) \(GO:(\d+)\)$/;
		    next if (!$class);
		    next if (!$description);
		    next if (!$go_number);
		    if (!defined ($go->{$go_number})) {
			$go->{$go_number}->{description} = $_;
			$go->{$go_number}->{from} = $from;
			$go->{$go_number}->{to} = $to;
		    }
		    else {
			$go->{$go_number}->{from} = 
			    _min($from,$go->{$go_number}->{from});
			$go->{$go_number}->{to} = 
			    _max($to,$go->{$go_number}->{to});
		    }
		}
	    }
		
	    # generate new facts, one for each InterPRO and GO entry found
	    foreach my $iprhit (keys %$ipr) {
		my $fact=GENDB::fact->create($orf->id);
		    
		$fact->toolresult("");
		$fact->information(0);
		
		# we got no dbfrom or dbto values...
		$fact->orffrom($ipr->{$iprhit}->{from});
		$fact->orfto($ipr->{$iprhit}->{to});
		$fact->description($ipr->{$iprhit}->{description});
		$fact->tool_id($tool->id);
		$fact->dbref($iprhit);
	    }
	    foreach my $gohit(keys %$go) {
		my $fact=GENDB::fact->create($orf->id);
		    
		$fact->toolresult("");
		$fact->information(0);
		
		# we got no dbfrom or dbto values...
		$fact->orffrom($go->{$gohit}->{from});
		$fact->orfto($go->{$gohit}->{to});
		$fact->description($go->{$gohit}->{description});
		$fact->tool_id($tool->id);
		$fact->dbref($gohit);
	    }
	    $what->finished(); 
	}
    }
    # clean up
#    remove_dir($dirname);
#    remove_dir($tmp_interpro_dir);
}

sub _min {
    return $_[0] < $_[1] ? $_[0] : $_[1];
}

sub _max {
    return $_[0] > $_[1] ? $_[0] : $_[1];
}

# check the installation of interpro and 
# create a temporary dir for executing it
sub _create_interpro_dir {
    my ($infile) = @_;
    
    my $interpro_path=$GENDB_INTERPRO_DIR;
    if (!$interpro_path) {
	# the path to INTERPRO is not configured..
	# try a path lookup as last resort...
	$interpro_path=`which InterProScan.pl`;
	print "interpro_path = '$interpro_path'\n";
	if (!$interpro_path) {
	    # bad news...
	    # no interpro found..
	    croak "InterProScan.pl not found - cannot execute InterPro scanning. Setup the path correctly at GENDB_CONFIG !";
	}
    }
    else {
	if (! -e $interpro_path."/InterProScan.pl") {
	    croak "InterProScan.pl not found in directory $interpro_path - cannot execute InterPro scanning. Setup the path correctly at GENDB_CONFIG !";
	}
    }
    if (! -r $interpro_path."/InterProScan.pl" ) {
	croak "Cannot execute $interpro_path/InterProScan.pl - check permissions !";
    }
    
    # ok, we know where to find InterProScan.pl
    # execute it and parse output..
#    print "path: '$ENV{PATH}'\n";
    $ENV{PATH}=$ENV{PATH}.":/vol/gnu/bin";
    open (PRESCAN, "$interpro_path/InterProScan.pl -i $infile +ipr +go +scr |") ||
	die "Cannot execute $interpro_path/InterProScan.pl";
    my $tmp_dir="";
    while (<PRESCAN>) {
	chomp;
#	if ($_ =~ /^from: (\S+)\s*$/) {
	if ($_ =~ /\s*from:\s+(\S+)\s*$/) {
	    $tmp_dir=$1;
	    chomp $tmp_dir;
	    last;
	}
    }
    close (PRESCAN);
    if (!$tmp_dir) {
	croak "cannot parse temporary executing directory from InterProScan.pl";
    }
    return $tmp_dir;
}

		     
# some arbitary level setup
sub level {
    # interpro results are always level 1 results
    return 1;

#      my ($tool, $fact) = @_;
#      if ($fact->toolresult eq "T") {
#  	return $GENDB_INTERPRO_TRUE_RESULT;
#      }
#      else {
#  	return $GENDB_INTERPRO_UNKNOWN_RESULT;
#      }
}

# IC IC IC change stubs below !!

sub bits {
    return 0;
}

sub score {
    return 0;
}

# interpro cannot be run on the fly..
sub alignment_state {
    return 0;
}
