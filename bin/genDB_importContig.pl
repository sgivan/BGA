#!/usr/bin/env perl
# $Id: genDB_importContig.pl,v 3.2 2007/07/11 20:48:11 givans Exp $
#
use warnings;
use strict;
use Carp;

use Getopt::Std;
#use Bio::Seq::SeqFactory;
use Bio::SeqIO;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;
use vars qw/ $opt_p $opt_f $opt_v $opt_d $opt_h $opt_m $opt_k /;
use vars qw/ $ORF_STATE_ATTENTION_NEEDED $ORF_STATE_IGNORED $ORF_STATE_ANNOTATED $ORF_STATE_FINISHED /;

getopts('p:f:m:vdhk');

my $project = $opt_p;
my $infile = $opt_f;
my $model_file = $opt_m || 'model';
my $verbose = $opt_v;
my $debug = $opt_d;
my $help = $opt_h;
my $keep_all = $opt_k;# keep every contig, even if no ORFs are identified

if ($help) {
	help();
	exit(1);
}

if (!$project || !$infile) {
	help();
	exit(1);
}

Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;
require GENDB::Tools::Importer::Fasta;
#require GENDB::Tools::Glimmer2;
require GENDB::Tools::Glimmer3;
require GENDB::Tools::tRNAScan;
require GENDB::Common;
require GENDB::Config;
require File::Basename;
require GENDB::annotator;

print "\n\ngenDB_importContig\n";

my $importer = GENDB::Tools::Importer::Fasta->new($infile);

