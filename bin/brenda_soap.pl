#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  brenda_soap.pl
#
#        USAGE:  ./brenda_soap.pl  
#
#  DESCRIPTION:  Script to retrieve information from the BRENDA database
#                   http://www.brenda-enzymes.org/index.php4
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  06/20/14 13:42:53
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use SOAP::Lite;

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

my $resultString = SOAP::Lite
-> uri('http://www.brenda-enzymes.org/soap2')
-> proxy('http://www.brenda-enzymes.org/soap2/brenda_server.php')
#-> getSynonyms("ecNumber*1.3.5.1#organism*Escherichia coli#")
#-> result;
#-> getKmValue("ecNumber*1.1.1.1#organism*Homo sapiens#")
->getEcNumber("casRegistryNumber*9031-72-5")
-> result; 

print $resultString;

sub help {

    say <<HELP;


HELP

}


