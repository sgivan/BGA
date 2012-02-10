#!/usr/bin/perl

# this packages is part of the tool concept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this package provides methods for TMHMM (prediction of transmembrane helices)

package tmhmm_helper;

# these methods should run without any dependencies
# to tool and fact class. all information should
# be provided by parameters

# all methods starting with an underscore are 
# to be considered local methods and shouldn't
# be invoked by external modules


use GENDB::tool;
use GENDB::fact;
use GENDB::Common qw(remove_dir create_fasta_file);
use GENDB::GENDB_CONFIG qw ($GENDB_GV $GENDB_TMHMM);
use POSIX qw (tmpnam);

@ISA=();

my $VIEW_PLOT=1;

# runs the command and parses TMHMM output to generate facts 
sub run_job {
    my ($tool,$what) = @_;

    # the filenames to use
    my $dirname    = POSIX::tmpnam();

    my $infile     = $dirname."/query";
    my $resultfile = $dirname."/tmhmm.output";

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
	my $cmdline = $tool->command_line($infile, $dirname, $VIEW_PLOT);

	# Run TMHMM and read result!
	my $result; 
	open (OUTPUT, "$cmdline |");	
	while (<OUTPUT>) {
	    $result .= $_;
	};
	
	close (OUTPUT);	

	if ($VIEW_PLOT) {
	    # start ghostview to view the plot
	    my $plotfile = $dirname."/".$orf->name.".eps";
	    system ("$GENDB_GV $plotfile $dirname &");
	}
	else {
	    remove_dir ($dirname);
	}
	# return the blast output
	return $result;
    }
    elsif (ref $what eq "GENDB::orfstate") {
	# we need to run a scheduled job
        # try to lock the job and bail out, if job
	# is already locked
	if ($what->lock() != 0) {
	    print STDERR "Job already locked! Bailing out...\n";
	    remove_dir ($dirname);
	    return;
	}

        # create the command line
	my $cmdline = $tool->command_line($infile, $dirname);
	$cmdline .= " > $resultfile";


	# Run TMHMM and parse result!
	system ($cmdline);

	
	open (OUTPUT, "$resultfile");	
	while (<OUTPUT>) {
	    #####################
	    # parse output data #
	    #####################
	    
	    # 14KD_DAUCA Number of predicted TMHs:  1	    
	    if (/.*Number of predicted TMHs:\s+(\d+)/) {
		if ($1 > 0) {
		    my $fact = GENDB::fact->create($orf->id);
		    if ($fact < 0) {
			die "Can't save fact $fact";
		    }
		    
		    $fact->description("Number of predicted TMHs: $1");
		    #$fact->orffrom($1);
		    #$fact->orfto($2);
		    $fact->tool_id($tool->id);
		}
	    }	    
	    else {
		next;
	    };
	};
	
       	close (OUTPUT);	
	$what->finished(); 
	
	remove_dir($dirname);

	return 1;	
    }
    else {
	
	remove_dir ($dirname);	
	return "Unknown kind of parameter (".ref $what.") in tmhmm_helper::run_jobs!\n";
    }

}

# create the command line
sub command_line {
    my ($tool, $queryfile, $tmpdir, $plot) = @_;

    if ($plot) {
	return "$GENDB_TMHMM --workdir=$tmpdir $queryfile";
    }
    else {
	return "$GENDB_TMHMM --workdir=$tmpdir -noplot $queryfile";
    }
};


    
# return the tool internal score (e.g. the blast e value)
sub score {
    return $_[0]->toolresult;
}


# return the normalized information score (bits..)
sub bits {
    return 0;
}


# if a fact for this tool exists, it
# always has level 1
sub level {
    return 1;
}

1;


