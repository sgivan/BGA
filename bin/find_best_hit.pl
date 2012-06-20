#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use lib '../lib';
use BGA::Util;

my ($debug,$verbose,$help);
my ($infile,$evalue,$hits,$coverage);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile=s"  =>  \$infile,
    "evalue=f"  =>  \$evalue,
    "hits=i"    =>  \$hits,
    "coverage=f"    =>  \$coverage,
);

if ($help) {
    help();
    exit(0);
}

my $bga = BGA::Util->new();
$bga->debug(1) if ($debug);
#$bga->parse_report($infile);
$bga->evalue($evalue) if ($evalue);
$bga->coverage($coverage) if ($coverage);

$bga->parse_report($infile);

my ($bestHit,$bestscore,$best_scoredata,$scores) = $bga->bestHit();

say "best hit:";
for my $val (@$bestHit) {
    say "$val";
}

sub help {

say <<HELP;

Script to identify the "best" BLAST hit

--infile
--evalue
--hits
--debug
--verbose
--help


HELP

}

