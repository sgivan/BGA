#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  annotator_bsub.pl
#
#        USAGE:  ./annotator_bsub.pl  
#
#  DESCRIPTION:  Script to submit ORFs to be annotated with functional information.
#                   The goal of this script is to submit individual ORFs to bsub.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  06/19/14 06:32:58
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args

use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

my ($debug,$verbose,$help,$project,$orf_name,$contig_name,$all_orfs,$nosave);

my $result = GetOptions(
    "project:s" =>  \$project,
    "orf:s"     =>  \$orf_name,
    "contig:s"  =>  \$contig_name,
    "all_orfs"  =>  \$all_orfs,
    "nosave"    =>  \$nosave,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    help();
    exit(0);
}
$verbose = 1 if ($debug);

if (!$project) {
    say "you must specify a project using --project";
    exit(0);
}

Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;

my (%contig,@contigs,@orfnames,@orfs);

if ($contig_name) {

    my $contig = GENDB::contig->init_name($contig_name);
    @orfs = values(%{$contig->fetchorfs()});

} elsif ($orf_name) {

    push(@orfnames,$orf_name);

} elsif ($all_orfs) {

  @contigs = values %{GENDB::contig->fetchallby_name()};
  for my $contig (@contigs) {
      #@orfs = values(%{$contig->fetchorfs()});
      push(@orfs, values(%{$contig->fetchorfs()}));
  }

} else {

    say "you must choose from among --orf, --contig and --all_orfs";
    exit(0);

}

if (scalar(@orfs)) {
    for my $orfobj (@orfs) {
        next if ($orfobj->status() && $orfobj->status() == 2); # skip ignored ORFs
        next if (!$orfobj->frame()); # skip tRNA's and rRNA's
        push(@orfnames,$orfobj->name());
    }
}

my $loopcnt;
for my $orfname (@orfnames) {
    ++$loopcnt;
    if ($debug) {
        say "orf name: '$orfname'";
        last if ($loopcnt == 10);
    }
    
    #submit to bsub
    my $BSUB;
    if ($debug) {
        if ($nosave) {
            open($BSUB,"-|","bsub -J $orfname -o $orfname.o -e $orfname.e 'annotator.pl -a '1,2' -p $project -G -v -D -T -R -F annotator.$orfname.out -o $orfname -z'") or die "can't submit job using bsub: $!";
        } else {
            open($BSUB,"-|","bsub -J $orfname -o $orfname.o -e $orfname.e 'annotator.pl -a '1,2' -p $project -G -v -D -T -R -F annotator.$orfname.out -o $orfname'") or die "can't submit job using bsub: $!";
        }
    } else {
        open($BSUB,"-|","bsub -J $orfname -o $orfname.o -e $orfname.e 'annotator.pl -a '1,2' -p $project -G -v -D -T -R -F annotator.$orfname.out -o $orfname'") or die "can't submit job using bsub: $!";
    }
    my @bsub_output = <$BSUB>;
    #close(<$BSUB>);
    say @bsub_output if ($verbose);
}

sub help {

    say <<HELP;

    "project:s" =>  \$project,
    "orf:s"     =>  \$orf_name,
    "contig:s"  =>  \$contig_name,
    "all_orfs"  =>  \$all_orfs,
    "nosave"    =>  \$nosave,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,

HELP

}


