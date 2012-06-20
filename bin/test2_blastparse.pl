#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use lib '../lib';
use BGA::Util;
use Test::More;

my ($debug,$verbose,$help,$infile,$outfile);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile=s"  =>  \$infile,
    "outfile=s" =>  \$outfile,
);
# for testing, hardcode the infile
$infile = '../test/test2.blastx';
my $bga = BGA::Util->new();
$bga->coverage(0.65);
$bga->debug(0);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;


HELP

}

is($infile,'../test/test2.blastx','infile OK');
is(ref($bga),'BGA::Util','created BGA::Util object correctly');
#$bga->debug(1);

$bga->parse_report($infile);

my ($bestHit,$bestscore,$best_scoredata,$scores) = $bga->bestHit();

# $bestHit is a reference to an array:
#  [0] tool score
#  [1] tool E-value
#  [2] hit description
#  [3] ID of hit from it's particular database
#  [4] Bio::Seq or Bio::PrimarySeq object containing the hit sequence

#say "best hit";
#for my $val (@$bestHit) {
#    say "$val";
#}

is($bestHit->[3],'gi|336445404|gb|AEI58770.1|','identified gi|336445404|gb|AEI58770.1|');

done_testing();

