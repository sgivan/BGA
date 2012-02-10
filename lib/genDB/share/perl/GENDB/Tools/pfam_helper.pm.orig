package pfam_helper;

# this packages is part of the tool conzept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this package provides methods for HMMpfam and 
# PFAM database

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
use GENDB::orf;
use GENDB::contig;
use GENDB::GENDB_CONFIG;
use GENDB::Common qw(create_fasta_file remove_dir);

use Bio::Tools::HMMER::Results;

use POSIX qw (tmpnam);
use Carp;
my $DNA_TYPE = 0;
my $AA_TYPE = 1;

($VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

1;

# runs the command and parses the hmmsearch output to
# generate facts 
sub run_job {


    # get the tool...
    my $tool = shift @_;

    # decide what to do...
    my $what = shift @_;
    
    return "hmmpfam not setup properly" if (!defined $GENDB_PFAM);

    # the filenames to use
    my $dirname    = POSIX::tmpnam();
    $dirname = "/local/cluster" . $dirname;
    
    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname !";

    my $orf = GENDB::orf->init_id ($what->orf_id);

    my $queryfile  = $dirname."/query";
    if ($tool->input_type() eq $DNATYPE) {
	create_fasta_file ($queryfile, $orf->name, $orf->sequence());
    }
    else {
	create_fasta_file ($queryfile, $orf->name, $orf->aasequence());
    }

    my $dbfile;

    # depending on the kind of parameter,
    # we get the needed information from different location

    if (ref $what eq "GENDB::fact") {

	# IC IC IC 
	# we should contruct the pfam database filename 
	# by informations from tool object...later..

	$dbfile = $dirname."/dbfile";
	
	my $dbentry = $what->dbentry();
	
	# skip possible multiple entries from file
	$dbentry = substr ($dbentry, 0, index ($dbentry, '//') + 1);
	_create_plain_file($dbfile, $dbentry);

	my $commandline = $tool->command_line ($queryfile, $dbfile);
	
	# and now......do it !
	my $pfamresult; 
	open (PFAMOUTPUT, "$commandline |");
	
	while (<PFAMOUTPUT>) {
	    $pfamresult .= $_;
	}
	
	close (PFAMOUTPUT);
	
	remove_dir ($dirname);

	# return the blast output
	return $pfamresult;
    }
    elsif (ref $what eq "GENDB::orfstate") {
	 
        # try to lock the job and bail out, if job
	# is already locked
	if ($what->lock() != 0) {
	    remove_dir ($dirname);
	    return;
	}
	
        # construct the command line

	my $cmdline = $tool->command_line ($queryfile);
       
	# lets run pfam through a pipe,
	# directing input into the parser
	open (PFAMRUN, "$cmdline |");  

	my $hmm_parser=Bio::Tools::HMMER::Results->new(-fh => *PFAMRUN,
						       -type => 'hmmpfam');
	
	# cycle through all sequence and domain units
	foreach my $seq ($hmm_parser->each_Set) {
	    foreach $domain ($seq->each_Domain) {

		my $new_fact = GENDB::fact->create ($orf->id);
	    
		if ($new_fact < 0) {
		    die "cannot allocate new fact object";
		}
		
		$new_fact->dbref($domain->hmmname);
#		$new_fact->description($domain->hmmacc);
		$new_fact->description($seq->seq_id);
		$new_fact->orffrom($domain->start);
		$new_fact->orfto($domain->end);
		$new_fact->dbfrom($domain->hstart);
		$new_fact->dbto($domain->hend);
		$new_fact->toolresult($domain->evalue());
		$new_fact->information($domain->bits());
		$new_fact->tool_id($tool->id);
	    }
	}
	close (PFAMRUN);

	$what->finished();

	remove_dir ($dirname);
	return 1;
    }
    else {
	remove_dir($dirname);
	# hmmm.....don't know, what to do
	return "Unknown kind of parameter (".ref $what.") in blast_helper::run_jobs!\n";
    }
}

# create a plain file
sub _create_plain_file {
    my ($filename, $content) = @_;

    open (FILE, "> $filename") or die "Cannot open $filename for writing";
    print FILE $content;
    close (FILE);
}

sub command_line {

    my ($tool, $queryfile, $dbfile) = @_;

    if ($dbfile) {
	# if a database file name is given,
	# but it into the command line
	return "$GENDB_PFAM $dbfile $queryfile";
    }
    my $dbname= $tool->dbname;
    if (substr($dbname, 0, 1) eq "/") {
	# if the database name starts with a leading "/"
	# we assume it is an absolute pathname
	return "$GENDB_PFAM $dbname $queryfile";
    }
    else {
	return "$GENDB_PFAM ${PFAM_DB_DIR}/".$tool->dbname." $queryfile";
    }
}

    
# return the tool internal score (e.g. the blast e value)
sub score {

    my ($fact) = @_;
    
    return $fact->toolresult;
}


# return the normalized informatrion score (bits..)
sub bits {
    my ($fact) = @_; 

    return $fact->information;
}


# return the level of a fact
# levels depend on user configurable settings
# so check the database
# levels for blast tools are stored as perl code to be evaluated
sub level {

    my ($tool, $fact) = @_;

    foreach $level (qw (level1 level2 level3 level4)) {
	my $score = score ($fact);

	if ($score <= $tool->$level()) {
	    # we got the level....so return the level number..
	    my $dummy = $level;
	    $dummy =~ s/level//;
	    return $dummy;
	}
    }
    # we got no result for level 1 - 4, so return level 5...
    return 5;
}

sub dbentry {
    my ($fact) = @_;
    
    my $used_tool = GENDB::tool->init_id($fact->tool_id);

    # hmm tools provide a way to use the pfam index to
    # retrieve single hmms

    my $entry;

    # use hmmfetch to retrieve pfam entry
    open (HMM, "$HMMFETCH_TOOL $PFAM_DB_DIR/Pfam ".$fact->dbref." |")
	or return -1;
    while (<HMM>) { $entry .= $_};
    close (HMM);

    if ($entry) {
	return $entry;
    }
    return -1;

}
