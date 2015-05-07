#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  build_index.pl
#
#        USAGE:  ./build_index.pl  
#
#  DESCRIPTION:  Script to build index of flat file sequence database.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  02/20/14 15:55:27
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.8
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use Bio::DB::Flat;

my ($debug,$verbose,$help,$indexdir,$swiss,$kegg,$dbdir,$defaults);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "indexdir"  =>  \$indexdir,
    "swiss"     =>  \$swiss,
    "kegg"      =>  \$kegg,
    "dbdir"     =>  \$dbdir,
    "defaults"  =>  \$defaults,
);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;

options:
--debug
--verbose
--help      print this help message
--indexdir  full path to directory indices
--swiss     create index for the swissprot flatfile
--kegg      create index for the KEGG flatfile
--dbdir     full path to directory containing sequence flatfile
--defaults  add default IRCF paths to dbdir root path (for internal IRCF users)

HELP
exit(0);
}

if (!$kegg && !$swiss) {
    say "No database selected. Use either --swiss or --kegg";
    exit(0);
}

$verbose = 1 if ($debug);
#$indexdir |= '/home/sgivan/dev/lib/annotator/indices';
$indexdir |= '/home/sgivan/lib/annotator/indices';
$dbdir |= '/ircf/dbase';

if ($debug) {
    say "indexdir: '$indexdir'";
    say "dbdir: '$dbdir'";
    exit(0);
}

if ($swiss) {

    if ($defaults) {
        $dbdir .= "/swissprot/";
    }

    say "building SwissProt database" if ($verbose);

    my $toolDB = Bio::DB::Flat->new(
                    -directory  =>  $indexdir,
                    -dbname     =>  'sprot.idx',
                    -format     =>  'swiss',
                    -write_flag =>  1,
                    -index	   =>	'bdb',
                );
    #$toolDB->build_index('/ircf/dbase/swissprot/uniprot_sprot.dat');
    $toolDB->build_index($dbdir . "/uniprot_sprot.dat");
    print "swissprot index finished\n" if ($verbose);
}

if ($kegg) {

    if ($defaults) {
        $dbdir .= "/KEGG/";
    }

    say "building KEGG index" if ($verbose);

    my $toolDB = Bio::DB::Flat->new(
                    -directory  =>  $indexdir,
                    -dbname     =>  'kegg.idx',
                    -format     =>  'fasta',
                    -write_flag =>  1,
                    -index	   =>	'bdb',
                );
    #$toolDB->build_index('/ircf/dbase/KEGG/genes');
    $toolDB->build_index($dbdir . "/genes");
    print "KEGG index finished\n" if ($verbose);
}

