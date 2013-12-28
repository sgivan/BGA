#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  rbs_eval.pl
#
#        USAGE:  ./rbs_eval.pl  
#
#  DESCRIPTION:  Evaluate results of rbs_refine.pl
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan, Ph.D.
#      COMPANY:  University of Missouri
#      VERSION:  1.0
#      CREATED:  12/24/13 06:00:56
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;


#!/usr/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;

my ($debug,$verbose,$help,$file);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "file=s"      =>  \$file,
);

if (!$file) {
    help();
    exit(0);
}

# put help menu subroutine here for clarity
#
if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;

    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "file"      =>  \$file,

HELP

}


open(my $IN,'<',$file);

while (my $line = <$IN>) {

    print $line;
}

