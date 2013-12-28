#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use Getopt::Long; # use GetOptions function to for CL args

use Bio::Tools::GFF;

my ($debug,$verbose,$infile,$outfile,$gff_version,$gtf_version);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "gff:i"     =>  \$gff_version,
    "gtf:f"     =>  \$gtf_version,
);

# provide some sensible defaults

$infile ||= 'infile';
$outfile ||= 'outfile';
$gff_version ||= 3;
$gtf_version ||= 2;# usually the right choice
$verbose = 1 if ($debug);

my $dbin = Bio::Tools::GFF->new(-file => $infile, -gff_version => $gtf_version) or die "can't open '$infile': $!";
my $dbout = Bio::Tools::GFF->new(-file => ">$outfile", -gff_version => $gff_version) or die "can't open '$outfile': $!";

while (my $f = $dbin->next_feature()) {
    $dbout->write_feature($f);
}

say "finished";
