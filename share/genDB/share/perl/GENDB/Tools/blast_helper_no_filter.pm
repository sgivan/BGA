package blast_helper_no_filter;

# this packages is part of the tool conzept of GENDB
# it contains several methods to maintain and 
# manipulate tool generated data (facts)

# this package provides methods for BLAST 2 tools
# these methods should run without any dependencies
# to tool and fact class. all information should
# be provided by parameters.

# this class disables the blast input filter

# all methods starting with an underscore are 
# to be considered local methods and shouldn't
# be invoked by external modules
# (why doesn't perl provide a way to hide 
#  methods...... ? )

use GENDB::tool;
use GENDB::fact;
use GENDB::GENDB_CONFIG;
use GENDB::Common;
use Bio::Tools::Blast;
use POSIX qw (tmpnam);
use File::Basename;

@ISA=();

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

my $DNA_TYPE = 0;
my $AA_TYPE = 1;

# end of CONFIG area
1;


# runs the command and parsers the blast output to
# generate facts 
sub run_job {


    # get the tool...
    my $tool = shift @_;

    # decide what to do...
    my $what = shift @_;
    
    # the filenames to use
    my $dirname    = POSIX::tmpnam();

    my $infile     = $dirname."/query";
    my $dbfile;
    my $resultfile = $dirname."/blast.output";

    # ok this is mean, but both GENDB::fact and GENDB::orfstate got a
    # orf_id field.....

    my $orf = GENDB::orf->init_id ($what->orf_id);
    

    # create a file for the orf sequence 

    mkdir ($dirname, 0750) or die "Cannot create temporary directory $dirname !";
    
    # depending on the kind of tool (dna / amino acid input),
    # we need to convert create different file content
    
    if ($tool->input_type == $DNA_TYPE) {
	create_fasta_file ($infile, $orf->name(), $orf->sequence());
    }
    else {
	create_fasta_file ($infile, $orf->name(), $orf->aasequence());
    }
    
    # depending on the kind of parameter,
    # we get the needed information from different location

    if (ref $what eq "GENDB::fact") {

	# we need to run the tool for a given fact...
	# e.g. we should blast against a single
	# database entry..
	
	# create a blast database containing the target database entry
	my $dbname = $what->dbref();
	my $dbseq = $what->dbsequence();

	# check whether SRS returns a sequence
	# due to broken SRS this may happen for
	# some database entries.....
	if (!$dbseq || ($dbseq =~/</)) {
	    return -1;
	}

	$dbfile = $dirname."/database";
	create_fasta_file ($dbfile, $dbname,$dbseq);

	# depending on the kind of tool (dna / amino acid input),
	# we need to convert the database file

	if ($tool->input_type == $DNA_TYPE) {
	    system ("$FORMATDB_TOOL -p F -i $dbfile -l /dev/null");
	}
	else {
	    system ("$FORMATDB_TOOL -p T -i $dbfile -l /dev/null");
	}

	# create the command line
	my $cmdline = $tool->command_line($infile, $dbfile);
	### $ENV{'NCBI'}='/vol/biotools/share/ncbi';

	# and now......do it !
	my $blastresult; 
	open (BLASTOUTPUT, "$cmdline |");
	
	while (<BLASTOUTPUT>) {
	    $blastresult .= $_;
	}
	
	close (BLASTOUTPUT);
	
	remove_dir ($dirname);

	# return the blast output
	return _correct_blast_evalue($blastresult, $what);
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
	my $cmdline = $tool->command_line($infile);
	$cmdline .= " > $resultfile";

	### $ENV{'NCBI'}='/vol/biotools/share/ncbi';

	# and now......do it !

	system ($cmdline);

	# encapsulate the blast parser
	# there is a known problem when
	# parsing report without a hit
	my $blast_run;
	eval {
	    $blast_run = Bio::Tools::Blast->new(-file=> $resultfile,
						-parse => 1);
	};
	if ($@ || ($blast_run < 0)) {
	    print STDERR "Error parsing blast report (perhabs no hits?):\n$@";
	}
	else {
	    my $counter=0; # count hsps
	    foreach $hit ($blast_run->hits) {
		
		my $desc= $hit->desc;
		my $db=$hit->name;
		foreach $hsp ($hit->hsps) {
		    
		    $counter++;
		    
		    # skip this fact if the expect value 
		    # is too high
		    next if ($GENDB_BLAST_LEVEL5_CUTOFF &&
			     $hsp->expect > $tool->level5);

		    my $fact=GENDB::fact->create($orf->id);
		    
		    # IC IC IC ....
		    if ($fact < 0) {
			die "can't save fact $fact";
		    }
		    
		    my ($orffrm,$orfto)= $hsp->range('query');
		    my ($dbfrm,$dbto)= $hsp->range('sbjct');
		    my $evalue=$hsp->expect;
		    
		    my $res="(s:".$hsp->score.",e:".$evalue.")";
		    $fact->toolresult($res);
		    
		    $fact->information($hsp->bits); 
		    # information on the
		    # hit in bits is slightly better to compare then 
		    # p or e values.
		    
		    $fact->dbfrom($dbfrm);
		    $fact->dbto($dbto);
		    $fact->description($desc);
		    $fact->orffrom($orffrm);
		    $fact->orfto($orfto);
		    $fact->tool_id($tool->id);
		    $fact->dbref($db);
		    
		}
	    }
	}
	$what->finished(); 
	
	remove_dir($dirname);
	return 1;
	
    }
    else {
	
	remove_dir ($dirname);
	# hmmm.....don't know, what to do
	return "Unknown kind of parameter (".ref $what.") in blast_helper::run_jobs!\n";
    }
}

