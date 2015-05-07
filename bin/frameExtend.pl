#!/usr/bin/env perl
#
# $Id: frameExtend.pl,v 1.9 2006/05/05 17:44:55 givans Exp $
#
use strict;
use Carp;
use Getopt::Std;
use Bio::SearchIO;
use English;
use DB_File;
use vars qw / $opt_f $opt_b $opt_v $opt_h $opt_o $opt_O $opt_d $opt_F $opt_E $opt_D $opt_S $opt_B $opt_u /;

getopts('f:b:vho:O:d:F:E:D:SB:u');
$| = 1;

my ($infile, $outfile, $usage, $report, %strand, $overlap,$separation, $infolder, @infiles, $blast,$Evalue,$debug,$blastdb_name);
my ($low,$med,$high,$confidence,$hlink,%GI) = ("","*","***","");## Confidence indicators
my $verbose;
$verbose = 1 if ($opt_v);

my $db_update = $opt_u;

$usage = "frameExtend.pl -f <file name | folder name>";

if ($opt_h) {
print <<HELP;

This script will parse a blastx report to identify
potential frameshift errors based on multiple BLAST
hits to the same protein.

usage: $usage

Command-line arguments and options

-f	input file name*
-F	folder containing BLAST result files*
-B  name of BLAST database (ie, nr, nt, gamma_aa)
-u  update or create index of sequence database
-b	type of blast report (defaults to blastx)
-E	maximum E value to accept
-o	output file name
-O	maximum overlap allowed between consecutive hits (default = 25)
-d	maximum distance between consecutive hits (default = 100)
-S	stricter E-value requirements
-D	use for debugging
-v	verbose output to terminal
-h	print this help menu

* one of these two are required

HELP
exit;

}

%strand = (
	   1	=>	'+',
	   -1	=>	'-',
	   );

if (!$opt_f && !$opt_F) {
  print "usage:  '$usage'\n";
  exit;
} elsif ($opt_f) {
  push(@infiles, $opt_f);
  $outfile = "$opt_f" . ".frameExtend.tab";
  $infolder = ".";
} elsif ($opt_F) {
  $infolder = $opt_F;
  $outfile = 'frameExtend.tab';
  opendir(IN, $infolder) or die "can't open '$infolder': $!";
  @infiles = readdir(IN);
  closedir(IN);
}

$outfile = $opt_o if ($opt_o);

$overlap = 25;
$overlap = $opt_O if ($opt_O);

$separation = 100;
$separation = $opt_d if ($opt_d);

$blast = "blastx";
$blast = $opt_b if ($opt_b);

$Evalue = '1e-06';
$Evalue = $opt_E if ($opt_E);

$debug = 0;
$debug = $opt_D if ($opt_D);
$verbose = 1 if ($debug);

$blastdb_name = $opt_B;

