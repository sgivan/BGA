#
#===============================================================================
#
#         FILE:  concat.detail.t
#
#  DESCRIPTION: Script to test concat.detail output file. 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 16:33:11
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use strict;
use warnings;

use Test::More tests => 4;

say "testing file concat.detail";

my $rtn = open(my $DETAIL,"<",'concat.detail');

ok($rtn >= 1,'file opened');

my @content = <$DETAIL>;

my $firstline = $content[0];

is($firstline,"Command:  glimmer3 -o 30 -g 50 -l concat.nfa orf.00.model concat\n",'first line ');

is(scalar(@content),19083,'lines in file ');

my $lastline = $content[$#content];

is($lastline,"2609    -1  1499049  1499022  1498498      549     522    14.36    99  0  -  - 99  -  -  0\n",'last line ');
