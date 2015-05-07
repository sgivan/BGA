#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  genDB_getIntergenic.pl
#
#        USAGE:  ./genDB_getIntergenic.pl  
#
#  DESCRIPTION:  Script to collect all the intergenic regions
#                   from a genDB genome project and output
#                   them in a multi-fasta file.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  11/24/14 16:58:45
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use Bio::Seq::SeqFactory;
use Bio::SeqIO;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;
#use Data::Dumper;
#$Data::Dumper::Indent = 3;
#$Data::Dumper::Pair = ":";
use Data::Printer;

my ($debug,$verbose,$help,$outfile,$project,$contig_name,$minlen);

my $result = GetOptions(
    "out=s"     =>  \$outfile,
    "project=s" =>  \$project,
    "contig=s"  =>  \$contig_name,
    "minlens=i" =>  \$minlen,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

my $format = 'fasta';
#$outfile = 'outfile' unless ($outfile);
$minlen = 100 unless ($minlen);# minimum amount of DNA sequence before/after first/last ORF on contig

if ($help) {
    help();
    exit(0);
}
help() unless ($project);

sub help {

say <<HELP;

    --out         =>  output file name, if unused outputs to STDOUT
    --project     =>  project name; ie PS0106
    --contig      =>  contig name; if unused all contigs are fetched
    --minlen      =>  minimum length of intergenic region to accept
                        default = 100nt
    --debug       =>  debugging output to STDOUT
    --verbose     =>  verbose output to STDOUT
    --help        =>  this help menu

HELP

}

my ($seqio);
if ($outfile) {
  #  open(OUT,">$outfile") or die "can't open '$outfile': $!";
  $seqio = Bio::SeqIO->new(
			   -file	=>	">$outfile",
			   -format	=>	$format,
			  );
} else {
  #  open(OUT,">&STDOUT") or die "can't open STDOUT: $!";
  $seqio = Bio::SeqIO->new(
			   -fh		=>	\*STDOUT,
			   -format	=>	$format,
			  );
}

select(STDERR) if ($verbose || $debug);

Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;

my (%contig,@contigs);
my $factory = Bio::Seq::SeqFactory->new( -type => 'Bio::Seq' );

if ($contig_name) {
  push(@contigs,GENDB::contig->init_name($contig_name));
} else {
  @contigs = values %{GENDB::contig->fetchallby_name()};
}

foreach my $contig (@contigs) {
    my %intergenic_regions = ();
    my @orfs = sort {$a->start() <=> $b->start()} values %{$contig->fetchorfs()};
    my $orfslength = scalar(@orfs);
    my $contig_bioseq = $factory->create( -id => $contig->name(), -seq => $contig->sequence());
    say "contig ", $contig->name(), " is ", $contig_bioseq->length(), "nt long" if ($debug);
    #for (my $i = 0; $i < scalar(@orfs); ++$i) {
    for (my ($i,$j) = (0,1); $i < $orfslength; ++$i, ++$j) {
        my $porf = $orfs[$i-1];
        my $orf = $orfs[$i];
        my $norf = $orfs[$j];
        my ($istart,$istop) = ();
        say "\norf name: '" . $orf->name() . "'\tstart: '" . $orf->start() . "'\tstop: '" . $orf->stop() . "'" if ($debug);
        if ($i == 0) {
            say "this is the first ORF on contig" if ($debug);
            if ($orf->start() == 0) {
                say "no upstream sequence" if ($debug);
            } else {
                say "upstream sequence present" if ($debug);
                $istart = 1;
                $istop = $orf->start() - 1;
                $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
            }
            # special case where this is the only ORF on contig
            if (!$norf) {
                $istart = $orf->stop() + 1;
                $istop = $contig_bioseq->length();
                $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
            } else {
                $istart = $orf->stop() + 1;
                $istop = $norf->start() -1;
                $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
            }

        } elsif ($orf && $norf) {
            say "determining intergenic region" if ($debug);
            $istart = $orf->stop() + 1;
            $istop = $norf->start() - 1;
            $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
        } elsif ($j == $orfslength) {
            say "this is the last ORF on the contig" if ($debug);
            # should only get here if there are ORFs 5' of this ORF
            if ($porf) {
                $istart = $porf->stop() + 1;
                $istop = $orf->start() - 1;
                $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
            }
            if ($contig_bioseq->length() - $orf->stop() >= $minlen) {
                $istart = $orf->stop + 1;
                $istop = $contig_bioseq->length();
                $intergenic_regions{$contig->name() . "." . $istart . "." . $istop} = [$istart,$istop,$istop-$istart,$contig->name(),$orf->name()];
            }
        }
        
        # I can't put the assignment statement here b/c in some special cases I need to assign two
        # values; ie for a contig with <= two ORFs
        #$intergenic_regions{$istart . "." . $istop} = [$istart,$istop,$contig->name(),$orf->name()];
    }
    p %intergenic_regions if ($debug);

    if (scalar(keys %intergenic_regions)) { # if there are any intergenic regions
        for my $arrayref (values %intergenic_regions) {
            next if ($arrayref->[2] < $minlen);
            my $subseq = $contig_bioseq->subseq(
                    -START  =>  $arrayref->[0],
                    -END    =>  $arrayref->[1],
            );
            my $intergenic_seq = $factory->create(
                    -id     =>  $arrayref->[3] . "." . $arrayref->[0] . "." . $arrayref->[1],
                    -seq    =>  $subseq,
                );
            $seqio->write_seq($intergenic_seq);
        }
    }
    
}

