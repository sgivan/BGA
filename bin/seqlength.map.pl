#!/usr/bin/env perl
# $Id: seqlength.map.pl,v 1.4 2004/11/03 01:11:04 givans Exp $

use Bio::SeqIO;
use Getopt::Long;

my ($infile,$format,$outfile);
my $argparse = GetOptions(
							"infile=s"	=>	\$infile,
							"format=s"	=>	\$format,
							"outfile=s"	=>	\$outfile,
						);

my $file = $ARGV[0];
$file = $infile unless ($file);
$format = 'fasta' unless ($format);

print "Enter file name on command line\n" unless ($file);


$outfile = "$file" . ".lengthmap" unless ($outfile);

open(OUT,">$outfile") or die "can't open $outfile: $!";

my $seqio = Bio::SeqIO->new(	
							-file	=>	$file,
							-format	=>	$format,
				);

while (my $seq = $seqio->next_seq()) {
  my $id = $seq->id();

  my $length = $seq->length();

  print OUT "$id\t$length\n";

}

close(OUT);

