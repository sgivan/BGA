#!/usr/bin/env perl
# $Id: lengthsort_all.pl,v 3.2 2007/05/30 22:39:02 givans Exp $

use strict;
#use lib '/local/lib/perl5';
use Bio::SeqIO;
use Getopt::Std;
use IO::File;
use vars qw/ $opt_f $opt_r $opt_h $opt_o /;
getopts('f:O:or:s:ho');
my($infile,%outfile,$lower,$upper,$outfile) = ();

my $usage = <<USAGE;

Script to sort sequences from a fasta file by length and output
them to fasta files containing sequences of uniform length.

usage:  lengthsort_all.pl

command-line options
-f\tspecify input file name
-r\tsize range to accept
\tspecify as 2 digits separated by a dash; ie, 21-25
\tdefaults to 20-30
-o\toutput all sequences to one file called outfile.nfa 
-h\tprint this help menu


USAGE

if ($opt_h) {
  print $usage;
  exit;
}

if (!$opt_f) {
    print "Name of input file: ";
    $infile = <STDIN>;
    chomp($infile);
} else {
    $infile = $opt_f;
}

die "you must enter a valid input file name\n" unless ($infile);

if ($opt_r) {
  if ($opt_r =~ /(\d+?)-(\d+?)$/) {
    $lower = $1;
    $upper = $2;
  } else {
    print "specify range as 2 digits separated by a dash; ie 21-25\n";
    exit();
  }
} else {
  $lower = 20;
  $upper = 30;
}

my $outfh;
if ($opt_o) {
  $outfile = 'outfile.nfa';
#  $outfh = new IO::File ">$outfile";
  $outfh = Bio::SeqIO->new(
      -file     =>  '>outfile.nfa',
      -format   =>  'fasta',
  );
}


for (my $length = $lower; $length <= $upper; ++$length) {
  if (!$opt_o) {
#    $outfile{$length} = new IO::File ">$length.nfa";
      $outfile{$length} = Bio::SeqIO->new(
          -file     =>  "$length.nfa",
          -format   =>  'fasta',
      );
  } else {
#    $outfile{$length} = $outfh;
      $outfile{$length} = $outfh;
  }
}

#print "range = $lower" . "-" . "$upper\n";
#exit();

# die "you must enter a valid output file name\n" unless ($outfile);

my $seqio = Bio::SeqIO->new(
    -file	=>	$infile,
	-format	=>	'fasta',
);

my %tally = ();
while (my $seq = $seqio->next_seq()) {
    my $length = $seq->length();
    my $id = $seq->id();
    $id =~ s/\-.+//;

    #my $fh = $outfile{$length};
    #my $seqout = $outfile{$length};

    next if ($length > $upper || $length < $lower);

#    $outfile{$length}->print(">" . $seq->id() . "\n" . $seq->seq() . "\n");

    $outfile{$length}->write_seq($seq);

    
    ++$tally{$length};
}

my @lengths = sort {$a <=> $b} keys %tally;

print "Length\tNumber\n";

foreach my $length (@lengths) {
    print "$length\t$tally{$length}\n";
	    
}

print "\nfinished\n";
