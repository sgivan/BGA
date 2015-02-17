#
#===============================================================================
#
#         FILE:  concat.coord.t
#
#  DESCRIPTION:  Test script for concat.coord file.
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

use Test::More tests => 13;

say "testing file concat.coord";
my $rtn = open(my $CONCAT,"<",'concat.coord');

cmp_ok($rtn,'>=',1,'file open');

my $firstline = <$CONCAT>;

my @firstlinevals = split /\s+/, $firstline;

is(scalar(@firstlinevals),5,'first line column check');

# 00001       1    1668  +1   0.719

is($firstlinevals[0],'00001','value 1');
is($firstlinevals[1],1,'value 2');
is($firstlinevals[2],1668,'value 3');
is($firstlinevals[3],'+1','value 4');
is($firstlinevals[4],0.719,'value 5');

my $lastline;
while (<$CONCAT>) {
    $lastline = $_ if ($_);
}

my @lastlinevals = split /\s+/, $lastline;

is(scalar(@lastlinevals),5,'last line column check');

# 00464 1498442 1497468  -3   0.562

is($lastlinevals[0],'00464','value 1');
is($lastlinevals[1],1498442,'value 2');
is($lastlinevals[2],1497468,'value 3');
is($lastlinevals[3],-3,'value 4');
is($lastlinevals[4],0.562,'value 5');

