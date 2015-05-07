#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  populate_GO_table.pl
#
#        USAGE:  ./populate_GO_table.pl  
#
#  DESCRIPTION:  Script to populate the gene_ontology table within the BGA database.
#                 This is primarily accomplished by collecting PFAM domain IDs from data
#                 table and using them to collect GO data from Pfam database.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  05/15/14 16:03:44
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args

use lib '../lib';
use BGA::PFAM;
use BGA::GeneOntology;
use BGA::Data;

my ($debug,$verbose,$help,$database,$quality_threshold) = (0,0,0,'test_gendb',1e-6);

my $result = GetOptions(
    "evalue=f"  =>  \$quality_threshold,
    "database=s"  =>  \$database,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($debug) {
    $verbose = 1;
    say "option summary: \
    debug       => '$debug'
    verbose     =>  '$verbose',
    evalue      =>  '$quality_threshold',
    database    =>  '$database',
    help        =>  '$help'
    ";
}

if ($help) {
    help();
    exit(0);
}

#
# main
# 
#

my $data = BGA::Data->new();
my $pfam = BGA::PFAM->new();
$data->specify_database($database);

my $pfam_data_iterator = $data->fetch_pfam_data_iterator();

my ($loopcnt,$insertcnt) = (0,0);
while (my $pfam_row = $pfam_data_iterator->next()) {
    say $pfam_row->dbref() if ($debug);

    next if ($pfam_row->toolresult <= $quality_threshold);


    my $pfam_autoID = $pfam->id_to_autoID($pfam_row->dbref());
    say $pfam_autoID if ($debug);

    my $go_info = $pfam->go_info($pfam_row->dbref());

    for my $go_row (@$go_info) {
        my $go = BGA::GeneOntology->new();
        say join "; ", @{$go_row} if ($debug);
        $go->orf_id($pfam_row->orf_id());
        $go->auto_pfamA($pfam->id_to_autoID($pfam_row->dbref()));
        $go->go_id($go_row->[0]);
        $go->term($go_row->[1]);
        $go->category($go_row->[2]);
        $go->save();
        ++$insertcnt;
    }

    say "" if ($debug);
    last if ($debug && $loopcnt++ == 100);
}

say "inserted $insertcnt rows" if ($verbose);

#
# subroutines
#

sub help {

say <<HELP;

Script to populate the gene_ontology table in a BGA database
This uses Pfam domains to infer GO terms

--database      the database to interact with
--evalue        minimum E-value of Pfam hit to accept [default = 1e-6]
--help          print this help message
--verbose       verbose output to terminal
--debug         debugging mode


HELP

}


