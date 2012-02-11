#!/usr/bin/env perl
#
# $Id: genDB_orfStartRefine.pl,v 3.7 2006/10/03 16:55:39 givans Exp $
#
use warnings;
use strict;
use Carp;
use Getopt::Std;
use Bio::SearchIO;
use Bio::SeqIO;
use Statistics::Descriptive;
use Statistics::Distributions;
#use Statistics::ChiSquare;

use vars qw / $opt_f $opt_b $opt_v $opt_h $opt_o $opt_O $opt_F $opt_E $opt_D $opt_i $opt_I $opt_d $opt_S $opt_P /;

getopts('f:b:vho:OF:E:D:iId:S:P');

my $usage = "orfStartRefine.pl -f <file name | folder name>";
my $HELP = <<HELP;

 \033[1;31mNOTE:  This help message was adapted from another script.
        Some options may not be available.\033[0m

This script will parse a blastx report to identify
potential frameshift errors based on multiple BLAST
hits to the same protein.

usage: $usage

Command-line arguments and options

\033[1mOption	Description\033[0m
-f <file>	input file name*
-F <folder>	folder containing BLAST result files*
-b <blast>	type of blast report (defaults to blastx)
-E <E-value>	maximum E value to accept (enclose in quote)
-I		ignore BLAST hits with > 98% identity to query --
		this usually prevents comparing to gene from same organism
-i		make GI index of BLASTDB (probably not necessary)
-o <file>	output file name
-O		generate output file to be used with genDB_orfCoord.pl
		will be called 'orfStartRefine.out'
-S		maximum distance to search for a new START from the predicted new START [default = 30]
-d <string> 	specify name of BLAST database searched [optional]
-D <integer>	use for debugging
-v		verbose output to terminal
-P		show progress 
-h		print this help menu

* one of these two are required

HELP

if ($opt_h) {
  _help();
  exit;
}



my ($infile, $outfile, $report, $infolder, @infiles, $blast,$Evalue,$debug,$dbname,$verbose,$maxSep,$show_progress);
my ($low,$med,$high,$confidence,$hlink,%GI) = ("","*","***","");## Confidence indicators

my %startCodons = (
		   1	=>	'ATG',
		   2	=>	'GTG',
		   3	=>	'TTG',
		   );
my @startCodons = values(%startCodons);




#
#################################
# Parse command-line options	#
#################################
#
#
#

if (!$opt_f && !$opt_F) {
  print "usage:  '$usage'\n";
  exit;
} elsif ($opt_f) {
  push(@infiles, $opt_f);
  $outfile = "$opt_f" . ".orfStartRefine.tab";
  $infolder = ".";
} elsif ($opt_F) {
  $infolder = $opt_F;
  $outfile = 'orfStartRefine.tab';
  opendir(IN, $infolder) or die "can't open '$infolder': $!";
  @infiles = readdir(IN);
  closedir(IN);
}

$outfile = $opt_o if ($opt_o);

$blast = "blastx";
$blast = $opt_b if ($opt_b);

$Evalue = '1e-06';
$Evalue = $opt_E if ($opt_E);

$debug = 0;
$debug = $opt_D if ($opt_D);

$verbose = $opt_v;
$verbose = 1 if ($debug);

$maxSep = $opt_S;
$maxSep = 30 unless ($maxSep);

$dbname = $opt_d;
$show_progress = $opt_P;

#
#
# End of option parsing
#############################
#

#
#########################
# Open output file	#
#########################
#
#

open(OUT, ">$outfile") or die "can't open '$outfile': $!";

print OUT "ORF\tStart\tStop\tCodon\tDescription\n";

if ($opt_O) {
  open(CLEAN,">orfStartRefine.out") or die "can't open 'orfStartRefine.out': $!";
}

#
#################################
# Loop through BLAST reports	#
#################################
#
#

my $loop = 0;
foreach my $infile (@infiles) {
  next unless ($infile =~ /(.+)\.$blast\b/);
  ++$loop;
#  print "\n\n\033[1mprogress: $loop files\033[0m\n\n" if ($debug);
  if ($show_progress && !(int($loop/5) - $loop/5)) {
    print STDERR "\n\033[1mprogress: $loop files\033[0m\n";
  }

  my $seqFile = $1;
  $seqFile .= ".nfa";
  print "\n\n", "#" x 25, "\nseqFile = '$seqFile'\n" if ($debug);

  $report = Bio::SearchIO->new(
			       -file	=>	"$infolder/$infile",
			       -format	=>	'blast',
			      );
  my ($seq,$starts);
  if (-e "$infolder/$seqFile") {
    print "creating Bio::Seq object\n" if ($debug);
    my $seqIO = Bio::SeqIO->new(
			   -file	=>	"$infolder/$seqFile",
			   -format	=>	'fasta',
			   );
    $seq = $seqIO->next_seq();
  }

  if ($debug) {
    last if ($loop > $debug);
#    ++$loop;
#    print "loop = '$loop'\n" if ($debug);
  }

  while (my $result = $report->next_result()) {
    my $blastdb;
    if ($dbname) {
      $blastdb = $dbname;
    } else {
      $blastdb = $result->database_name() or croak("can't get blastdb");
    }
	
    $blastdb = "$ENV{'BLASTDB'}/$blastdb";
    $blastdb =~ s/ //g;
    #
#################################
# Create index of BLAST DB	#
#################################
#
#

    if ($opt_i) {
      if (! $GI{$blastdb}) {
	print "creating index of '$blastdb'\n" if ($debug || $verbose);
	$GI{$blastdb} = makeGIindex($blastdb);
      }
    }

    print $result->query_name() . " number of hits: " . $result->num_hits() . "\n" if ($verbose || $debug);
    my($o_start,$o_end,$o_frame,$o_len) = o_gene($result);
    print "orginal gene: $o_start - $o_end [$o_len]\n" if ($debug);
    #   print "look for hits in frame '$o_frame'\n" if ($debug);

#
#########################
# Establish bin ranges	#
#########################
#
# I experimented with several different configurations so
# there's a lot of unused code in this section.  Currently
# I only use 2 bins:  upstream and downstream of current
# start location.
#

#     my $binsize = int($o_start/10);
#     my ($range1,$range2,$range3,$range4,$range5,$range6,$range7,$range8,$range9,%tally);
#     my $fudge = $o_start + int($binsize/2);
#     $range1 = $fudge - $binsize * 4;
#     $range2 = $fudge - $binsize * 3;
#     $range3 = $fudge - $binsize * 2;
#     $range4 = $fudge - $binsize;
#     $range5 = $fudge;
#     $range6 = $fudge + $binsize;
#     $range7 = $fudge + $binsize * 2;
#     $range8 = $fudge + $binsize * 3;
#     $range9 = $fudge + $binsize * 4;
#     my @ranges = ($range1,$range2,$range3,$range4,$range5,$range6,$range7,$range8,$range9);
#     @ranges = (($o_start-5), $o_end);
# #    my @expects = qw/0.0025 0.0225 0.025 0.1 0.70 0.1 0.025 0.0225 0.0025 /;
# #    my @expects = qw/0.0025 0.0225 0.025 0.1 0.50 0.15 0.15 0.025 0.025 /;
# #    my @expects = qw/0.0025 0.0025 0.015 0.025 0.28 0.25 0.15 0.15 0.125 /;
# #    my @expects = qw/0.0025 0.0025 0.0025 0.0025 0.4325 0.4325 0.05 0.0375 0.0375 /;## good
    my @expects = qw/ 0.05 0.95 /;## best so far
    my @ranges = (($o_start-5), $o_end);

#    print "ranges:\n$range1 [-", $binsize * 4, "] : $range2 [-", $binsize * 3, "] : $range3 [-", $binsize * 2, "] : $range4 [-", $binsize, "] : $o_start : $range6 [+", $binsize, "] : $range7 [+", $binsize * 2, "] : $range8 [+", $binsize * 3, "] : $range9 [+", $binsize * 4, "]\n" if ($debug);

#
# Initialize tally hash
#
    my %tally;
    foreach my $intRange (@ranges) {
      $tally{$intRange}{tally} = 0;
      $tally{$intRange}{list} = ();
    }
#
#
############################################
#


#
#################################################
# Send Bio::Seq object to findStarts subroutine	#
# to identify potential start sites		#
#################################################
#
#

    if ($seq && ref($seq) eq 'Bio::Seq') {
      print "finding start codons in ", $seq->id(), "\n" if ($debug);
      $starts = findStarts($seq,$o_start,\@startCodons);
    }

#     if ($debug) {
#       print "returned potential start sites:\n";
#       foreach my $codon (map { $startCodons{$_}} sort { $a <=> $b } keys %startCodons) {
# 	print "$codon:  ";
# 	print "@{$starts->{$codon}}" if ($starts->{$codon});
# 	print "\n";
#       }
#     }
    #
#################################
# Loop through BLAST hits	#
#################################
#
#

    my $hit_num = 0;
    my ($bestBits,$minBits) = (0,0);
    foreach my $hit ($result->hits()) {
#      ++$hit_num;

#
# Restrict analysis to top 20% of BLAST hits
#
#      if ($hit_num == 1) {
      if (!$hit_num) {
	next if ($opt_I && $hit->hsp()->frac_identical() >= 0.99);## this should ignore hits to same ORF
	$bestBits = $hit->bits;
	$minBits = $bestBits * 0.8;
	print "bestBits = $bestBits; minBits = $minBits\n" if ($debug);
      } else {
	last if (!$hit->bits || $hit->bits < $minBits);
      }
      ++$hit_num;
      my $h_sig = $hit->significance();
      $h_sig = "1" . "$h_sig" if ($h_sig =~ /^e/); ## sometimes E-value is just ie, e-100.

      if ($h_sig > 1e-10) {
#	print "low quality hit\n" if ($debug);
	next;
      }

      foreach my $hsp ($hit->hsps()) {
#	print $hit->name(), " hsp length = '", $hsp->length('hit'), "'; query length = '", $o_len/3, "'\n";
#	print "hsp stop = ", $hsp->end(), ", gene start = ", $o_start, "\n";
	my $overlap_percentage = $hsp->length('hit') / ($o_len/3);
	my $gene_start_overlap = $hsp->end() - $o_start;

	if ($overlap_percentage < 0.75 || ($gene_start_overlap && $gene_start_overlap < 0)) {
	  printf "skipping because HSP for %s : does not satisfy length requirements [%3.2f%s | %d]\n", $hit->name(),$overlap_percentage*100,'%',$gene_start_overlap  if ($debug);
	  next;
	} else {
	  printf "HSP for %s satisfies length requirements [%3.2f%s | %d]\n", $hit->name(),$overlap_percentage*100,'%',$gene_start_overlap  if ($debug);
	}

	if ($hsp->frame('hit') != $o_frame) {# change in API
#  if ($hsp->frame != $o_frame) {
#	  print "hit in wrong frame [", $hit->frame, "]\n" if ($debug);
	  next;
	}
	if ($hsp->strand('query') != 1) {
	  #	print "wrong query strand '", $hit->strand('query'), "'\n";
	  next;
	}

	#
	#########################################################
	# Put BLAST hits into bins based on start of alignment	#
	#########################################################
	#
	#
	#      print "putting hits in bins\n";
	my $h_start = $hsp->start();

	for (my $r = 0; $r < scalar(@ranges); ++$r) {
	  #	print "\$ranges[$r] = $ranges[$r]\n";
	  if ($h_start < $ranges[$r]) {
	    ++$tally{$ranges[$r]}{tally};
	    push(@{$tally{$ranges[$r]}{list}},$h_start);
	    last;
	  }
	}
      }
    }				## end of foreach my $hit loop
#
#
# End of looping through BLAST hits from a BLAST report
#########################################################
#

#
#########################
# Print summary of bins	#
#########################
#
#

    my ($cnt,$tot) = (0,0);
    foreach my $bin (sort { $a <=> $b } keys %tally) {
      ++$cnt;
      $tot += $tally{$bin}{tally};
      print "range $bin: $tally{$bin}{tally}\n" if ($debug);

      if ($debug && $tally{$bin}{tally}) {
	print join ',', @{$tally{$bin}{list}};
	print "\n";
      }
    }

#
# Calculate Chi-Square value and probability
#############################################
#
#
#
    my ($X,$Xvals) = calc_chisquare(\%tally,\@expects);
    my $df = scalar(@ranges) - 1;
    my $chisprob = Statistics::Distributions::chisqrprob($df,$X);

    if ($tally{$ranges[0]}{tally} && $X != -1) {# $X = -1 when obs < exp for bin1

      if ($debug) {
	print "Chi-Square value [df=$df] = $X\n";
	print "Chi-Square probability: ", $chisprob, "\n";
      }
      my $newStart;
      if ($chisprob <= 0.05) {
	print "\tstart site may need to be adjusted\n" if ($debug || $verbose);
	if ($tally{$ranges[0]}{tally} > 1) {
	  my $stat = Statistics::Descriptive::Full->new();

	  $stat->add_data(@{$tally{$ranges[0]}{list}});
	  my $median = int($stat->median());
	  print "\tlook for potential start site around nt $median [+/-$maxSep]\n" if ($debug || $verbose);
	  $newStart = $median;
	} else {
	  print "\tlook for potential start site around nt @{$tally{$ranges[0]}{list}} [+/-$maxSep]\n" if ($debug || $verbose);
	  $newStart = pop(@{$tally{$ranges[0]}{list}});
	}

#
#################################
# select new start position	#
#################################
#
#

	my %min;
#
#	sort codons by preference, which is represented by order of hash keys
#
	my $newStartLoop = 0;

#	my $max_maxSep = 30;

#      newStart: {
# 	last newStart if ($maxSep > $max_maxSep);
#
# 	Sorting by key will give preference to codons
#
	foreach my $codon (map { $startCodons{$_}} sort { $a <=> $b } keys %startCodons) { ## start of codo loop
 	  if ($newStartLoop < 3 && $debug) {
 	    print "$codon:  ";
 	    print "@{$starts->{$codon}}" if ($starts->{$codon});
 	    print "\n";
 	  }
 	  ++$newStartLoop;
#
#	loop through potential start sites for this codon
#
	  foreach my $potStart (@{$starts->{$codon}}) {
	    next if ($potStart == $o_start);
	    my $separation = $newStart - $potStart;
	    next unless ( ($separation < 0 && abs($separation) <= ($maxSep * 0.5)) || ($separation >= 0 && $separation <= $maxSep) );
	    if ($min{$codon}{pos}) {
	      if ($min{$codon}{separation} > $separation) {
		$min{$codon}{pos} = $potStart;
		$min{$codon}{separation} = $separation;
	      }
	    } else {
	      $min{$codon}{pos} = $potStart;
	      $min{$codon}{separation} = $separation;
	    }
	  }

	} ## end of codon loop


#  	if (!%min) {
#  	  $maxSep += 10;
#  	  redo newStart;
#  	}
#      } ## end of newStart loop

#
#	if a new potential start site was identified, generate info
#
	if (%min) {
	  foreach my $codon (map { $startCodons{$_} } sort { $a <=> $b } keys %startCodons) {
	    if ($min{$codon}{pos}) {
	      print "\tclosest location: $codon - $min{$codon}{pos} [$min{$codon}{separation}nt ", ($newStart - $min{$codon}{pos} > 0) ? 'upstream' : 'downstream', "]\n" if ($debug || $verbose);
	      print OUT $result->query_name(), "\t", $newStart - $min{$codon}{pos}, "\t\t", $codon,"\n";
	      if ($opt_O) {
#		print CLEAN $result->query_name(), "\t", $min{$codon}{pos} - $o_start > 0 ? "+" . $min{$codon}{pos} - $o_start : $min{$codon}{pos} - $o_start, "\n";
		print CLEAN $result->query_name(), "\t", eval{ $min{$codon}{pos} - $o_start > 0 ? return "+" : return}, $min{$codon}{pos} - $o_start, "\n";
	      }
	      last;
	    }
	  }
	} else {
	  print "\tno good candidate identified\n" if ($debug || $verbose);
	  print OUT $result->query_name(),"\t\t\t\tno good candidate identified\n";
	  if ($chisprob <= 0.005) {
	    print "\t\033[1;31mALERT:\033[0m can't find a good new start site\n" if ($debug || $verbose);
	    print OUT $result->query_name(), "\t\t\t\t", "ALERT:  can't locate a good start\n";
	  }
	}
      }
#
#
# end of new start position selection
#######################################
#

     } else {
       print "no need to determine new start position\n" if ($debug);
     }
  }
}
close(OUT);
close(CLEAN) if ($opt_O);

#
#
# End of main
#######################
#

#
#################
# Subroutines	#
#################
#
#

#########################################
# o_gene determines start and stop	#
# coordinates of query sequence		#
#########################################
sub o_gene {
  my $result = shift;
  my($start,$end, $descr,$length,$frame);

  $descr = $result->query_description();
  $length = $result->query_length();

  if ($descr =~ /\[\+\s(\d+)\supstream\s\:\s\+\s(\d+)\sdownstream\]/) {
    print "subtracting buffers from original gene [$length]\n" if ($debug);
    $start = $1;
    $end = $length - $2;
#    $end = $length;
    $length -= ($1 + $2);
  } else {
    $start = 1;
    $end = $length;
  }

  if ($start) {
    my $temp;
    $temp = ($start/3) - int($start/3);
    if ($temp == 0) {
      $frame = '0';
    } elsif ($temp < 0.6) {
      $frame = '1';
    } else {
      $frame = '2';
    }
  }

  return ($start,$end,$frame,$length);
}

#################################################
# makeGIindex creates an index of a BLAST DB	#
#################################################
sub makeGIindex {
  my $db = shift;
  my $dbfile = "$db" . ".psd";
  my(%gi,%acc,%gi_ref);
  print "making index of '$dbfile'\n" if ($debug);

  open(IN, $dbfile) or die "can't open '$dbfile': $!";

  while (<IN>) {
    my $line = $_;
    if ($line =~ /^gi\|(\d+?)\W(\d+)\b/) {
      $gi{$2} = $1;
    } elsif ($line =~ /\|(.+?)\|\W(\d+)\b/i) {
      $acc{$1} = $2;
    }
  }

  while (my($key,$value) = each %acc) {
    $gi_ref{uc($key)} = $gi{$value};
  }

  return \%gi_ref;

}

#########################################################
# findStarts returns a hash keyed by start codons	#
# containing arrays of potential start sites		#
#########################################################
sub findStarts {
  my $seq = shift;
  my $currStart = shift;
  my $startCodons = shift;
  my %startList;

  my $seqstring = $seq->seq();

  foreach my $codon (@$startCodons) {

    my @temp;

    for (my $pos = $currStart; $pos > 0; $pos -= 3) {
      my $tcodon = uc(substr($seqstring,$pos,3));
      #
      # leave loop if STOP codon is encountered
      # NOT doing this is actually interesting because it identifies
      # potential sequence errors
      #
      last if ($tcodon eq 'TAA' || $tcodon eq 'TGA' || $tcodon eq 'TAG');
      #
      #
      if ($tcodon eq $codon) {
	push(@temp,$pos);
      }
    }
#
#########################################################
#							#
# the following routine didn't account for in-frame	#
# stop codons when extending ORFs 5'			#
# I replaced with above routine which fixes the problem	#
#							#
#########################################################
#
#      my $pos = -1;
#      while (($pos = index($seqstring,$codon,$pos)) > -1) {
#        my $dist = abs($currStart - $pos);
#        if ((($dist/3) - int($dist/3)) == 0) {
#  	push(@temp,$pos);
#        }
#        $pos++;
#      }


    @temp = sort { $a <=> $b } @temp;

    if (scalar(@temp)) {
       $startList{$codon} = [@temp];
    }

  }

  return \%startList;
}

#########################################
# Calculate the Chi-Square value	#
# or return -1 if not applicable      	#
#########################################
 sub calc_chisquare {
   my $data = shift;
   my $expects = shift;

   my @tallies = map { $data->{$_}{tally} } sort { $a <=> $b } keys %$data;
   my ($X, $total, @X) = (0,0);
   map { $total += $_ } @tallies;
#   print "total = $total\n";
   return 0 if (!$total);
   my $categories = scalar(@tallies);
   if (scalar(@$expects) != $categories) {
     print "unequal categories [", scalar(@tallies), "] and expect [", scalar(@$expects), "] values\n" if ($debug);
     die();
   }

   for (my $i = 0; $i < $categories; ++$i) {
     my $exp = $expects->[$i] * $total;
     if ($i == 0) {
#       return (1,[1, 1]) if ($tallies[$i] < $exp);
       return (-1,[-1, -1]) if ($tallies[$i] < $exp);
     }
     print "range", $i+1," observed = $tallies[$i]; expect [", $expects->[$i], "] = ", $expects->[$i] * $total, "\n" if ($debug);

#     $X += (((($tallies[$i]/$total) - $expects->[$i])**2)/$expects->[$i]);
     my $oe = ((($tallies[$i] - ($expects->[$i] * $total))**2)/($expects->[$i] * $total));
     push(@X, $oe);
     $X += $oe;
   }
   return ($X,\@X);
 }

#################################
# _help prints a help menu	#
#################################
sub _help {
  print $HELP;
}

#
#
# End of subroutines
########################
#

#
#
# End of program
#######################
#
