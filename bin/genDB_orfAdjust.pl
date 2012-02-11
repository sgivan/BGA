#!/usr/bin/env perl
# $Id: genDB_orfAdjust.pl,v 3.4 2005/06/02 02:32:34 givans Exp $

#use warnings;
use strict;
use Carp;
use Getopt::Std;
use vars qw/ $opt_d $opt_v $opt_h $opt_f $opt_p $opt_c $opt_D $ORF_STATE_ANNOTATED $opt_a $opt_A /;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('f:p:c:dDvhaA');

my($debug,$help,$verbose,$infile,$project,$contig_name,$contig,@rbs);

my $description = <<HELP;

This script uses the output of the TIGR script rbs_finder.pl,
which adusts ORF start codons based upon ribosome binding site
information, to adjust the start codons of ORFs in GenDB annotation
projects.

Command-line Options

-f	input file of rbs_finder.pl data
-p	name of GenDB annotation project
-c	contig identifier in GenDB
-a	enter a new GenDB annotation for changed ORFs
-D	drop facts after changing start coordinate
-A	adjust start and stop coordinates (if using glimmer output)
-v	verbose output
-d	debugging mode
-h	print this help menu


HELP

$debug = $opt_d;
$verbose = $opt_v;
$verbose = 1 if ($debug);

if ($opt_h) {
  print "$description\n";
  exit(0);
}

$infile = $opt_f;
$project = $opt_p;

if (!$infile || !$project) {
  print "usage:  genDB_orfAdjust.pl -f <rbs_finder.pl data> -p <genDB project name> <options>\n";
  exit(0);
}

if (!-e $infile) {
  print "'$infile' doesn't exist in this directory\n";
  exit(0);
} else {
  print "opening $infile\n" if ($verbose);
  open(RBS,$infile) or die "can't open '$infile': $!";
  @rbs = <RBS>;
  close(RBS);
}

Projects::init_project($opt_p);
require GENDB::orf;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::contig;
require GENDB::Common;
require Job;

$contig_name = $opt_c;
if (!$contig_name) {
  print "Which contig are you working with?\n";
  my $contigs = GENDB::contig->contig_names();
  foreach my $cont_name (keys %{$contigs}) {
    print "\t$cont_name\n";
  }
  $contig_name = <STDIN>;
  chomp($contig_name);
}

$contig = GENDB::contig->init_name($contig_name);
if (!$contig) {
  print "can't initialize that contig\n";
  die();
} else {
  print "contig '$contig_name' initialized\n" if ($verbose);
}

print "contig name: '", $contig->name(), "'\n" if ($debug);
my $annotator = GENDB::annotator->init_name('orfAdjust');
my $cnt = 0;
foreach my $line (@rbs) {
  ++$cnt;
  last if ($debug && $cnt > 100);
  next unless ($cnt > 2);

  $line =~ s/^\s+//;
  my($geneID,$newStart,$rbs_stop,$rbs_pattern,$rbs_site,$newStartCodon,$shift,$oldStartCodon,$oldStart) = split /\s+/, $line;

  if ($shift) {			## start site has changed
    print "\n\n$geneID has shifted $shift nt\n" if ($debug);
    my $frame;
    my ($start,$stop,$frame) = startstop($oldStart,$rbs_stop);

    print "attempting to inialize orf with:\n\tstart=$start\n\tstop=$stop\n" if ($debug);
    my $orf = $contig->fetchorfs_exact($start,$stop); # fetchorfs_exact() is a CGRB extension

    foreach my $orfname (keys %{$orf}) {
      my $orf = $orf->{$orfname}; ## GENDB::orf object

      print "orfname: '$orfname'\tstart: ", $orf->start(), "\tstop: ", $orf->stop, "\n" if ($verbose);

      if ($frame > 0) {
	print "changing start positions to $newStart\n" if ($verbose);
	$orf->start($newStart) unless ($debug);
      } else {
	print "changing start position (GenDB stop position) to $newStart\n" if ($verbose);
	$orf->stop($newStart) unless ($debug);
      }

      if ($debug) {
	print "setting start codon from ", uc($orf->startcodon()), " to $newStartCodon\n";
      } else {
	$orf->startcodon($newStartCodon);

	my $orf_aaseq = $orf->aasequence();
	$orf->isoelp(GENDB::Common::calc_pI($orf_aaseq));
	my $MW = GENDB::Common::molweight($orf_aaseq);
	GENDB::orf::molweight($orf,$MW);

	if ($opt_D) {
	  $orf->drop_facts() if ($opt_D);

	  $orf->toollevel(0);
	  for (my $job_id = $orf->order_next_job; $job_id != -1; $job_id = $orf->order_next_job) {
	    Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
	  }
	}

	if ($opt_a) {
	  my $annotation = GENDB::annotation->create("", $orf->id());
	  $annotation->annotator_id($annotator->id());
	  $annotation->date(time());
	  $annotation->comment("Start position changed from $oldStart to $newStart based on potential RBS ($rbs_pattern) at nt $rbs_site");
	  $orf->status('1');
	}
      }
    }
  }
}

