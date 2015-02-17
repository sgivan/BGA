#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  run_tests.pl
#
#        USAGE:  ./run_tests.pl  
#
#  DESCRIPTION:  Run tests of BGA pipeline.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 17:05:36
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use TAP::Harness;
use File::chdir;

my ($debug,$verbose,$help);

my $result = GetOptions(
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


HELP

}

my $harness = TAP::Harness->new();

my $dirpath = "../test/Rfascians";
opendir(my $dh, $dirpath);
my @testfiles = grep { /.+\.t$/ && -f "$dirpath/$_" } readdir($dh);
closedir($dh);

#say @testfiles

$CWD = $dirpath;

$harness->runtests(@testfiles);