open(OUT, ">$outfile") or die "can't open '$outfile': $!";
autoflush OUT;
print OUT "Query\tGene Start\tGene Stop\tApprox Frame Shift Location\tDB Hit\tConfidence\tLink\n";
my $loop = 0;
foreach my $infile (@infiles) {
  next unless ($infile =~ /.+\.$blast\b/);

  $report = Bio::SearchIO->new(
			       -file	=>	"$infolder/$infile",
			       -format	=>	'blast',
			      );

  if ($debug) {
    last if ($loop == $debug);
    ++$loop;
    print "loop = '$loop'\n" if ($debug);
  }
  my ($bestE, $worstE);

  while (my $result = $report->next_result()) {
    my $blastdb;
    if (!$blastdb_name) {
      $blastdb = $result->database_name() or croak("can't get blastdb");
    } else {
      $blastdb = $blastdb_name;
    }
    #print "BLAST DB = '$blastdb'\n" if ($verbose);
    $blastdb = "$ENV{'BLASTDB'}/$blastdb_name";
    $blastdb =~ s/ //g;
    print "blastdb_name = '$blastdb_name'\n" if ($debug);
    print "BLAST DB = '$blastdb'\n" if ($verbose);

    if (! $GI{$blastdb_name}) {
      print "creating index of '$blastdb_name' [$blastdb]\n" if ($verbose);
      $GI{$blastdb_name} = makeGIindex($blastdb);
    }

    print $result->query_name() . " number of hits: " . $result->num_hits() . "\n" if ($opt_v || $debug);
    my($o_start,$o_end) = o_gene($result);
    print "orginal gene: '$o_start - $o_end'\n" if ($debug);

    my $hit_num = 0;
    while (my $hit = $result->next_hit()) {

      my @hsps = $hit->hsps();
      last if (scalar(@hsps) == 0);
      my $h_sig = $hit->significance();
      $h_sig = "1" . "$h_sig" if ($h_sig =~ /^e/); ## sometimes E-value is just ie, e-100.

      ++$hit_num;

      if ($opt_S && $hit_num == 1) {
        if ($h_sig != 0) {
            $bestE = $h_sig;
        } else {
            $bestE = 1e-200;
        }
        $worstE = $bestE ** 0.5;
        $Evalue = $worstE;
        print "first iteration:  best E value= $bestE, worst acceptable E value = $worstE\n" if ($debug);
      }


      if ($h_sig > $Evalue) {
        print "Evalue reached\t$h_sig > $Evalue\n\n" if ($debug);
        last;
      }

      if (scalar(@hsps) > 1) {
        print "hit name: " . $hit->name() . ", num hsp's: " . scalar(@hsps) . "\n" if ($debug);
        @hsps = sortHits(\@hsps, 1);

        @hsps = checkOverlap(\@hsps, $overlap,'query'); ## removes hsps with overlapping lhis to query
        @hsps = checkOverlap(\@hsps, 10,'hit'); 	## removes hsps with overlapping hits to subjct
#	@hsps = checkSeparation(\@hsps, $separation);
        if (! scalar(@hsps)) {
            print $hit->name() . " failed overlap test\n\n" if ($debug);
            next;
        }

        @hsps = checkSeparation(\@hsps, $separation);	## removes hsps with that too far apart
        if (! scalar(@hsps)) {
            print $hit->name() . " failed separation test\n\n" if ($debug);
            next;
        }

        my $h_acc = $hit->accession();
        my $h_gi = $GI{$blastdb_name}->{$h_acc};
#	$hlink = "=HYPERLINK(\"$infolder" . "HTML/$infile.html#$h_gi\", \"BLAST report\")";
        $hlink = "http://gac.science.oregonstate.edu/sar11/$infolder" . "HTML/$infile.html#$h_gi";


        #        my $i = 0;
        #        foreach my $hsp (@hsps) {
        for (my $i = 0; $i <= (scalar(@hsps) - 1); ++$i) {
            my $strand = $hsps[$i]->strand();
            my @qrange = $hsps[$i]->range('query');
            my @hrange = $hsps[$i]->range('hit');
            #	++$i;
            
            if ($opt_v || $debug) {

                print $hit->name() . " hsp " . ($i + 1) . "\n";
                print "\tquery range:\t$qrange[0] - $qrange[1] ($strand{$strand})\n";
                print "\thit range:\t$hrange[0] - $hrange[1]\n";
            }

            if ($hsps[$i + 1]) {
                my @tempRange = sort { $a <=> $b } ($hsps[$i]->end(), $hsps[$i + 1]->start());

                $confidence = $low;
                my $range_lo = $tempRange[0] - 2;
                my $range_hi = $tempRange[1] + 2;
                if ($range_lo <= $o_start && $o_start <= $range_hi) {
                $confidence = $high;
                } elsif ($range_lo <= $o_end && $o_end <= $range_hi) {
                $confidence = $high;
                } elsif (($range_lo - ($range_lo * 0.25)) <= $o_start && $o_start <= ($range_hi + ($range_hi * 0.25))) {
                $confidence = $med;
                } elsif (($range_lo - ($range_lo * 0.25)) <= $o_end && $o_end <= ($range_hi + ($range_hi * 0.25))) {
                $confidence = $med;
                }

#	    my @tempRange = sort { $a <=> $b } ($hsps[$i]->end(), $hsps[$i + 1]->start());

                print OUT $result->query_name() . "\t$o_start\t$o_end\t$range_lo - $range_hi\t" . $hit->name() . "\t$confidence\t$hlink\n";
            }

        }
        print "\n\n" if ($opt_v || $debug);
        }


    }
  }
}
close(OUT);
print "\n\nfinished\n\n" if ($opt_v);


