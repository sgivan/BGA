#!/usr/bin/env perl
# $Id: extractSeq.pl,v 1.6 2005/03/03 23:49:51 givans Exp $
#
use strict;
use 5.10.0;
use Carp;
use Getopt::Std;
use vars qw/ $opt_S $opt_E $opt_f $opt_F $opt_v $opt_h $opt_o $opt_B $opt_p $opt_t $opt_P $opt_T $opt_O $opt_d $opt_c /;
use Bio::SeqIO;
use Bio::Seq::SeqFactory;

getopts('S:E:f:F:vho:B:p:t:PTOdc:');

my $usage = "extractSeq.pl -f <DNA sequence file> -F <coordinate file name>";
my $debug = $opt_d;

if ($opt_h) {
print <<HELP;

This script will take a DNA file in FASTA format and a tab-delimited
file containing the start and end coordinates of internal sequences
and return a file containing each subsequence.

usage: $usage

Command-line arguments and options

-f	input file containing DNA sequence*
-F	input file containing coordinates*
-o	output file name
-O	output to stdout
-S	column containing start coordinates
-E	column containing end coordinates
-B	amount of upstream and downstream sequence to include
-p	amount of upstream sequence to include
-P	only output specified upstream sequence for each ORF
-t	amount of downstream sequence to include
-T	only output specified downstream sequence for each ORF
-c  only output specified number of nts downstream of start site
-v	verbose output to terminal
-h	print this help menu


HELP
exit;
}


my ($coordFile, $seqFile, $start_column, $end_column, $outfile,$seqio,$fiveBuffer,$threeBuffer,$buffer,$factory,$codingbases);
($fiveBuffer, $threeBuffer, $start_column, $end_column) = (0,0,3,4);


if (! $opt_F || ! $opt_f) {
  print "usage: $usage\n";
  exit(1);
}

$seqFile = $opt_f;
$coordFile = $opt_F;

$outfile = "$seqFile" . ".extractSeq";
$outfile = $opt_o if ($opt_o);

$codingbases = $opt_c;

if ($opt_B) {
  $buffer = $opt_B;
  $fiveBuffer = $buffer;
  $threeBuffer = $buffer;
} else {
  $fiveBuffer = $opt_p if ($opt_p);
  $threeBuffer = $opt_t if ($opt_t);
}

$start_column = $opt_S if ($opt_S);
$end_column = $opt_E if ($opt_E);
--$start_column;
--$end_column;


$seqio = Bio::SeqIO->new(
			 -file		=>	$seqFile,
			 -format	=>	'fasta',
			 );
my $seq = $seqio->next_seq() or die "can't open '$seqFile': $!";
my $seqLength = $seq->length();
#print $seq->id() . " is " . $seq->length() . "nt\n";

my $factory = Bio::Seq::SeqFactory->new();

my ($outseqio,%outFileParam);
if (!$opt_O) {
  %outFileParam = (
		   -file => ">$outfile",
		   -format => 'fasta',
		   );
} else {
  %outFileParam = (
		   -fh => '',
		   -format => 'fasta',
		  );
}
$outseqio = Bio::SeqIO->new(%outFileParam);

open(COORD, "$coordFile") or die "can't open '$coordFile': $!";

my $seqnum = 0;
while (<COORD>) {
  my $line = $_;
  chomp($line);
  my $revcomp = 0;
#  print "line: '$line'\n" if ($opt_v);
#  my @line = split /\t/, $line;
  my @line = split /\s+/, $line;
  my $start = $line[$start_column];
  my $end = $line[$end_column];
  next unless ($start && $end);

  say "\ninput values: start = '$start', end = '$end'" if ($debug);

  if ($start > $end) {
      say "start < end, switching coordinates" if ($debug);
    $revcomp = $end;
    $end = $start;
    $start = $revcomp;
  }
  say "values: start = '$start', end = '$end'" if ($debug);

  if ($codingbases) {
      say "adding coding bases to start coordinate" if ($debug);
      $end = $start + $codingbases;
  }
  say "values: start = '$start', end = '$end'" if ($debug);
    
  say "adding sequence buffers to start/stop coordinates, if requested" if ($debug);
  if (!$revcomp) {
    $start -= $fiveBuffer;
    $end += $threeBuffer;
  } else { ## working with reverse complement
    $end += $fiveBuffer;
    $start -= $threeBuffer;
  }
  say "1) values: start = '$start', end = '$end'" if ($debug);

  if ($opt_P) {
    if (!$revcomp) {
      $end = ($start + $fiveBuffer) - 1;
    } else { ## working with reverse complement
      $start = ($end - $fiveBuffer) + 1;
    }
  }
  say "2) values: start = '$start', end = '$end'" if ($debug);

  if ($opt_T) {
    if (!$revcomp) {
      $start = ($end - $threeBuffer) + 1;
    } else { ## working with reverse complement
      $end = ($start + $threeBuffer) - 1;
    }
  }
  say "3) values: start = '$start', end = '$end'" if ($debug);

#  if ($codingbases) {
#      $end = $start + $codingbases;
#  }
#
#  if ($end > $seqLength) {
#    $end = $seqLength;
#  }
#
# if ($end < $start) {
#     say "end: '$end' < start: '$start'";
# }

  print "start: '$start', end: '$end'\n" if ($opt_v);

  #$start = 10;
  #$end = 100;
  ++$seqnum;
  last if ($seqnum >= 10 && $debug);
  my $id = $line[0] || $seqnum;
  my $description = "";
  if ($fiveBuffer || $threeBuffer) {

    if ($fiveBuffer && $threeBuffer) {
      $description = "[+ $fiveBuffer upstream : + $threeBuffer downstream]";
    } elsif ($fiveBuffer) {
      $description = "[+ $fiveBuffer upstream]";
    } else {
      $description = "[+ $threeBuffer downstream]";
    }
  }


  if ($start < 0 || !$start) {
        if ($debug) {
            if (!$start) {
                print "no start value\n";
            } else {
                print "bad start value: '$start'\n";
            }
            die();
        } else {
            next;
        }
  }

  my $newseq = $seq->subseq($start, $end) or confess();;

  my $outseq = $factory->create(
				-id   	=>	$id,
				-seq	=>	$newseq,
			       );
  $outseq = $outseq->revcom() if ($revcomp);
  $outseq->desc($description) if ($description);

  $outseqio->write_seq($outseq);

}

close(COORD);
print "\n\nfinished\n\n";
