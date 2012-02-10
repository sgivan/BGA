package GENDB::Tools::Glimmer3;

# simple package to encapsulate glimmer2
#
# used by GENDB

# $Id: Glimmer2.pm,v 1.2 2007/01/05 23:11:33 givans Exp $
#
# $Log: Glimmer2.pm,v $
# Revision 1.2  2007/01/05 23:11:33  givans
# commented some output lines
#
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.2  2003/11/07 23:50:11  genDB
# Added several print statements for troubleshooting.
# Commented print statements.
# Fixed regex to work with Glimmer2.13.
#
# Revision 1.1  2003/11/07 21:10:12  genDB
# Initial revision
#
# Revision 1.3  2001/08/28 16:44:56  agoesman
# removed unneccessary comments
#
# Revision 1.2  2001/08/28 16:11:40  agoesman
# supporting glimmer-2.02 now!!! still containing lots of old code
#
# Revision 1.1  2001/08/27 16:14:25  agoesman
# Initial revision
#
# Revision 1.2  2000/08/09 11:00:26  blinke
# moved methods to put data into database to application
# added support for modelfiles
#
# Revision 1.1  2000/07/21 14:01:30  blinke
# Initial revision
#
#
#

use POSIX;
use File::Temp ();
use GENDB::Common;
use GENDB::contig;
use GENDB::orf;
use GENDB::Config;
use GENDB::GENDB_CONFIG qw($GENDB_INSTALL_DIR);
use GENDB::Tools::genetic_codes;

#my $glimmer_cmd = $GENDB_INSTALL_DIR.'/share/exec/glimmer-2.02';
my $glimmer_cmd = $GENDB_INSTALL_DIR . '/share/exec/glimmer-3.02';
#print "\n\tGENDB::Tools::Glimmer2; glimmer_cmd: '$glimmer_cmd'\n";

1;

sub new {

    my ($class, $args) = @_;
 #   print "##Glimmer2->new() glimmer_cmd: '$glimmer_cmd'##\n"; 
    # init class
    $self =  { 
	'verbose' => 0
	};
 
    bless $self, $class;
    return $self;

}

sub verbose {
    my ($self,$val) = @_;
    if ($val) {
	$self->{verbose} = $val;
    }
    print "setting Glimmer3 to verbose\n" if ($val);
    return $self->{verbose};
}

# set a reference to a string for displaying
# status messages. 
sub statusmessage {
    my ($self, $val) = @_;
    if ($val) {
	$self->{statusmessage} = $val;
    }
    return $self->{statusmessage};
}

# management of sequences

sub add_sequence {
    my ($self, $sequence_name, $sequence) = @_;

    # IC IC 
    # we don't check whether the sequence is already added..
    # this should be changed sometimes...
    if (!defined($self->{_sequences}->{$sequence_name})) {
    	print "adding '$sequence_name' to Glimmer2 object\n" if ($self->verbose());
    	$self->{_sequences}->{$sequence_name}=$sequence;
    } else {
    	#print "not adding '$sequence_name' to Glimmer2 because it already exists\n";
    }
}

sub delete_sequence {
    my ($self, $sequence_name) = @_;

    if (defined $self->{_sequences}->{$sequence_name}) { 
	undef $self->{_sequences}->{$sequence_name};
    }
} 

sub sequences {
    my ($self) = @_;
    return $self->{_sequences};
}

sub orfs {
    my ($self, $sequence_name) = @_;
    if ($sequence_name) {
			return $self->{_orfs}->{$sequence_name};
    }
    return $self->{_orfs};
}

sub model_file {
    my ($self, $modelfile) = @_;
    if ($modelfile) {
			$self->{modelfile} = $modelfile;
    }
    print "model file: " . $self->{modelfile} . "\n" if ($self->verbose());
    return $self->{modelfile}
}

sub statusupdate {
    my ($self, $status) = @_;
    print "status:  $status\n";
    if ($self->{statusmessage}) {
			${$self->{statusmessage}} = $status;
    }
}

sub linear_contig {
    my ($self,$val) = @_;
    if ($val) {
	$self->{linear} = $val;
    }
    print "setting to linear contig\n" if ($self->verbose() && $val);
    return $self->{linear};
}

