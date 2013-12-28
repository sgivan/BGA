#!/usr/bin/env perl
# $Id: RBSfind.pl,v 3.10 2009/12/03 01:09:21 givans Exp $
use warnings;
use strict;
use Carp;
use Getopt::Std;
use vars qw/ $opt_r $opt_g $opt_v $opt_d $opt_h $opt_l $opt_b $opt_p $opt_x $opt_n $opt_a /;
use Bio::SeqIO;
use Statistics::Distributions;
use Statistics::Descriptive;
use Math::BigInt 1.60 lib => 'GMP';
#use Math::BigInt;
use Math::BigFloat 1.60 lib => 'GMP';
#use Math::BigFloat;

getopts('r:g:l:b:vdhp:xna');

my $descr = <<HELP;
#
# Based on recommendations in rbs_finder.pl (a script from TIGR),
# this script does the following:
#
#     -Take the complement of last 30bps of 16S rRNA
#     -Find the most abundantly found 5bps subsequence of this complement in the
#      30bps upstream regions of the start codons annotated by Glimmer2.
#     -Use this sequence as consensus sequence.
#
# Before running this script, use extractSeq.pl to extract upstream regions of genes
# All sequence files should be in FASTA format
#


# Command-line options

-r	file containing 16S rRNA gene
-g	file containing genomic sequence
-l	length of 3' end of 16S rRNA to use [default = 30]
-p	length of promoter included with each genomic sequence [default = 0]
-b	size of potential Shine Delgarno box [default = 5; usually 3 - 9]
-x	sort results by chi-square probability instead of poisson probability
-n	print nucleotide frequencies
-a	generate data for all potential RBS [not just those statistically overrepresented]
-v	verbose output
-d	debugging mode
-h	print this help menu

HELP

if ($opt_h) {
  print "$descr\n";
  exit(0);
}

my($rnaFile,$genFile,$verbose,$debug,$endLength,$promoter_len);

$verbose = $opt_v;
$debug = $opt_d;

if (!$opt_r || !$opt_g) {
  print "usage:  RBSfind.pl -r <16S rRNA sequence file> -g <genomic upstream region sequence file> <options>\n";
  exit(0);
}

$rnaFile = $opt_r;
print "using '$rnaFile' 16S rRNA sequence\n" if ($verbose);
if (!-e $rnaFile) {
  print "'$rnaFile' doesn't exist in this directory\n";
  exit(0);
}

$genFile = $opt_g;
print "using '$genFile' genomic upstream sequences\n" if ($verbose);
if (!-e $genFile) {
  print "'$genFile' doesn't exist in this directory\n";
  exit(0);
}

 if ($opt_p) {
   $promoter_len = $opt_p;
   print "promoter length = $promoter_len\n" if ($verbose);
 }

$endLength = $opt_l;
$endLength = 30 unless ($endLength);

my $SDbox = $opt_b;
$SDbox = 5 unless ($SDbox);

#
# Read 16S rRNA sequence
#
print "using last $endLength nt of 16S rRNA sequence\n" if ($verbose);

print "reading 16S rRNA sequence\n" if ($verbose);
my $rRNA_IO = Bio::SeqIO->new(
			      -file	=>	$rnaFile,
			      -format	=>	'fasta',
			      );
my $rRNA = $rRNA_IO->next_seq();

#
# Read upstream sequences
#
print "reading genomic upstream sequences\n" if ($verbose);
my $genSeq_IO = Bio::SeqIO->new(
				-file	=>	$genFile,
				-format	=>	'fasta',
			       );



#
# Generate a hash table of 5nt sequences from the 3' end of rRNA
#
#print "Using the reverse-complement of the 3' end of the 16S rRNA\n" if ($verbose);
print "16S rRNA sequence length: ", $rRNA->length(), "\n" if ($verbose);
$rRNA = $rRNA->revcom();

my $rRNA_end = $rRNA->subseq(1, $endLength);

print "reverse complement of 3' end 16S rRNA:\n", $rRNA_end, " [", length($rRNA_end), " nt]\n" if ($verbose);

my (%rbs,%genic) = ();
my @data = (\%rbs,\%genic);
#my $rbs_len = 5;
for (my $i = 0; $i <= (length($rRNA_end) - $SDbox); ++$i) {
  my $subseq = substr($rRNA_end, $i, $SDbox);
#  print "\$subseq = '$subseq'\n" if ($debug);
  $genic{$subseq} = $rbs{$subseq} = 0;
}

#
# Hash has been built

