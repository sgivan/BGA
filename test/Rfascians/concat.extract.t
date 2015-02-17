#
#===============================================================================
#
#         FILE:  concat.extract.t
#
#  DESCRIPTION:  Test script for concat.extract file.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/17/15 15:49:34
#     REVISION:  ---
#===============================================================================

use v5.10;
use strict;
use warnings;
use autodie;

use Test::More tests => 10;

say "testing file concat.extract";
my $rtn = open(my $EXTRACT,"<",'concat.extract');

cmp_ok($rtn,'>=',1,'file open');

my @content = <$EXTRACT>;

my @ids = grep /^>/, @content;

is(scalar(@ids),464,'464 seqs extracted');

my @firstseqidvals = split /\s+/, $ids[0];
# >00001  1 1668  len=1665

is($firstseqidvals[0],'>00001','first seq ID');
is($firstseqidvals[1],1,'first seq start');
is($firstseqidvals[2],1668,'first seq stop');
is($firstseqidvals[3],'len=1665','first seq length');

my @lastseqidvals = split /\s+/, $ids[$#ids];

# >00464  1498442 1497468  len=972

is($lastseqidvals[0],'>00464','last seq ID');
is($lastseqidvals[1],1498442,'last seq start');
is($lastseqidvals[2],1497468,'last seq stop');
is($lastseqidvals[3],'len=972','last seq length');