my $icontigs = $importer->contigs();
my $cnt = 0;
my @contigs = keys(%$icontigs);
#while (my($id,$seq) = each(%$icontigs)) {
foreach my $id (@contigs) {
	my $seq = $icontigs->{$id};
	++$cnt;
	print "contig id: '$id'\n";

	my $rtn = $importer->import_contigs(\&error_mssg);
	
# 	if ($rtn) {
# 		print "\$rtn = '$rtn'\n";
# 		#last;
# 	}
	#print "creating GENDB::Tools::Glimmer2 object\n";
#	my $glimmer = GENDB::Tools::Glimmer2->new();
	my $glimmer = GENDB::Tools::Glimmer3->new();
	$glimmer->verbose(1);
	$glimmer->model_file($model_file);
	#$glimmer->statusmessage(\$msg);
	
	#foreach $contig (@{GENDB::contig->fetchall}) {
	$glimmer->add_sequence($id, $seq);
	my $sequences = $glimmer->sequences();
# 	if (ref($sequences) eq 'HASH') {
# 		hashdump($sequences);
# 	} else {
# 		die "Glimmer2 object contains no sequences\n";
# 	}
	#}	
	
	$glimmer->linear_contig(1);
	print "running glimmer\n";
	$glimmer->run_glimmer();
	
	
	my %contigs;
	
	my $orfs_ref = $glimmer->orfs();
	if ($orfs_ref) {
# 		print "\$orfs_ref is a '", ref($orfs_ref), "'\n";
# 		if (ref($orfs_ref) eq 'HASH') {
# 			hashdump($orfs_ref);
# 		}
	} else {
        unless ($keep_all) {
            print "glimmer produced no ORFs.\nDeleting contig '$id'\n";
            GENDB::contig->init_name($id)->delete();
            #exit(1);
        }
	}
	
	# get annotator for glimmer import
	#print "checking if 'glimmer' is a valid annotator\n";
	my $annotator = GENDB::annotator->init_name("glimmer");
	if ($annotator == -1) {
		#print "must create a new annotator for 'glimmer'\n";
		# create a default glimmer annotator
		print "*** Creating default glimmer annotator! ***\n";
		$annotator = GENDB::annotator->create();
		$annotator->name("glimmer");
		$annotator->description("Glimmer ORF finder");
	} else {
		#print "'glimmer' is already an annotator\n";
	}
	#
	# I took most of the rest of this code directly from
	# the GENDB::GUI::Import module
	#
	foreach $seq (keys %$orfs_ref) {
		#print "\$seq = '$seq'\n";
		my $contig = $contigs{$seq};
		if(!defined $contig) {
				$contig = GENDB::contig->init_name($id);
				$contigs{$seq} = $contig;
		}
		
		if ($contig < 0) {
				die "Cannot get contig $seq.....\n";
		}
	
		# get a list of ORFs stored in DB 
		# and a list of all predicted ORFs
		my @orfs_in_db = sort {$a->start <=> $b->start} values (%{$contig->fetchorfs});
		my @generated_orfs = @{$orfs_ref->{$seq}};
		@generated_orfs = sort {$a->{'from'} <=> $b->{'from'}} @generated_orfs;
	
		# this is a mean hack
		# we need to know the highest id allready stored in db
		# (id = "<sequencename>_000x")
		my $next_orf_id = 0;
		foreach (my @orfs_in_db) {
				my ($junk,$orf_id) = split "_", $_->name();
				$next_orf_id = $orf_id if ($orf_id > $next_orf_id);
		}
		$next_orf_id++;
	
					# lets do a cross check of both lists
		# new ORFs (ORF not in db) shall be created,
		# old ORFs (ORF in db, but not in @generated_orfs)
		# are marked "attention needed"
		for (my $i = 0; $i< scalar(@generated_orfs); $i++) {
				
			if (defined ($orfs_in_db[0])) {
				while ($orfs_in_db[0]->start < $generated_orfs[$i]->{'from'}) {
						
						# annotated and finished are not touched by this
		
					if (($orfs_in_db[0]->state != $ORF_STATE_ATTENTION_NEEDED) || ($orfs_in_db[0]->state != $ORF_STATE_IGNORED) || ($orfs_in_db[0]->state != $ORF_STATE_ANNOTATED) || ($orfs_in_db[0]->state != $ORF_STATE_FINISHED)) {
					# these ORFs has been deprecated, so mark them
						$orfs_in_db[0]->status($ORF_STATE_ATTENTION_NEEDED);
						my $annotation=GENDB::annotation->create('',$orfs_in_db[0]->id);
						if ($annotation < 0) {
							die "can't create annotation object for $annotation\n";
						}
					
					# set annotator to glimmer
						$annotation->annotator_id($annotator->id);
						$annotation->description('ORF was deprecated by another glimmer2-run');
						$annotation->date(time());
					}	
						
						shift @orfs_in_db;
				}
				
				# both orfs got the same start position,	   
				if ($orfs_in_db[0]->start == $generated_orfs[$i]->{'from'}) {
						if ($orfs_in_db[0]->stop == $generated_orfs[$i]->{'to'}) {
					# if start and stop position are the same,
					# this orf is already in database
							shift @orfs_in_db;
							next;
						}
				}
			}
				my $orf_data = $generated_orfs[$i];
				
				# create a new orf
				my $orf_prefix = "C".$contig->id;
				my $orfname=sprintf ("%s_%004d",$orf_prefix,$next_orf_id);
				$next_orf_id++;
				
				my $orf=GENDB::orf->create($contig->id,
								$orf_data->{'from'},
								$orf_data->{'to'},
								$orfname);
				if ($orf < 0) {
					die "can't create orf object for $orfname\n";
				}
				
				# fill in information
				$orf->status(0); # status is putative
				$orf->frame($orf_data->{'frame'});
				$orf->startcodon ($orf_data->{'startcodon'});
				
				my $orf_aaseq = $orf->aasequence();
				$orf->isoelp(GENDB::Common::calc_pI($orf_aaseq));
	
				# there's a name clash !
				# calling $orf->molweight uses GENDB::Common::molweight
				# damnit importing of symbols !
				# we should fix this as soon as possible
				my $molweight = GENDB::Common::molweight($orf_aaseq);
				GENDB::orf::molweight($orf, $molweight);
		
				my $orf_seq= $orf->sequence();
		
				# count Gs and Cs...
				my $gs = ($orf_seq =~ tr/g/g/);
				my $gcs = ($orf_seq =~ tr/c/c/) + $gs;
		
				# count As and Gs...
				my $ags = ($orf_seq =~ tr/a/a/) + $gs;
				$orf->gc(int ($gcs / length ($orf_seq) * 100));
				$orf->ag(int ($ags / length ($orf_seq) * 100));
							
				my $annotation=GENDB::annotation->create('',$orf->id);
				if ($annotation < 0) {
					die "can't create annotation object for $annotation\n";
				}
				
				# set annotator to glimmer
				$annotation->annotator_id($annotator->id);
				my $comment = $orf_data->{'comment'};
				# set comment to glimmer comment
				if (defined $comment) {
					$annotation->comment($comment);
				}
				$annotation->name($orfname);
				$annotation->description('ORF created by glimmer2');
				$annotation->date(time());
		}
		
		#
		# end of code taken from GENDB::GUI::Import 
		#
		#
		# run tRNAScan-SE on contig
		print "running tRNAScan-SE\n";
		GENDB::Tools::tRNAScan::run_on_contig($contig);
		print "finished with '", $contig->name(), "'\n\n";
	}
}

sub error_mssg {
	my ($category,$message) = @_;
	
	print "ERROR: $category; $message\n\n";
	exit(0);
}

sub help {
print <<HELP;

Script to import a contig into a GenDB project.  Sequence file must
be in FASTA format and GenDB project must already exist.

usage:  genDB_importContig.pl -p project_name -f input_file [ -v -d -h ]

options
-p		project name
-f		input file in fasta format
-m		specify Glimmer2 model file [defaults to 'model']
-v		verbose output to terminal
-d		debugging mode
-h		print this help menu



HELP
}

sub hashdump {
	my $hashref = shift;
	
	while (my($key,$value) = each %$hashref) {
		print "key: '$key'; value: '$value'\n";
	}
}