sub run_glimmer {
		#print "\nrun_glimmer called from '", scalar(caller()), "'\n";
    my ($self) = @_;
    
    # do we have something to do ?
    return if (scalar (keys %{$self->{_sequences}}) == 0);
		#print "sequences received\n";
    my $glimmer_parameters = "-x";

    # check whether a model file was given....
    # if a model file was given, it will be used to
    # predict ORFs
    # if no model file was given, the longest contig 
    # will be used to build a temporary fasta file from which a model file can be build

    if (!$self->model_file) {
			# first of all, build an IMM of the longest sequence..
			#print "no model file specified\n";
			$self->statusupdate("Creating model....");
			my $longest;
			my $longlen;
			# search the longest sequence...
			foreach $seq (keys %{$self->{_sequences}}) {
					my $seqlen = length ($self->{_sequences}->{$seq});
					if ($seqlen > $longlen) {
						$longest = $seq;
						$longlen = $seqlen;
					}
			}
		
			#my $contigfile = POSIX::tmpnam;
			my $contigfh = File::Temp->new();
			my $contigfile = $contigfh->filename();
			#print "temp contig file = '$contigfile'\n";
		#	print "##Glimmer2->run_glimmer() contigfile: '$contigfile'##\n";
			create_fasta_file ($contigfile, $longest, $self->{_sequences}->{$longest});
			$glimmer_parameters .= " -c $contigfile";
    } else {
    	#print "model file specified as '", $self->model_file(), "'\n";
			$glimmer_parameters .= " -m ".$self->model_file;
    }


    ### option for linear or circular contig sequence
    if ($self->linear_contig) {
			$glimmer_parameters .= " -l ";
    };

    ### use genetic code
    if ($GENDB_CODON) {
			$glimmer_parameters .= " -t $GENDB_CODON";
    };

    # we got our model,
    # now look for orfs....

    foreach $seq (keys %{$self->{_sequences}}) {

			$self->statusupdate("Predicting ORFs for $seq.....");
			#my $file = POSIX::tmpnam;
			my $tempfh = new File::Temp( TEMPLATE => 'genDBXXXXXXXXXX', UNLINK => 1, SUFFIX => '.nfa' );
			my $file = $tempfh->filename();
			#print "temp fasta file = '$file'\n";
			create_fasta_file ($file, $seq, $self->{_sequences}->{$seq});
			print "using cmd:  '$glimmer_cmd $glimmer_parameters -f $file\n" if ($self->verbose());
			open (GLIMMERRESULT, "$glimmer_cmd ".$glimmer_parameters."-v -f $file |")
					or die "Cannot run glimmer.....";
		
			my $orfcounter=0; my $specialcounter=0;
		#	my $glimmerout = POSIX::tmpnam;
		#	print "##Glimmer2->run_glimmer() attempting to open file '$glimmerout' for Glimmer output##\n";
		#	open(GOUT, ">$glimmerout") or die "can't open '$glimmerout': $!";
			while (<GLIMMERRESULT>) {
		#	  print GOUT "$_";
					my ($nr, $start, $stop, $frame, $length , $comment) = ();
				## SAG fixed this regex to work with Glimmer2.13
				#	if (/(\d+)\s+(\d+)\s+(\d+)\s+\[((?:\+|-)\d)\sL=(\s*\d+)\sr\=-1\.\d{3}\](\s+\[([\w\s\#=]+)\])?/) {
					if (/(\d+)\s+(\d+)\s+(\d+)\s+\[([+-]\d)\sL=(\s*\d+)\sr\=[-.\d]+\](\s+\[([\w\s\#=]+)\])?/) {
		#	      print "\tpass: '$_'\n";
				$nr = $1;
				$start = $2;
				$stop = $3;
				$frame = $4;
				$length = $5;
				$comment = $6;
					}
					else  {
		#	      print "\tfail: '$_'\n";
				next;
					};
		
					chomp $length;
					
					# check if frame, $start and $stop are same
					if ((($stop > $start) && ($frame < 0)) || 
				(($stop < $start) && ($frame > 0))) {
				printf "Ambiguous orf position, skipping orf: start %d, stop %d, frame %d !\n", $start, $stop, $frame if $self->{verbose};
				next;
					}
					
					# normalize results, e.g. start is always less than stop..
					# so change start and stop for frame < 0
					if ($frame < 0) {
				my $dummy = $start;
				$start = $stop - 3;
				$stop = $dummy;
					}
					else {
				$stop+=3;
					};
					
					
					$calc_frame = $start % 3;
					if ($calc_frame != (abs($frame) % 3)) {
				
				printf "Ambiguous frame, skipping orf : start %d, stop %d, length %d, frame from glimmer %d, calculated frame %d (abs. value)\n", $start, $stop, $length, $frame, $calc_frame if $self->{verbose};
				next;
					}
					
					if (($length % 3) != 0) {
				printf "Warning ! Orf length not a multiple of 3: start %d, stop %d, length %d !\n", $start, $stop, $length if $self->{verbose};
					}
					
					if ($frame > 0) {
				$startcodon = substr ($self->{_sequences}->{$seq}, $start - 1, 3);
					}
					else {
				$startcodon = GENDB::Common::reverse_complement 
						(substr ($self->{_sequences}->{$seq},$stop - 3, 3));
					};
					
					# check the start codon according to applied genetic code
					my $starts = GENDB::Tools::genetic_codes->get_start_codons();
					if ( $startcodon!~/$starts/i ) {
				printf "Warning ! Ambiguous start codon: %s, start: %d, stop: %d, frame: %d\n", $startcodon, $start, $stop, $frame if $self->{verbose};
					};
					
		
					# this orf seems to be ok ...	    
					$self->{_orfs}->{$seq}->[$orfcounter]->{'from'} = $start;
					$self->{_orfs}->{$seq}->[$orfcounter]->{'to'} = $stop;
					$self->{_orfs}->{$seq}->[$orfcounter]->{'frame'}=$frame;
					$self->{_orfs}->{$seq}->[$orfcounter]->{'startcodon'}=$startcodon;
					if (defined $comment) {
				$self->{_orfs}->{$seq}->[$orfcounter]->{'comment'}=$comment;
				$specialcounter++;
					}
					
					$orfcounter++;
			}
			close (GLIMMERRESULT);
		#	close (GOUT);
		#	unlink ($file);
    }

    if ($model_file) {
	unlink ($model_file);
    }
    
}