sub sortHits {
  my $hits = shift;
  my $parameter = shift;
  my @sorted;

  if ($parameter == 1) {
    @sorted = sort { $a->start() <=> $b->start() } @$hits;
  } elsif ($parameter == 2) {
    @sorted = sort { $a->end() <=> $b->end() } @$hits;
  }

  return @sorted;
}

sub checkOverlap {
  my $hsps = shift;
  my $overlap = shift;
  my $context = shift; ## usually either 'query' or 'hit'
  my @return;

  for (my $i = 0; $i < (scalar(@$hsps) - 1); ++$i) {
    my $end1 = $hsps->[$i]->end($context);
    my $start2 = $hsps->[$i + 1]->start($context);
    print "For $context, testing whether ($end1 - $start2) <= $overlap\n" if ($debug);

    if (($end1 - $start2) <= $overlap) {
      ($i == 0) ? push(@return, $hsps->[$i], $hsps->[$i + 1]) : push(@return, $hsps->[$i + 1]);
    }

  }

  return @return;
}

sub checkSeparation {
  my $hsps = shift;
  my $distance = shift;
  my @return;

  for (my $i = 0; $i < (scalar(@$hsps) - 1); ++$i) {
    my $end1 = $hsps->[$i]->end();
    my $start2 = $hsps->[$i + 1]->start();
    print "testing whether ($start2 - $end1) <= $distance\n" if ($debug);
    if (($start2 - $end1) <= $distance) {
      ($i == 0) ? push(@return, $hsps->[$i], $hsps->[$i + 1]) : push(@return, $hsps->[$i + 1]);
    }

  }
  return @return;
}

sub o_gene {
  my $result = shift;
  my($start,$end, $descr,$length,$o_length);

  $descr = $result->query_description();
  $length = $result->query_length();

  if ($descr =~ /\[\+\s(\d+)\supstream\s\:\s\+\s(\d+)\sdownstream\]/) {
    $start = $1;
    $end = $length - $1;
  } else {
    $start = 1;
    $end = $length;
  }

  return ($start,$end);
}


sub makeGIindex {
  my $db = shift;
  my $dbfile = "$db" . ".psd";
  my(%gi,%acc,%gi_ref);
  if ($db_update) {
    print "makeGIindex:  making index of '$dbfile'\n" if ($verbose);
    tie(%gi, 'DB_File', 'gi.index', O_RDWR|O_CREAT, 0644, $DB_BTREE) or die "can't tie gi.index: $!";
    tie(%acc, 'DB_File', 'acc.index', O_RDWR|O_CREAT, 0644, $DB_BTREE) or die "can't tie acc.index: $!";
    tie(%gi_ref, 'DB_File', 'db.index', O_RDWR|O_CREAT, 0644, $DB_BTREE) or die "can't tie db.index: $!";
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
  } else {
    print "reusing existing index of '$dbfile'\n" if ($verbose);
    tie(%gi_ref, 'DB_File', 'db.index', O_RDONLY, 0444, $DB_BTREE) or die "can't tie db.index: $!";
  }

  return \%gi_ref;

}
