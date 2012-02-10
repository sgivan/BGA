package GENDB::Tools::Importer::EMBL;

# EMBL importer for GENDB
# this class encapsulates the complete
# database management and error reporting

# $Id: EMBL.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: EMBL.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.4  2002/04/16 10:01:31  blinke
# /label-qualifiers of CDS features are used as ORF names, if they exists
#
# Revision 1.3  2001/11/12 17:06:41  blinke
# reworked to code to ensure the uniqueness of imported contig names
#
# Revision 1.2  2001/11/09 10:36:17  blinke
# fixed error message about unsupported CDS locations
#
# Revision 1.1  2001/11/09 09:26:21  blinke
# Initial revision
#

# use our full-featured EMBL parser

require Exporter;
@ISA=qw(GENDB::Tools::Importer);

use strict;

use lib "/vol/biotools/share/perl";
use SeqDB::PlaybackReader;
use IO::File;

use GENDB::contig;
use GENDB::orf;
use GENDB::annotator;
use GENDB::annotation;
use GENDB::Common;
use GENDB::feature_type;

1;

# since GENDB::Tools::Importer is some kind of
# useless class, overload the methods to implement
# a nice EMBL importer for GENDB


# create an instance of this importer
sub new {
    my ($class, $filename, $add_parameters) = @_;

    my $error_state;
    my $file = IO::File->new($filename);
    if (!ref $file) {
	$error_state = "Cannot open $filename for reading";
    }
    my $reader = SeqDB::PlaybackReader->new;
    $reader->load_file($file);
    my $self = { reader => $reader,
		 error_state => $error_state
		 };
    
    bless $self, ref $class || $class;
    return $self;

}


# parse the input file using the SeqDB parser
# catch all errors and report them
sub parse {
    my ($self) = @_;

    # return pending error
    if ($self->{error_state}) {
	return $self->{error_state};
    }

    # to decrease overall compilation time,
    # load the SeqDB only if it's really 
    # needed
    require SeqDB;

    my $main_parser = SeqDB->new;
    eval {$self->{parser}=$main_parser->parse($self->{reader})};
    if ($@) {
	# parsing was aborted due to errors
	$self->{error_state} = $@;
	
	# clean up
	eval {
	    if (ref $self->{parser}) {
		undef $self->{parser};
	    }
	    if (ref $self->{reader}) {
		undef $self->{reader};
	    }
	};
	return $self->{error_state};
    }
    # parse run was finished successful
    return;
}

# the annotator name for this importer
sub annotator_name {
    return "EMBL Importer";
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
    

# cycles through each EMBL entry and imports
# the entry itself and each CDS
#
# the callback is called with two parameters, error msg
# and error content
# 
# error codes (so far):
# 
# 'not_unique' - content is the name of the EMBL entry
#                callback returns :
#                 0       - skip this entry
#                -1       - abort import
#                'string' - rename entry and try again
# 'inform'     - content is a message to be displayed

sub import_data {
    my ($self, $callback) = @_;

    my $names_at_db = GENDB::contig->contig_names;

    # get all entries from EMBL parser
    my $entries = $self->{parser}->{entries};

    # check the entry name's
    my @names = keys %$entries;
    my $accepted = {};
    foreach (@names) {
	while ($names_at_db->{$_}) {
	    my $new_name= &$callback('not_unique',
				     $_);
	    if ($new_name eq -1) {
		return "Aborted by user";
	    }
	    if ($new_name eq 0) {
		delete %$entries->{$_};
		last;
	    }
	    if (!exists $entries->{$new_name}) {
		$entries->{$new_name}=$entries->{$_};
		delete $entries->{$_};
		$_=$new_name;
	    }
	    else {
		&$callback('inform',"New name $new_name is already part of EMBL file, please choose another one");
	    }
	}
	$accepted->{$_}=$entries->{$_};
	delete $entries->{$_};
    }

    # prepare annotation entry
    my $annotator = _get_annotator;
    my $orf_counter = 1;
    my $cds_feature = GENDB::feature_type->init_by_feature_name('CDS');
    # entry names are unique, import the entries
    foreach (keys %$accepted) {
	&$callback('status',"Importing $_ .....");
	my $sequence = $accepted->{$_}->sequence;
        my $contig=GENDB::contig->create($_, $sequence);
	$contig->length(length $sequence);
	foreach my $feature (@{$accepted->{$_}->featuretable->get_features}) {
	    # GENDB currently only supports CDs features
	    next if !($feature->feature_key eq 'CDS');
	    my $cds_location = $feature->location;
	    my $start;
	    my $stop;
	    my $frame;
	    if ($cds_location =~ /complement\((\d+)\.\.(\d+)/) {
		$start = $1;
		$stop = $2;
		$frame = -($start % 3);
		if ($frame == 0) {
		    $frame = -3;
		}
	    }
	    elsif ($cds_location =~ /(\d+)\.\.(\d+)/) {
		$start = $1;
		$stop = $2;
		$frame = $start % 3;
		if ($frame == 0) {
		    $frame = 3;
		}
	    }
	    else {
		&$callback('inform',"unsupported CDS location ($cds_location), OF skipped at entry ".$contig->name);
		next;
	    }
	    # create orf 
	    my $orf=GENDB::orf->create($contig->id,
				       $start, $stop,
				       ($feature->label) ? $feature->label :
				       $contig->name."_$orf_counter");
	    $orf_counter++;
	    
	    # set information about this orf
	    $orf->frame($frame);
	    my $orf_aa_seq = $feature->translation;
	    $orf->molweight(GENDB::Common::molweight($orf_aa_seq));
	    $orf->isoelp(GENDB::Common::calc_pI($orf_aa_seq));

	    my $dna_seq = $orf->sequence;
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
	    
	    my $annotation=GENDB::annotation->create($feature->gene, $orf->id);
	    $annotation->date(time());
	    $annotation->annotator_id($annotator->id);
	    if ($feature->product) {
		$annotation->product($feature->product);
	    };
	    if ($feature->EC_number) {
		$annotation->ec($feature->EC_number);
	    };
	    if ($feature->function) {
		$annotation->description($feature->function);
	    }
	    $annotation->feature_type($cds_feature);
	    my $note=$feature->note;
	    if ($feature->db_xref) {
		if (!$note) {
		    $note="/db_xref=".$feature->db_xref;
		}
		else {
		    $note .=" /db_xref=".$feature->db_xref;
		}
	    };
	    $annotation->comment($note);
	    $orf->status($ORF_STATE_ANNOTATED);
	}
    }
}
