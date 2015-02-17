#
#===============================================================================
#
#         FILE:  concat.predict.t
#
#  DESCRIPTION: Script to test file concat.predict 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 16:44:18
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use strict;
use warnings;

# declare number of tests to run
use Test::More tests => 4;

my $rtn = open(my $PREDICT,"<",'concat.predict');

ok($rtn >= 1,"file opened");

my @content = <$PREDICT>;

my $first = $content[1];# second line of file
my $last = $content[$#content];

is($first,"orf00001        1     1668  +1    12.46\n","first line");
is(scalar(@content),1587,"number of lines in file");
is($last,"orf02609  1499022  1498498  -1    14.05\n","last line");

