#
#===============================================================================
#
#         FILE:  concat_orf30.nfa.t
#
#  DESCRIPTION:  Script to test file concat_orf30.nfa
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 16:54:39
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use strict;
use warnings;

# declare number of tests to run
use Test::More tests => 4;

my $rtn = open(my $SEQ,"<","concat_orf30.nfa");

ok($rtn >= 1,'file opened');

my @content = <$SEQ>;

my @seqs = grep /^>/, @content;

is($seqs[0],">orf00003 [+ 30 upstream]\n",'first sequence');
is(scalar(@seqs),1585,'number of sequences');
is($seqs[$#seqs],">orf02609 [+ 30 upstream]\n",'last sequence');
