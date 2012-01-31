#!/usr/bin/perl
# $Id: genDB_prepare_fasta.pl,v 3.2 2005/06/30 23:16:31 givans Exp $

use warnings;
use strict;
use Carp;
use DB_File;
use Fcntl;
use Getopt::Std;
use vars qw/ $opt_h $opt_v $opt_f /;

getopts('hvf:');

my ($help,$verbose,$infile,$outfile);
$help = $opt_h;
$verbose = $opt_v;
$infile = $opt_f;

my $usage = "genDB_prepare_fasta.pl <options> -f <input file name>";

my $help_mssg = <<HELP;

This script uses a pre-parsed database of GenDB sequence identifiers
and a fasta file of proteins sequences from the project and converts
genDB sequence identifiers to user-determined locus tag identifier.
This is mainly useful in preparing a genome submission to NCBI.

usage:  $usage

Options:
-f	input file name (required)
-t	locus tag prefix (default = PRE)
-v	verbose output to terminal
-d	debug mode



HELP

if (!$infile || $help) {
  print $help_mssg;
  exit(0);
} elsif (!-e $infile) {
  print "'$infile' doesn't exist\n";
  exit(0);
}

$outfile = $infile;
$outfile = "$outfile" . ".out";

print "opening name database 'id_map.db'\n" if ($verbose);
my %db;
tie %db, "DB_File", 'id_map.db', O_RDONLY, 0444;

print "database has ", scalar(keys(%db)), " entries\n" if ($verbose);

print "opening '$infile'\n" if ($verbose);
open(IN,$infile) or die "can't open $infile: $!";

print "opening '$outfile'\n" if ($verbose);
open(OUT,">$outfile") or die "can't open $outfile: $!";

my $skip = 0;
foreach my $line (<IN>) {
  chomp($line);

  if ($line =~ /^\>(.+?)\s/) {
    my ($old,$new) = $1;
    if ($db{$old}) {
      $skip = 0;
      $new = $db{$old};
    } else {
      $skip = 1;
      next;
#      $new = $old;
    }
    $line = ">$new ";
#    $line = ">$new [transl_table=11]";
  } elsif ($skip) {
    next;
  }

  print OUT "$line\n";
}



untie %db;
close(IN);
close(OUT);
