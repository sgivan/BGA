package GENDB::Tools::Importer::GenBank;

# GenBank importer for GENDB
# this class encapsulates the complete
# database management and error reporting

# $Id: GenBank.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: GenBank.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.3  2002/03/13 13:58:10  jan
# Unwanted entries were no longer inserted in the database (if callback returns 0)
#
# Revision 1.2  2002/03/13 13:44:54  jan
# use GENDB::feature_type inserted
#
# Revision 1.1  2001/11/15 11:30:29  blinke
# Initial revision
#

# the backend of this module is the GenBank parser
# of BioPerl (http://www.bioperl.org)

# create a new importer
# parameter: $filename        file to import
#            $add_parameters  scalar to pass additional parameters
#
# add_parameter should be used by subclasses to configure arbitary
# options (e.g. the glimmer model file for fasta import)
#
# returns:   Import object ref

use GENDB::Common;
use GENDB::contig;
use GENDB::orf;
use GENDB::annotator;
use GENDB::annotation;
use GENDB::feature_type;
use vars qw(@ISA);
use strict;

@ISA=qw(GENDB::Tools::Importer);

1;


sub new {
    my ($class, $filename, $add_parameters) = @_;

    my $self = {file => $filename };
    
    bless $self, ref $class || $class;
    return $self;

}

# parsing the input file is done by Bio::SeqIO
# catch all errors and report them
sub parse {
    my ($self) = @_;

    # to decrease overall compilation time,
    # load the BioPerl modules only if it's
    # really needed
    require Bio::SeqIO;

    eval {
	my $main_parser = Bio::SeqIO->new(-file => $self->{file},
					  '-format' => 'genbank');
	while (my $seqobj = $main_parser->next_seq()) {
	# skip all non-dna entries
	    if (!($seqobj->moltype() eq 'dna')) {
		next;
	    }
	    $self->{entries}->{$seqobj->id} = $seqobj;
	}
    };
    if ($@) {
	return $@;
    }
    # parse run was finished successful
    return;
}

# the annotator name for this importer
sub annotator_name {
    return "GenBank Importer";
}

# helper for creating and retrieving the annotator 
# object of this module
sub _get_annotator {
    my $annotator = GENDB::annotator->init_name(&annotator_name);
    if ($annotator == -1) {
	$annotator = GENDB::annotator->create();
	$annotator->name(&annotator_name);
	$annotator->description('EMBL data import module');
    }
    return $annotator;
}

# cycles through each GenBank entry and imports
# the entry itself and each CDS
#
# the callback is called with two parameters, error msg
# and error content
# 
# error codes (so far):
# 
# 'not_unique' - content is the name of the GenBank entry
#                callback returns :
#                 0       - skip this entry
#                -1       - abort import
#                'string' - rename entry and try again
# 'inform'     - content is a message to be displayed
# 'status'     - update status message if supported

sub import_data {
    my ($self, $callback) = @_;

    my $names_at_db = GENDB::contig->contig_names;

    # extract all sequence from GenBank parser
    
    my @names=keys %{$self->{entries}};

    # check whether the entry names are unique

    my $accepted = {};
    foreach (@names) {
	while ($names_at_db->{$_}) {
	    my $new_name= &$callback('not_unique',
				     $_);
	    if ($new_name eq -1) {
		return "Aborted by user";
	    }
	    if ($new_name eq 0) {
		delete $self->{entries}->{$_};
		last;
	    }
	    if (!exists $self->{entries}->{$new_name}) {
		$self->{entries}->{$new_name}=$self->{entries}->{$_};
		delete $self->{entries}->{$_};
		$_=$new_name;
	    }
	    else {
		&$callback('inform',"New name $new_name is already part of GenBank file, please choose another one");
	    }
	}
	$accepted->{$_}=$self->{entries}->{$_} if exists $self->{entries}->{$_};
	delete $self->{entries}->{$_};
    }

    # %accepted contains all Bio::Seq objects which
    # names are unique 

    # prepare annotation entry
    my $annotator = _get_annotator;
    my $orf_counter = 1;
    my $cds_feature = GENDB::feature_type->init_by_feature_name('CDS');

    # import these objects into GENDB
    foreach my $seq_name (keys %$accepted) {
	my $seq_obj = $accepted->{$seq_name};
	&$callback('status',"Importing $_ .....");
	my $sequence = lc ($seq_obj->seq);
	my $new_contig=GENDB::contig->create($seq_name,
					     $sequence);
	$new_contig->length(length $sequence);
	foreach my $feature ($seq_obj->all_SeqFeatures()) {
	    if ($feature->primary_tag eq 'CDS') {
		my $start;
		my $stop;
		
		# analyse the strand of this feature and 
		# set frame according to strand, start and stop
		my $frame;
		next if ($feature->strand == 0);
		if ($feature->strand < 0) {
		    $start = $feature->start;
		    $stop  = $feature->end;
		    $frame = -($start % 3);
		    if ($frame == 0) {
			$frame = -3;
		    }
		}
		else {
		    $start = $feature->start;
		    $stop  = $feature->end;
		    $frame = $start % 3;
		    if ($frame == 0) {
			$frame = 3;
		    }
		}
		
		# create orf 
		my $orf=GENDB::orf->create($new_contig->id,
					   $start, $stop,
					   $new_contig->name."_$orf_counter");
		$orf_counter++;
		
		# set information about this orf
		$orf->frame($frame);
		
		my $orf_aa_seq = &get_tag($feature,"translation");
		$orf->molweight(GENDB::Common::molweight($orf_aa_seq));
		$orf->isoelp(GENDB::Common::calc_pI($orf_aa_seq));
		
		my $dna_seq = substr ($sequence, $start -1, $stop - $start + 1);
		if ($frame < 0) { 
		    $dna_seq = reverse_complement ($dna_seq);
		}
		$orf->startcodon(substr($dna_seq,0,3));
		
		# count Gs and Cs...
		my $gs = ($dna_seq =~ tr/g/g/);
		my $gcs = ($dna_seq =~ tr/c/c/) + $gs;
		
		# count As and Gs...
		my $ags = ($dna_seq =~ tr/a/a/) + $gs;
		$orf->gc(int ($gcs / length ($dna_seq) * 100));
		$orf->ag(int ($ags / length ($dna_seq) * 100));
		
		# create an annotation about this orf
	        # and fill in information from feature
	        # qualifiers
		
		my $annotation=GENDB::annotation->create(&get_tag($feature,"gene"), $orf->id);
		$annotation->date(time());
		$annotation->annotator_id($annotator->id);
		if ($feature->has_tag('product')) {
		    $annotation->product(&get_tag($feature,'product'));
		};
		if ($feature->has_tag('EC_number')) {
		    $annotation->ec(&get_tag($feature,'EC_number'));
		};
		if ($feature->has_tag('function')) {
		    $annotation->description(&get_tag($feature,'function'));
		}
		$annotation->feature_type($cds_feature);
		my $note;
		if ($feature->has_tag('note')) {
		    $note=&get_tag($feature,'note');
		} 
		if ($feature->has_tag('db_xref')) {
		    if (!$note) {
			$note="/db_xref=".&get_tag($feature,'db_xref');
		    }
		    else {
			$note .=" /db_xref=".&get_tag($feature,'db_xref');
		    }
		};
		$annotation->comment($note);
		$orf->status($ORF_STATE_ANNOTATED);
	    }
	}
    }
}


sub get_tag {
    my ($feature, $tag_name) = @_;
    return join ("", $feature->each_tag_value($tag_name));
}