# blast e-values depend on database size. reblasting
# a fact on the fly generates "wrong" e-values due to
# different database sizes. this sub fixes the blast
# report to show the correct value
sub _correct_blast_evalue {
    my ($blastresult, $fact) = @_;

    # the e-values is part of the hit overview and 
    # the HSP description. substitute both values

    # the first HSP contains the e-value generated by this report
    # parse it.
    my ($wrong_e_value) = $blastresult =~ /Expect = ([\d.e-]+)/m;

    return $blastresult if (!$wrong_e_value);
    # substitute this value by the value stored in the database
    # (there may be more than one HSP, but the fact always refers
    # to the first aka best HSP) .oO ( are we sure about this ? )
    my $new_value = $fact->score;
    
    # fix decimal point...it confuses the next regexp ;-)
    $wrong_e_value =~ s/\./\./;
    $blastresult =~ s/$wrong_e_value/$new_value/g;
    return $blastresult;
}

sub command_line {

    my ($tool, $queryfile, $dbfile) = @_;

    if ($dbfile) {
	# if a database file name is given,
	# put it into the command line
	return $tool->executable_name." $dbfile $queryfile -F F";
    }

    my $dbname = $tool->dbname();
    return $tool->executable_name." $dbname $queryfile -F F";
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
    my $score = score ($fact);
    foreach $level (qw (level1 level2 level3 level4)) {

	if ($score <= $tool->$level()) {
	    # we got the level....so return the level number..
	    $dummy = $level;
	    $dummy =~ s/level//;
	    return $dummy;
	}
    }
    # we got no result for level 1 - 4, so return level 5...
    return 5;
}

sub dbsequence {
    my ($fact) = @_;
#    print "\n\n\nchecking dbsequence\n\n\n";
    my $used_tool = GENDB::tool->init_id($fact->tool_id);

    # we use the Bio::Index system of BioPerl to index
    # and query fasta entry from databases

    # test whether we can access the index file and

    if ($BLAST_DATABASE_INDEX) {
	my ($dbfile,undef,undef) = fileparse($used_tool->dbname());
	my $index_file = $BLAST_DATABASE_INDEX."/".$dbfile;
	if (-r $index_file ) {
	    # access the index
	    require Bio::Index::Fasta;
	    my $index = Bio::Index::Fasta->new(-filename => $index_file,
					       -write_flag => 0);
	    
	    if ($index) {
		# get a Bio::Seq object 
		
		my $seq = $index->fetch($fact->dbref());
		if ($seq) {
		    # return the sequence itself
		    return $seq->seq();
		}
	    }
	}
    }
    # we cannot access the index, so return error state
    return -1;
}


