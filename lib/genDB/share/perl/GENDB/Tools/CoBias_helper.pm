package CoBias_helper;
use GENDB::tool;
use GENDB::fact;
use GENDB::GENDB_CONFIG;
use GENDB::Common;

@ISA=();


# runs the command and parse output
# to create a fact
sub run_job {


    # get the tool...
    my $tool = shift @_;

    # decide what to do...
    my $what = shift @_;
    
    # the filenames to use
    my $dirname    = POSIX::tmpnam();

    my $infile     = $dirname."/query";
    my $resultfile = $dirname."/CoBias.output";

    # ok this is mean, but both GENDB::fact and GENDB::orfstate got a
    # orf_id field.....
    my $orf = GENDB::orf->init_id ($what->orf_id);
    # create a file for the orf sequence 
    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname !";

    _create_fasta_file ($infile, $orf->name(), $orf->sequence());
 


    # try to lock the job and bail out, if job
    # is already locked
    if ($what->lock() != 0) {
	print STDERR "job already locked, bailing out...\n";
	remove_dir ($dirname);
	return;
    }
    
    # create the command line
    my $cmdline = $tool->command_line($infile);
    $cmdline .= " > $resultfile";
    
    # and now......do it !
    
    system ($cmdline);

    # parse output ..
    open(IN, $resultfile) || die "Cannot open CoBias outfile $resultfile: $!\n";
    # 1        6.41e-214   0.17       C1_0957      description, ..
    while(<IN>) {
	chomp;
	#1    1.00e+00  -0.41  U00096_2,    length: 2463
	if(/^(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)$/) {
	    my $counter = $1;
	    my $p_value = $2;
	    my $av_score = $3;
	    my $id = $4;
	    my $description = $5;
	    my $fact=GENDB::fact->create($orf->id);
	    if ($fact < 0) {
		die "can't save fact $fact";
	    }
	    
	    my $res="(s:".$av_score.",e:".$p_value.")";
	    $fact->toolresult($res);
	    $fact->tool_id($tool->id);
	    $fact ->description($tool ->dbname);
	    $what->finished(); 
	
	    remove_dir($dirname);
	    return 1;
	}
	
    }
    
    remove_dir ($dirname);
    # hmmm.....don't know, what to do
    return "Unknown kind of parameter (".ref $what.") in CoBias_helper::run_jobs!\n";
}


sub command_line {

    my ($tool, $queryfile) = @_;
    my $matrix = $tool->dbname();
    return $tool->executable_name." -l 1 -m $matrix $queryfile";
}


sub alignment_state {
    return 0;
}

# return the tool internal score (e.g. the blast e value)
sub score {

    my ($fact) = @_;
    
    my $result = $fact->toolresult;
    
    # split the tool result field into score and e-value
    $result =~ /^\(s:(.+),e:(.+)\)$/;
    
    my $score = $1;
    my $evalue = $2;

    return $evalue;

}

# write a fasta file
sub _create_fasta_file {

    my ($filename, $seqname, $sequence) = @_;

    open (SEQFILE, "> $filename") || return 0;
    print SEQFILE ">$seqname\n";
    print SEQFILE $sequence;
    close (SEQFILE);
    return 1;
}

# return the normalized informatrion score (bits..)
sub bits {
    my ($fact) = @_; 

    my $result = $fact->toolresult;
    
    # split the tool result field into score and e-value
    $result =~ /^\(s:(.+),e:(.+)\)$/;
    
    my $score = $1;
    my $evalue = $2;
    
    return $score;
}
# return the level of a fact
# levels depend on user configurable settings
# so check the database
# levels for blast tools are stored as perl code to be evaluated
sub level {
    my ($tool, $fact) = @_;
    return 1;
}

1;


