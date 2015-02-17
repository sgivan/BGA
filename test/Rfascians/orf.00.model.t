#
#===============================================================================
#
#         FILE:  orf.00.model.t
#
#  DESCRIPTION:  Script to test file orf.00.model
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 16:50:15
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use strict;
use warnings;

# declare number of tests to run
use Test::More tests => 2;

my $rtn = open(my $MODEL,"<",'orf.00.model');

ok($rtn >= 1,"file opened");

my $firstline = <$MODEL>;

is($firstline,">ver = 2.00  len = 12  depth = 7  periodicity = 3  nodes = 21845\n","first line");