#
# Search for Shine Delgarno sequences
# in submitted upstream sequences
#
my $cnt = 0;
my($pA,$pT,$pG,$pC,$gA,$pN,$gT,$gG,$gC,$gN,$total_len,$total_promoter_len,$total_genic_len,%promoter_nuc,%genic_nuc,%total_nuc);

my @nuc = qw/ A T G C N X /;
while (my $genSeq = $genSeq_IO->next_seq()) {
  ++$cnt;
  my ($promoter,$genic,$total);
  if ($promoter_len) {
    $promoter = uc(substr($genSeq->seq(),0,$promoter_len));
    $genic = uc(substr($genSeq->seq(),$promoter_len));
    $total = uc($genSeq->seq());

    $total_promoter_len += length($promoter);
    $total_genic_len += length($genic);
    $total_len += (length($promoter) + length($genic));

    foreach my $nuc (@nuc) {
      my @pfound = $promoter =~ /$nuc/g;
      my @gfound = $genic =~ /$nuc/g;
      my @tfound = $total =~ /$nuc/g;
      $promoter_nuc{$nuc}->[0] += scalar(@pfound);
      $genic_nuc{$nuc}->[0] += scalar(@gfound);
      $total_nuc{$nuc}->[0] += scalar(@tfound);
    }

  } else {
    $promoter = $genSeq->seq();
    foreach my $nuc (@nuc) {
      my @pfound = $promoter =~ /$nuc/g;
      $total_nuc{$nuc}->[0] += scalar(@pfound);
      $promoter_nuc{$nuc}->[0] += scalar(@pfound);
     }
    $total_promoter_len += length($promoter);
    $total_len += length($promoter);
  }

  foreach my $ShineD (keys %rbs) {
    if (my @SD = $promoter =~ /$ShineD/ig) {
#      if ($debug) {
#        if (scalar(@SD) > 1) {
#          print $genSeq->id(), " >1 SD: @SD\n";
#        }
#      }

#      $rbs{$ShineD} += scalar(@SD);
      ++$rbs{$ShineD};
    }

    if ($promoter_len) {
      if (my @genic = $genic =~ /$ShineD/ig) {
#	      $genic{$ShineD} += scalar(@genic);
      	++$genic{$ShineD};
      }
    }
  }
}

my @sortedSD = sort { $rbs{$b} <=> $rbs{$a} } keys %rbs;

foreach my $key (%promoter_nuc) {
  if ($promoter_nuc{$key} && $total_promoter_len) {
    $promoter_nuc{$key}->[1] = $promoter_nuc{$key}->[0] / $total_promoter_len;
  }
}

foreach my $key (%genic_nuc) {
  if ($genic_nuc{$key} && $total_genic_len) {
    $genic_nuc{$key}->[1] = $genic_nuc{$key}->[0] / $total_genic_len;
  }
}

foreach my $key (%total_nuc) {
  if ($total_nuc{$key} && $total_len) {
    $total_nuc{$key}->[1] = $total_nuc{$key}->[0] / $total_len;
  }
}

