#!/usr/bin/env perl
# $Id: dump2gb.pl,v 1.1 2007/01/29 01:00:00 smithda Exp $
# Ref: http://www.bioperl.org/wiki/HOWTO:Feature-Annotation#Building_Your_Own_Sequences
use warnings;
use strict;
use Carp;
use vars qw/ $opt_p $opt_f $opt_l $opt_o $opt_c $opt_P $opt_i $opt_I $opt_r /;
use Getopt::Std;
use Bio::SeqIO;
use Bio::Species;
use Bio::SeqFeature::Generic;
use Bio::Annotation::Collection;
use Bio::Annotation::Comment;
use lib '/home/sgivan/projects/BGA/share/genDB/share/perl';
use lib '/home/sgivan/projects/COGDB';
use Projects;
use COGDB;
use POSIX qw(strftime);


my $USAGE  = <<USAGE;
Extracts information from genDB and other local sources.

Usage: $0 -p <project_name> <options> 


       OPTIONS:
       --------------------------------------------------------------------------------
       -f format                     Output format, recognized by BioPerl.
                                     default: genbank

       -l 'orf1,orf2,...'            Limit to these ORFs. (Implies -i)
                                     default: all ORFs

       -P                            Output a.a. instead of DNA for individual entries.

       -i                            Individually display each orf, instead of as
                                     features on the contig's sequence.
				     
       -r (0 or 1)                   Display RNA elements? 0 => no; 1 => yes.
                                     default: 1

       -c 'contig1,contig2,...'      Limit to these contigs.
                                     default: all contigs

       -o filename                   Output file.
                                     default: STDOUT

       -I                            Display information about this project.
                                     Overides all other options.

USAGE

getopts('PiIp:f:l:r:c:o:');
my $project     = $opt_p || die $USAGE;
my $format      = $opt_f || 'genbank';
my $disp_P      = $opt_P;
my $include_rna = defined($opt_r) ? $opt_r : 1;
my @getorfs     = $opt_l ? split(/\s*[\,]+\s*/, $opt_l) : ();
my @contigs     = $opt_c ? split(/\s*[\,]+\s*/, $opt_c) : ();

# Set up our output object
my %io_args = ('-format' => $format, '-verbose' => -1);
if ($opt_o) { $io_args{'-file'} = ">$opt_o"; }
else        { $io_args{'-fh'}   = \*STDOUT;  }
my $io = Bio::SeqIO->new(%io_args);

# If the user just wants specific orfs or sets -i,
# don't dump the whole DNA sequence of its contig.
my $dump_ctg = (scalar(@getorfs) || $opt_i) ? 0 : 1;

# For information on translation options, see
# http://www-biocomp.doit.wisc.edu/bptutorial.html
my @t_opts = (undef, undef, undef, undef, 1);


# Initialize this project name
Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;
require GENDB::orf_names;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::funcat;


#------------------------------------------------------------------------------#
# Set up our COG database interface.                                           #
#------------------------------------------------------------------------------#
my $cogdb   = COGDB->new();
my $local   = $cogdb->localcogs();
my $cog_org = $local->organism({Code => $project});
my $whogdb  = $local->whog();


#------------------------------------------------------------------------------#
# If -I flag is set, then output a bunch of information and exit.              #
#------------------------------------------------------------------------------#
if ($opt_I) {
	my $sets = [];
	
	# Fetch information on each individual contig
	my %contigs = %{GENDB::contig->fetchallby_name()};
	foreach (map($contigs{$_}, sort keys %contigs)) {
		push @{$sets}, [$_->name(), $_->length(), scalar(keys %{$_->fetchorfs()})];
	}
	
	# Sum the lengths and # of orfs
	my @sum = (scalar(keys %contigs), 0, 0);
	foreach my $a (@{$sets}) { $sum[1] += $a->[1]; $sum[2] += $a->[2]; }
	
	# Headers and Summations
	unshift @{$sets}, ["Contig Name", "Length (nt)", "# of Orfs"], ["","",""];
	push @{$sets}, ["","",""], ["Total [$sum[0]]", $sum[1], $sum[2]] if ($sum[0] > 1);
	
	# Right-pad each value to make spacing even among columns
	my @w = (0,0,0);
	foreach my $a (@{$sets}) { @w =  map(max($w[$_], length($a->[$_])),     0..2);  }
	foreach my $a (@{$sets}) { $a = [map(sprintf("%-*s", $w[$_], $a->[$_]), 0..2)]; }
	
	# Display the data
	print "\n$project: ". $cog_org->name() ."\n\n";
	print "  ". join("    ", @{$_}) ."\n" foreach (@{$sets});
	print "\n";
	
	exit;
}


