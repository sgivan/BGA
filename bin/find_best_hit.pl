#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use lib '../lib';
use lib '/home/sgivan/projects/BGA/lib';
use BGA::Util;

my ($debug,$verbose,$help);
my ($infile,$evalue,$hits,$coverage,$tab);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile=s"  =>  \$infile,
    "evalue=f"  =>  \$evalue,
    "hits=i"    =>  \$hits,
    "coverage=f"    =>  \$coverage,
    "tab"       => \$tab,
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

if (!$tab) {
    say "best hit:";
    for my $val (@$bestHit) {
        say "$val";
    }
} else {
    if (exists($bestHit->[0])) {
        say "$bestHit->[4]\t$bestHit->[3]\t$bestHit->[0]\t$bestHit->[1]\t$bestHit->[2]";
    }
}

sub help {

say <<HELP;

Script to identify the "best" BLAST hit

--infile    name of infile
--evalue    minimum acceptable evalue (default = 1e-6)
--hits      number of hits to parse per file (not yet implemented)
--coverage  minimum proportional coverage of hit to query (default = 0.65)
--tab       generate tab-delimited output
--debug
--verbose
--help


HELP

}