my($tot_obs,$tot_exp);
map { $tot_obs += $rbs{$_} } keys(%rbs);
#
# Output data
#
print "total number of promoter regions searched: $cnt\n";
print "total nucleotides: $total_len\n";
print "total promoter nucleotides: $total_promoter_len\n";
print "Sorted potential Shine Delgarno sequences:\n";
my (@table,@chisquares);
#if (!$promoter_len) {
if (0) {

  print "Seq\tCount\n";
  foreach my $key (@sortedSD) {
    my $expected = 1;

    foreach my $nuc (@nuc) {
      my $number = $key =~ tr/$nuc/$nuc/;
      $expected *= $promoter_nuc{$nuc}->[1] ** $number;
    }


    print "$key\t$rbs{$key}\n";
  }

} else {

#  print "Seq\tO\tE\tchisquare\tp\t\tX\n";
#  foreach my $key (@sortedSD) {
  my $cnt = 0;
  $| = 1;
  print "\n\n";
  foreach my $key (keys %rbs) {
    my $frq = 1;

    foreach my $nuc (@nuc) {

      my @number = $key =~ /$nuc/g;
      my $number = scalar(@number);

#      $frq = $frq * ($promoter_nuc{$nuc}->[1] ** $number);
      $frq = $frq * ($total_nuc{$nuc}->[1] ** $number);
    }
    my $expected = $frq * $total_promoter_len;
    $expected = int($expected);						## take the integer portion of $expected
    ++$expected if (($frq * $total_promoter_len) - $expected >= 0.5);	## round up if necssary
    my $oe = $rbs{$key} - $expected;
    my $chisquare = $oe ** 2 / $expected;
    my $obs_b = Math::BigInt->new($rbs{$key});
    my $exp_b = Math::BigInt->new($expected);
#    my $e_exp = Math::BigFloat->new(exp($exp_b->bneg()));
    my $e_exp = Math::BigFloat->new($exp_b->bneg());
    print "\$e_exp = '" . $e_exp . "'\n" if ($debug);
    $e_exp->bexp();
    print "\$e_exp = '" . $e_exp . "'\n" if ($debug);
    my $o_fac = Math::BigInt->new($obs_b->bfac());
#    my $o_to_exp = Math::BigInt->new($expected**$rbs{$key});
    my $o_to_exp = Math::BigInt->new($expected);
    $o_to_exp->bpow($rbs{$key});
    print "\$o_to_exp = '" . $o_to_exp . "'\n" if ($debug);
#    print "\$e_exp->bmul(\$o_to_exp) = '", $e_exp->bmul($o_to_exp), "'\n";
    my $numerator = $e_exp->bmul($o_to_exp);

    push(@table,{
		 seq	=>	$key,
		 obs	=>	$rbs{$key},
		 exp	=>	$expected,
		 frq	=>	$frq,
		 chisq	=>	$chisquare,
		 prob_x	=>	Math::BigFloat->new(Statistics::Distributions::chisqrprob(1,$chisquare)),
		 prob_p	=>	Math::BigFloat->new($numerator->bdiv($o_fac)),
		});
    if ($debug) {
      print "\nprob_x = '" . Math::BigFloat->new(Statistics::Distributions::chisqrprob(1,$chisquare)) . "'\n";
      print "\$expected = '$expected'\n";
      print "\$exp_b = '" . $exp_b . "'\n";
#      print "exp() operation: '" . exp($exp_b->bneg()) . "'\n";
      print "\$e_exp isa '" . ref($e_exp) . "'\n";
      print "\$e_exp = '" . $e_exp . "'\n";
      print "\$numerator = '" . $numerator . "'\n";
      print "prob_p = '" . Math::BigFloat->new($numerator->bdiv($o_fac)) . "'\n\n";
      exit();
    }
  }
  print "\nSeq\tO\tE\tchisquare\tp\t\tX\n";
  my $sort_param = 'prob_p';
  $sort_param = 'prob_x' if ($opt_x);
  foreach my $line (sort { $a->{$sort_param}->bcmp($b->{$sort_param}) } @table) {
    if ($line->{obs} > $line->{exp} || $opt_a) {
      printf "%s\t%d\t%d\t%7.2f\t%14.3e\t%14.3e\n", $line->{seq}, $line->{obs}, $line->{exp}, $line->{chisq}, $line->{prob_p}, $line->{prob_x};
      push(@chisquares,$line->{chisq});
    }
  }
  print "total categories: ", scalar(keys(%rbs)), "\n";
  print "total Obs = $tot_obs\n";
}

print "\n";
my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@chisquares);
$stat->sort_data();
#my @sorted = $stat->get_data();
#my $chisquare = pop(@sorted);

foreach my $chisquare ($stat->get_data()) {
  if ($stat->standard_deviation()) {
  my $t = ($chisquare - $stat->mean()) / $stat->standard_deviation();
  my $tprob = Statistics::Distributions::tprob(($stat->count() - 1),$t)/2;
  if ($tprob <= 0.1) {
    printf "t-test for chisquare = %3.2f;  [t = %4.3f] t-prob = %6.5f\n", $chisquare, $t, $tprob;
  }
  }
}


#print "count: ", $stat->count(), "\n";
#print "mean:  ", $stat->mean(), "\n";
#print "SD: ", $stat->standard_deviation(), "\n";
print "t-crit, 0.05: ", Statistics::Distributions::tdistr(($stat->count() - 1),0.1), "\n\n";

if ($opt_n) {

  print "promoter (length = $total_promoter_len)\n";
  foreach my $nuc (@nuc) {
    printf "%s:\t%d\t%3.2f\n", $nuc,$promoter_nuc{$nuc}->[0],$promoter_nuc{$nuc}->[1];
  }

  if ($promoter_len) {

    if ($total_genic_len) {
      print "\n\ngenic (length = $total_genic_len)\n";

      foreach my $nuc (@nuc) {
	printf "%s:\t%d\t%3.2f\n", $nuc,$genic_nuc{$nuc}->[0],$genic_nuc{$nuc}->[1];
      }
    }

  }

}
