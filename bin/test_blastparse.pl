#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use Test::More;
use lib '../lib';
use BGA::Util;

my ($debug,$verbose,$help,$infile,$outfile);
my $bga = BGA::Util->new();
print "\$bga isa '", ref($bga), "'\n";
is(ref($bga),'BGA::Util');
$bga->debug(1);

my $result = GetOptions(
    'help'      =>  \$help,
    'verbose'   =>  \$verbose,
    'debug'     =>  \$debug,
    'infile=s'  =>  \$infile,
    'outfile=s' =>  \$outfile,
);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;
Help menu.

HELP

}

open(my $IN,'<',$infile);

while (<$IN>) {
    next if (substr($_,0,1) eq '#');
    chomp($_);
    my ($qid,$sid,$pident,$alength,$mismatches,$gapopens,$qstart,$qend,$sstart,$send,$evalue,$bitscore) = split /\t/,$_;
    $bitscore =~ s/\s//g;
    is($qid,'TCONS_00000354',"qid = '$qid'");
    is($sid,'gi|388493176|gb|AFK34654.1|', "sid = '$sid'");        
    is($pident,'74.63',"% ident = '$pident'");
    is($alength,'67',"align length = '$alength'");
    is($mismatches,'17',"no. mismatches = '$mismatches'");
    is($gapopens,'0',"gap opens = '$gapopens'");
    is($qstart,'285',"query start = '$qstart'");
    is($qend,'85',"query end = '$qend'");
    is($sstart,'5',"subj start = '$sstart'");
    is($send,'71',"subj end = '$send'");
    is($evalue,'5e-28',"evalue = '$evalue'");
    is($bitscore,'109',"bitscore = '$bitscore'");


    my $title = join ",", $bga->get_title('NR/nr',$sid);
    #say "title: '$title'"; 
    is($title,'unknown [Lotus japonicus]',"title line = '$title'");

    $bga->filter(1);
    my @words = $bga->getWords($title);
    is(scalar(@words),4, "returned 4 words");

    my $wdcnt = 0;
    for my $word (@words) {
        ++$wdcnt;
        say "$wdcnt\t$word";
    }

    my %hash = ();
    $bga->uniqueWords(\%hash,\@words,$evalue);
    my $sorted = $bga->sort_by_value(\%hash);
    $bga->printHash($sorted,\%hash,4);

    my $score = $bga->scoreData($title,\%hash);
    say "score: '$score'";
    
}

done_testing();

