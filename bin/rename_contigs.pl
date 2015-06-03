#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  rename_contigs.pl
#
#        USAGE:  ./rename_contigs.pl  
#
#  DESCRIPTION:  Script to rename contigs in an annotation project to conform
#                   to ad-hoc standard.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  06/03/15 14:31:57
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;

my ($debug,$verbose,$help,$infile);

my $result = GetOptions(
    "infile:s"  =>  \$infile,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;
 
--infile
--debug
--verbose
--help  

HELP

}


open(my $IN, "<", $infile);
open(my $OUTSEQS, ">", 'outseqs.fa');
open(my $MAP, ">", 'outseqs_map.txt');

my $cnt = 0;
while (<$IN>) {
    chomp(my $inline = $_);

#    say $inline if ($debug);

    if (index($inline,'>') == 0) {
        ++$cnt;
        say $cnt if ($debug);
        if ($inline =~ />(.+)\b/) {
            $inline = ">C$cnt";
            say $MAP "$1\tC$cnt";
        }
    }
    say $OUTSEQS $inline;
}