sub startstop {
  my ($start,$stop) = @_;

  print "startstop:  \$start = $start, \$stop = $stop\n" if ($debug);
  my $frame = 1;
  if ($start > $stop) {
    my $temp = $start;
    $start = $stop;
    $start -= 3 if ($opt_A);
    $stop = $temp;
    $frame = '-1';
  } else {
    $stop += 3 if ($opt_A);
  }
  print "startstop:  returning \$start = $start, \$stop = $stop, \$frame = $frame\n" if ($debug);
  return ($start,$stop,$frame);
}


# This is how GenDB updates an ORF ...

# sub updateORF {

#     my( undef, $self, $dialog ) = @_;

#     &setstartposition($self, $self->{startposition});

#     if (($self->{startposition} != $self->{oldstartposition}) ) {

# 	### compute new molweight and iep
# 	my $orf = $self->{orf};
# 	my $orf_aaseq = $orf->aasequence();
# 	$orf->isoelp(GENDB::Common::calc_pI($orf_aaseq));

# 	# there's a name clash !
# 	# calling $orf->molweight uses GENDB::Common::molweight
# 	# damnit importing of symbols !
# 	# we should fix this as soon as possible
# 	# IC IC IC IC IC 
# 	my $molweight = GENDB::Common::molweight($orf_aaseq);
#       GENDB::orf::molweight($orf, $molweight);

# 	Utils::show_yesno("ORF start position has been changed, delete old facts and rerun tools ?", 
# 		   $self,
# 		   sub{ &make_new_facts( $self ); main->update_orfs; $dialog->destroy },
# 		   sub{  }
# 		   );
#     }

# }

# sub setstartposition {
#     my ($self, $newposition) = @_;

#     if ($self->{frame} > 0) {
# 	if (($newposition < $self->{stopposition}) &&
# 	    (($self->{stopposition} - $newposition) % 3 == 2)) {
# 	    $self->{orf}->start($newposition);
# 	    $self->{startposition} = $newposition;
# 	    $self->{orf}->startcodon(substr ($self->{orf}->sequence, 0, 3));
# 	    $self->{startcodon} = $self->{orf}->startcodon;
# 	}
#     }
#     elsif (($newposition > $self->{stopposition}) &&
# 	   (($newposition - $self->{stopposition}) % 3 == 2)) {
# 	$self->{orf}->stop($newposition);
# 	$self->{startposition} = $newposition;
# 	$self->{orf}->startcodon(substr ($self->{orf}->sequence, 0, 3));
# 	$self->{startcodon} = $self->{orf}->startcodon;
#     }
# }


#
# sub make_new_facts {
# my( $self ) = @_;
# 
# main->update_statusbar( "Rerunning Tools for ORF: ".$self->{orf}->name );
# 
# $self->{orf}->drop_facts;
# 
# # create an annotation entry
# my $annotator = GENDB::annotator->init_name($ENV{'USER'});
# my $annotation = GENDB::annotation->create("", $self->{orf}->id);
# $annotation->annotator_id ($annotator->id);
# $annotation->date(time);
# $annotation->description("ORF start position changed");
# $annotation->comment("Start position changed from ".$self->{oldstartposition}." to ".$self->{startposition});
# 
# # editing the orf start position is an annotation
# $self->{orf}->status($ORF_STATE_ANNOTATED);
# 
# 
# # reset toollevel and order tools
# $self->{orf}->toollevel(0);
# for ($job_id = $self->{orf}->order_next_job; $job_id != -1;
# $job_id = $self->{orf}->order_next_job) {
# Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
# }
# }

