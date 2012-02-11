#!/usr/bin/env perl
# $Id: genDB_getOrf.pl,v 3.12 2006/12/21 18:33:37 givans Exp $
use warnings;
use strict;
use Carp;
use vars qw/ $opt_d $opt_v $opt_h $opt_O $opt_o $opt_p $opt_u $opt_U $opt_D $opt_F $opt_f $opt_P $opt_c $opt_C $opt_I $opt_g $opt_G $opt_r /;
use Getopt::Std;
use Bio::Seq::SeqFactory;
use Bio::SeqIO;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('dvhO:o:p:u:D:Ff:Pc:C:UIgGrR');

my $usage = "genDB_getOrf.pl -p <project name> <options>";

if ($opt_h) {
  _help($usage);
  exit(0);
}

my ($project,$orfName,$outfile,$debug,$verbose,$upstream,$downstream,@orfs,$filter,$format,$contig_name,$minContigLen,$ignore,$ignoreOnly,$rna);

$debug = $opt_d;
$verbose = $opt_v;
$verbose = 1 if ($debug);

if ($opt_p) {
  $project = $opt_p;
} else {
  print "usage: $usage\n";
  exit(0);
}

if ($opt_O) {
  $orfName = $opt_O;
}

if ($opt_u) {
  $upstream = $opt_u;
} else {
  $upstream = 0;
}

if ($opt_D) {
  $downstream = $opt_D;
} else {
  $downstream = 0;
}

if ($opt_o) {
  $outfile = $opt_o;
}

if ($opt_F) {
  $filter = $opt_F;
} elsif (!$outfile) {
  $filter = 1;
}

if ($opt_f) {
  $format = $opt_f;
} else {
  $format = 'raw';
}

if ($opt_c) {
  $contig_name = $opt_c;
} else {
  $contig_name = undef;
}

$minContigLen = $opt_C || 5000;
#$ignore = $opt_g;
$ignoreOnly = $opt_G || 0;
$ignore = $ignoreOnly || $opt_g || 0;
$rna = $opt_r || undef;

#print "\$ignore = '$ignore', \$ignoreOnly = '$ignoreOnly'\n";
#exit();

my $seqio;
if ($outfile) {
  #  open(OUT,">$outfile") or die "can't open '$outfile': $!";
  $seqio = Bio::SeqIO->new(
			   -file	=>	">$outfile",
			   -format	=>	$format,
			  );
} else {
  #  open(OUT,">&STDOUT") or die "can't open STDOUT: $!";
  $seqio = Bio::SeqIO->new(
			   -fh		=>	\*STDOUT,
			   -format	=>	$format,
			  );
}

select(STDERR) if ($verbose || $debug);


Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;
#require GENDB::annotation;

my (%contig,@contigs);
my $factory = Bio::Seq::SeqFactory->new( -type => 'Bio::Seq' );

if ($contig_name) {
  push(@contigs,GENDB::contig->init_name($contig_name));
} else {
  @contigs = values %{GENDB::contig->fetchallby_name()};
}

foreach my $contig (@contigs) {
  @orfs = ();
#  next unless (length($contig->sequence()) > 5000);
  next unless (length($contig->sequence()) > $minContigLen);
  my $contig_bioseq = $factory->create( -id => $contig->name(), -seq => $contig->sequence());
  print "contig ", $contig->name(), " is ", $contig_bioseq->length(), "nt long\n" if ($debug);
  foreach my $orf (values %{$contig->fetchorfs()}) {
    if ($ignoreOnly) {
      next if ($orf->status() && $orf->status() != 2); # output only ignored ORFs
    } elsif (!$ignore) {
      next if ($orf->status() && $orf->status() == 2); # skip ignored ORFs
    } else {
      # include ignored ORFs
    }
    
    if ($rna) {
      next if ($orf->frame()); # skip regular ORFs, include tRNA's & rRNA's
    } else {
      next if (!$orf->frame()); # skip tRNA's and rRNA's
    }

    if ($orfName) {
      next unless ($orf->name() eq $orfName);
    }
    push(@orfs, $orf);
  }
  $contig{$contig->name()}{bioseq} = $contig_bioseq;
  $contig{$contig->name()}{orfs} = [@orfs];
} # end of foreach my $contig


