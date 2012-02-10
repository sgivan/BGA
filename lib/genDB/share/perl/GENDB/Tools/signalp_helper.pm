package signalp_helper;

# this packages is part of the tool concept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this package provides methods for SignalP
# these methods should run without any dependencies
# to tool and fact class. all information should
# be provided by parameters

# all methods starting with an underscore are 
# to be considered local methods and shouldn't
# be invoked by external modules


use GENDB::tool;
use GENDB::fact;
use POSIX qw (tmpnam);
use GENDB::Common qw(remove_dir create_fasta_file);
use GENDB::Tools::ProjectConfig;

@ISA=();
($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

# runs the command and parses signalp output to generate facts 
sub run_job {
    my ($tool,$what) = @_;

    # the filenames to use
    my $dirname    = POSIX::tmpnam();

    my $infile     = $dirname."/query";
    my $resultfile = $dirname."/signalp.output";

    # init orf from fact or whatever there is
    my $orf = GENDB::orf->init_id ($what->orf_id);
    
    # create a file for the orf sequence 
    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname!";
    
    create_fasta_file ($infile, $orf->name(), $orf->aasequence());
    
    # depending on the kind of parameter,
    # we get the needed information from different location
    if (ref $what eq "GENDB::fact") {
	# run the tool for a given fact...	
	# create the command line
	my $cmdline = $tool->command_line($infile, $dirname);

	# Run SignalP and read result!
	my $signalpresult; 
	open (SIGNALPOUTPUT, "$cmdline |");	
	while (<SIGNALPOUTPUT>) {
	    $signalpresult .= $_;
	};
	
	close (SIGNALPOUTPUT);	
	remove_dir ($dirname);

	# return the blast output
	return $signalpresult;
    }
    elsif (ref $what eq "GENDB::orfstate") {
	# we need to run a scheduled job
        # try to lock the job and bail out, if job
	# is already locked
	if ($what->lock() != 0) {
	    print STDERR "job already locked, bailing out...\n";
	    remove_dir ($dirname);
	    return;
	}

        # create the command line
	my $cmdline = $tool->command_line($infile, $dirname);
	$cmdline .= " > $resultfile";

	# Run SignalP and parse result!
	system ($cmdline);

	my $fact=GENDB::fact->create($orf->id);
	if ($fact < 0) {
	    die "can't save fact $fact";
	}

	open (SIGNALPOUTPUT, "$resultfile");	
	while (<SIGNALPOUTPUT>) {
	    #####################
	    # parse output data #
	    #####################
	    
	    # Most likely cleavage site between pos. 39 and 40: SGA-MM
	    if (/cleavage site between pos.\s(\d+) and (\d+):\s(\S+)/) {
		$fact->orffrom($1);
		$fact->orfto($2);
		
	    }	    
	    elsif (/Prediction: (.+)/) { ### Parsing: Prediction: Signal peptide
		$fact->description($1);

	    }
	    elsif (/Signal peptide probability: (.+)/) {
		$fact->toolresult($1);

	    }
	    # elsif (/Max cleavage site probability: (.+) between pos\. (\d+) and (\d+)/) {
		# print "Max cleavage site probability: $1 between $2, $3\n";
	    #}
	    else {
		next;
	    };
	};
	$fact->tool_id($tool->id);
       	close (SIGNALPOUTPUT);	
	$what->finished(); 
	
	remove_dir($dirname);
	return 1;
	
    }
    else {
	
	remove_dir ($dirname);	
	return "Unknown kind of parameter (".ref $what.") in signalp_helper::run_jobs!\n";
    }
}

# create the command line with parameters from project configuration 
sub command_line {

    my ($tool, $queryfile, $tmpdir) = @_;

    my $type=GENDB::Tools::ProjectConfig->get_parameter("signalp_tool type");
    my $format=GENDB::Tools::ProjectConfig->get_parameter("signalp_tool format");
    my $trunc=GENDB::Tools::ProjectConfig->get_parameter("signalp_tool trunc");
    
    return $tool->executable_name." -t $type -f $format -trunc $trunc -d $tmpdir $queryfile";
    
};


    
# return the tool internal score (e.g. the blast e value)
sub score {
    return $_[0]->toolresult;
}


# return the normalized information score (bits..)
sub bits {
    return 0;
}


# return the level of a fact
# levels depend on user configurable settings
# so check the database
# levels for blast tools are stored as perl code to be evaluated
sub level {

    my ($tool, $fact) = @_;
    my $score = score ($fact);
    foreach $level (qw (level1 level2 level3 level4)) {

	if ($score >= $tool->$level()) {
	    # we got the level....so return the level number..
	    $dummy = $level;
	    $dummy =~ s/level//;
	    return $dummy;
	}
    }
    # we got no result for level 1 - 4, so return level 5...
    return 5;
}

1;