#------------------------------------------------------------------------------#
# Check for good contig names in input.                                        #
#------------------------------------------------------------------------------#
foreach (@contigs) { 
	die ("Bad Contig Name: $_\n") if (GENDB::contig->init_name($_) == -1);
}


#------------------------------------------------------------------------------#
# Grab all the relevant contig objects for this project.                       #
#------------------------------------------------------------------------------#
if (scalar(@contigs)) { @contigs = map(GENDB::contig->init_name($_),@contigs); }
else                  { @contigs = values %{GENDB::contig->fetchallby_name()}; }
@contigs = sort { substr($a->name(), 1) <=> substr($b->name(), 1) } @contigs;


#------------------------------------------------------------------------------#
# Cache re-usuable objects.                                                    #
#------------------------------------------------------------------------------#
my $annotators = GENDB::annotator->fetchallby_id();
my $funcats    = GENDB::funcat->fetchallby_id();


#------------------------------------------------------------------------------#
# Now start processing the ORFs.                                               #
#------------------------------------------------------------------------------#
foreach my $contig (@contigs) {
	
	# $ctg_seq holds all the information about the current contig
	my $ctg_seq = Bio::Seq->new( -display_id  => $contig->name(),
		                     -seq         => $contig->sequence(),
				     -verbose     => -1);
	
	#----------------------------------------------------------------------#
	# Figure out our taxonomy as best we can.                              #
	#----------------------------------------------------------------------#
	if (length($cog_org->name())) {
		my @taxonomy = reverse split(/\s+/, $cog_org->name());
		$ctg_seq->species(Bio::Species->new(-classification => [@taxonomy]));
	}
	
	#----------------------------------------------------------------------#
	# Loop through all the ORFs on this contig.                            #
	#----------------------------------------------------------------------#
	my $sql  = "`contig_id`=". $contig->id() ." ORDER BY `start` ASC";
	my @orfs = @{GENDB::orf->fetchbySQL($sql)};
	foreach my $orf (@orfs) {
		
		# Reminder: @getorfs are the ones that the user asked for.
		next if (scalar(@getorfs) && !grep($orf->name() eq $_, @getorfs));
		next if ($orf->status() && $orf->status() == 2);
		
		#--------------------------------------------------------------#
		# Fetch the most recent annotations.                           #
		#--------------------------------------------------------------#
		$sql = "`orf_id`=". $orf->id() ." ORDER BY `date` DESC LIMIT 1";
		my $annotation = shift @{GENDB::annotation->fetchbySQL($sql)};
		
		#--------------------------------------------------------------#
		# If genDB gives us an out-of-range value then fix it.         #
		#--------------------------------------------------------------#
		my $bad_trunc_notice = undef;
		my ($trunc_start, $trunc_end) = ($orf->start(), $orf->stop());
		if ($trunc_start < 1 || $trunc_end > $ctg_seq->length()) {
			$bad_trunc_notice = $orf->name() ." extends beyond the contig,".
			                    " therefore a truncated version of ". 
					    $orf->name() ."'s sequence is displayed.";
			if ($trunc_start < 1) {
				$trunc_start = 1;
				$trunc_start = $trunc_start + ($trunc_end % 3);
			}
			if ($trunc_end > $ctg_seq->length()) {
				$trunc_end = $ctg_seq->length();
				$trunc_end = $trunc_end - ((($trunc_end - $trunc_start) + 1) % 3);
			}
		}
		
		#--------------------------------------------------------------#
		# Generate the nucleotide sequence.                            #
		#--------------------------------------------------------------#
		my $orf_seq = $ctg_seq->trunc($trunc_start, $trunc_end);
		   $orf_seq = $orf_seq->revcom() if ($orf->frame() < 0);
		
		#--------------------------------------------------------------#
		# Add all the custom fields                                    #
		#--------------------------------------------------------------#
		my $tags = {};
		   $tags->{'Locus_Tag'} = $orf->name();
		
		if ($annotation != -1) {
			$tags->{'Date'}      = [localtime $annotation->date()]         if ($annotation->date());
			$tags->{'Date'}      = strftime "%b %e %Y", @{$tags->{'Date'}} if ($annotation->date());
			$tags->{'Product'}   = $annotation->product()                  if ($annotation->product());
			$tags->{'EC_Number'} = $annotation->ec()                       if ($annotation->ec());
			$tags->{'Gene'}      = $annotation->name()                     if ($annotation->name());
			$tags->{'Comment'}   = $annotation->comment()                  if ($annotation->comment());
			$tags->{'Comment'}   =~ s/\n/\ /g                              if ($annotation->comment());
			$tags->{'Notice'}    = $bad_trunc_notice                       if ($bad_trunc_notice);
			
			if (defined($annotation->annotator_id())) {
				my $annotator = $annotators->{$annotation->annotator_id()};
				$tags->{'Annotator'} = $annotator->description() if ($annotator->description());
			}
			
			if (defined($annotation->category())) {
				my $funcat = $funcats->{$annotation->category()};
				my @funcats = ($funcat->name());
				while ($funcat->parent_funcat() != 0) {
					$funcat = $funcats->{$funcat->parent_funcat()};
					unshift @funcats, $funcat->name();
					last if (scalar(@funcats) > 50); # Emergency exit
				}
				$tags->{'Category'} = join(" => ", @funcats);
			}
		}
		
		
		#--------------------------------------------------------------#
		# Retrieve the COG information.                                #
		#--------------------------------------------------------------#
		my $whogs = $whogdb->fetch_by_name({ name => $orf->name(), organism => $cog_org });
		if ($whogs) {
			my @cog_summaries = ();
			foreach my $cog (map($_->cog(), @{$whogs})) {
				my @cats = map($_->name(), @{$cog->categories()});
				
				my $cog_summary  = $cog->name();
				   $cog_summary .= ": ". $cog->description()    if ($cog->description());
				   $cog_summary .= " [". join("; ", @cats) ."]" if (@cats);
				
				push @cog_summaries, $cog_summary;
			}
			
			$tags->{'COGs'} = join(", ", @cog_summaries);
		}
		
		
		#--------------------------------------------------------------#
		# How should we display the sequences in the 2 locations?      #
		#--------------------------------------------------------------#
		if ($orf->name() !~ m/[rt]RNA/i) {
			if ($disp_P) {
				$orf_seq = $orf_seq->translate(@t_opts);
				$orf_seq->alphabet('protein');
			} else {
				$tags->{'Translation'} = $orf_seq->translate(@t_opts)->seq();
				$orf_seq->alphabet('dna');
			}
		}
		else {
			next if ($include_rna == 0);
			
			$tags->{'RNA_Transcript'} = $orf_seq->seq();
			$tags->{'RNA_Transcript'} =~ tr/T/U/;
			$orf_seq->alphabet('dna');
		}
		
		#--------------------------------------------------------------#
		# Create a feature that describes this section of the contig.  #
		#--------------------------------------------------------------#
		my $ctg_feat = new Bio::SeqFeature::Generic(-primary => 'CDS',
							    -start   => $trunc_start,
							    -end     => $trunc_end,
							    -strand  => $orf->frame() > 0 ? 1 : -1,
							    -tag     => $tags);
		
		
		#--------------------------------------------------------------#
		# If we're dumping the entire contig, this will be a feature   #
		# on $ctg_seq. If not, we'll make this its own sequence object.#
		#--------------------------------------------------------------#
		if ($dump_ctg) {
			$ctg_seq->add_SeqFeature($ctg_feat);
		} else {
			my $valid_id = $orf->name();
			   $valid_id =~ s/\s*\(.*\)//;
			   $valid_id =~ tr/\ /\_/;
			
			my $seq = Bio::Seq->new(-display_id => $valid_id, 
			                        -seq        => $orf_seq->seq());
			
			# Inherit the species from the contig when applicable
			if (!$dump_ctg && $ctg_seq->species()) {
				$seq->species($ctg_seq->species());
			}
			
			# Create the definition line
			my $def_line = $tags->{'Product'} ||  $tags->{'Gene'} || "";
			   $def_line =~ s/\s*(\[.*?\]|\(.*?\))\s*//g;
			$seq->description($def_line);
			
			# Describe the location where this sequence came from
			# i.e. complement(SAR11_chromosome:857000..858000)
			$tags->{'coded_by'} = $ctg_feat->location()->to_FTstring();
			substr($tags->{'coded_by'}, index($tags->{'coded_by'}, "(") + 1, 0, $contig->name() .":");

			my $seq_feat = new Bio::SeqFeature::Generic(-primary => 'CDS',
								    -start   => 1,
								    -end     => $ctg_feat->length(),
								    -tag     => $tags);
			$seq->add_SeqFeature($seq_feat);
			$io->write_seq($seq);
		}
		
	} # end foreach (@orfs)
	
	$io->write_seq($ctg_seq) if ($dump_ctg);
	
} # end foreach (@contigs)

sub min {
	my $min = shift;
	foreach (@_) { $min = $_ if ($_ < $min); }
	return $min;
}

sub max {
	my $max = shift;
	foreach (@_) { $max = $_ if ($_ > $max); }
	return $max;
}