if (! keys %contig) {

  foreach my $orf (@orfs) {
    my $sequence = $orf->sequence();

    if ($opt_P) {
      print "translating\n";
      $sequence = GENDB::Common->translate($sequence);
    }
    my $seq = $factory->create(
			       -id	=>	$orf->id(),
#			       -description	=>	$orf->description(),
			       -seq	=>	$sequence,
			      );

    print "orf name: ", $orf->name(), ", orf_id: ", $orf->id(), ", start: ", $orf->start(), ", stop: ", $orf->stop(), ", frame: ", $orf->frame(), "\n" if ($debug);

    if ($orf->frame > 0) {
    
    } else {

    }

  }
} else {

  foreach my $contigName (keys %contig) {
    print "contig '$contigName':  " if ($debug);
    my $contig = $contig{$contigName}{bioseq}; # $contig is a Bio::Seq object
    my $orfs = $contig{$contigName}{orfs}; # orfs are GENDB::orf objects
    print "length: ", $contig->length(), ", # or ORFs: ", scalar(@$orfs), "\n" if ($debug);
    my $orfcnt = 0;
    @orfs = sort { $a->start() <=> $b->start() } @$orfs;

    foreach my $orf (@orfs) {

      if ($opt_I) {
	my ($orf2,$useq,$ustart,$ustop);
	if ($orf->frame() > 0) { ## plus strand ORF
	  print "orf ", $orf->name(), " is on + strand\n" if ($debug);
	  $orf2 = $orfs[$orfcnt-1];
	  next unless ($orf2); # hack - won't process last ORF on chromosome
	  print "\tupstream ORF is ", $orf2->name(), "\n" if ($debug);
	  ($ustart,$ustop) = ($orf2->stop() + 1, $orf->start() - 1);
	  print "\tupstream region is: $ustart to $ustop\n" if ($debug);

	  if ($ustart < $ustop) {
	    print "\tvalid upstream region\n" if ($debug);

	    $useq = $factory->create(
				     -id		=>	$orf->name() . "_upstream",
				     -seq		=>	get_seq($contig,[$ustart,$ustop]),
				     -description	=>	"[$ustart : $ustop]",
				    );


	  } else {
	    print "\tinvalid upstream region\n" if ($debug);
	  }

	} elsif ($orf->frame() < 0) { ## minus strand ORF
	  print "orf ", $orf->name(), " is on - strand\n" if ($debug);
	  $orf2 = $orfs[$orfcnt+1];
	  next unless ($orf2); # hack - won't process last ORF on chromosome
	  print "\tupstream ORF is ", $orf2->name(), "\n" if ($debug);

	  ($ustart,$ustop) = ($orf->stop()+1,$orf2->start()-1);
	  if ($ustart < $ustop) {
	    print "\tvalid upstream region [$ustart:$ustop]\n" if ($debug);

	    $useq = $factory->create(
				     -id		=>	$orf->name() . "_upstream",
				     -seq		=>	get_seq($contig,[$ustart,$ustop]),
				     -description	=>	"[$ustop : $ustart]",
				    )->revcom();


	  } else {
	    print "\tinvalid upstream region [$ustart:$ustop]\n" if ($debug);
	  }

	}

	if ($useq && $useq->isa('Bio::PrimarySeqI')) {
	  print "\t\tupstream sequence: '", $useq->seq(), "'\n" if ($debug);
	  $seqio->write_seq($useq);
	}

	++$orfcnt;

      } else { ## end of if $opt_I
	++$orfcnt;
	print "orf name: ", $orf->name(), ", orf_id: ", $orf->id(), ", start: ", $orf->start(), ", stop: ", $orf->stop(), ", frame: ", $orf->frame(), "\n" if ($debug);
	my @orfCoords = orfCoords($orf);

	my $orfSeq = get_seq($contig,\@orfCoords);

	if ($orf->frame() < 0) {
	  my $revseq = $factory->create( -id => $orf->name(), -seq => $orfSeq)->revcom();
	  $orfSeq = $revseq->seq();
	}
	my $sequence;
	if ($opt_P) {
	  $sequence = GENDB::Common::translate($orfSeq);
	} else {
	  $sequence = $orfSeq;
	}
	my $name = $orf->name();
	my $description = "";
	if ($name =~ /^(.+?)\s(.+)/) {
	  $name = $1;
	  $description = $2;
	}
	my $annotation = $orf->latest_annotation();
	$description .= $annotation->product() ? $annotation->product() : 'hypothetical ORF';
	$description = $annotation->name() . ": $description" if ($annotation->name());
	
	$seqio->write_seq($factory->create( -id => $name, -seq => $sequence, -description => $description . "  [+ $upstream upstream : + $downstream downstream]"));
      }
      last if ($debug && $orfcnt == 20);
    }				# end of foreach my $orf
  }				# end of foreach my $contigName
}

sub get_seq {
  my $contig = shift;
  my $orfCoords = shift;

  my $orfSeq = $contig->subseq(eval{$orfCoords->[0] <= 0 ? 1 : $orfCoords->[0]}, $orfCoords->[1] > $contig->length() ? $contig->length() : $orfCoords->[1]);

  return $orfSeq;
}

sub orfCoords {
  my $orf = shift;
  # uses $upstream and $downstream global variables

  my $start = $orf->start();
  my $stop = $orf->stop();
  my $frame = $orf->frame();

  if ($upstream) {
    if ($frame > 0) {
      $start -= $upstream;
      $stop = $orf->start() - 1 if ($opt_U);
    } else {
      $stop += $upstream;
      $start = $orf->stop() + 1 if ($opt_U);
    }
    print $orf->name() . " start = $start, stop = $stop\n" if ($debug);
  }

  if ($downstream) {
    print "adding $downstream downstream\n" if ($debug);
    if ($frame > 0) {
      $stop += $downstream;
    } else {
      $start -= $downstream;
    }
  }
  return ($start,$stop);

}


sub _help {
  my $usage = shift;

  print <<HELP

This script retrieves ORFs from a GenDB annotation project.

usage: $usage

Command-line options:

Option\t\tDescription
-p <project>\tGenDB project name (required)
-P\t\toutput protein sequences
-r\t\toutput structural RNA sequences (tRNAs & rRNAs)
-I\t\toutput potential promoter region of each ORF, if available (1)
-O\t\textract specific ORF
-c\t\textract ORFs from a specific contig
-g\t\tinclude ORFs with status "ignored"
-G\t\toutput only those ORFs with status "ignored"
-C\t\tminimum length of contig to extract ORFs from (default = 5000)
-o <file>\toutput to a file
-F\t\toutput sequences to STDOUT
-f\t\tfile format of sequences (ie, fasta)
-u <integer>\tamount of upstream sequence to include
-U\t\toutput only # of nucleotides specified with -u (2)
-D <integer>\tamount of downstream sequence to include
-h\t\tprint this help menu
-v\t\tverbose output to terminal
-d\t\tdebugging mode

(1) The -I option will output from the end of the "previous" ORF to the START
of the current ORF.  Depending on the strand of the current ORF, the end of the
previous ORF could be it's START or STOP.

(2) The -U option will output the specified number of upstream nucleotides 
(using the -u option) for every ORF, even if it overlaps an upstream ORF.

HELP

}
