#!/usr/bin/env perl
# $Id: gi_fetch.pl,v 1.8 2005/07/13 06:02:37 givans Exp $
#
#
# Fetches GI list from NCBI
#
# Script written by Scott Givan, Center for Gene Research and
# Biotechnology, Oregon State University
#
#

use warnings;
use strict;
use Carp;
#use LWP::Simple;
use LWP::UserAgent ();
use Getopt::Std;
use vars qw/ $opt_d $opt_s $opt_q $opt_o $opt_h $opt_c $opt_v /;

my($mol,$term,$file) = ();

# Get command line options or ask for them

getopts('d:s:qo:hcv');

if ($opt_h) {
    print <<EOF;
\nProgram to fetch GI numbers from NCBI\n
Option\tDescription
-d\tFor which type of molecule do you want GI\'s, nucleotide or protein;\n\tdefault = \'nucleotide\'
-s\tSearch term\n\tNo default - must be entered by user
-c\tonly return the number of gi\'s identified
-q\tQuite mode
-o\tOutput file name\n\tdefault = STDOUT
-v\tverbose output to STDOUT
-h\tPrint command line options\n\n
EOF
exit;
}

if (!$opt_d) {
    print "For which type of molecule do you want the GI's for ([nucleotide] or protein)?  ";
    $mol = <STDIN>;
    chomp $mol;
    $mol = 'nucleotide' if (!$mol);
} else {
    if ($opt_d eq 'nucleotide' || $opt_d eq 'protein') {
	$mol = $opt_d;
    } else {
	die "-d must be followed by either 'nucleotide' or 'protein'\n";

    }
}


if (!$opt_s) {
    print "What is your search term?  ";
    $term = <STDIN>;
    chomp $term;
    die "You must enter a valid search term." unless ($term =~ /\w+/);
} else {
    if ($opt_s =~ /\w+/) {
	$term = $opt_s;
    } else {
	die "-s must be followed by a valid search term.\nMultiple terms should be enclosed in quotes.\n";
    }
}

if ($opt_o) {
    if ($opt_o =~ /\w+/) {
	$file = $opt_o;
    } else {
	die "-o must be followed by a valid file name.\n";
    }
}# else {
#    $file = 'gi.list';
#    $file = "STDOUT"
#}

print STDOUT "Fetching all '$mol' sequences from '$term'\n" unless ($opt_q);

#
# Begin formatting Entrez query
#
#
my $ua = LWP::UserAgent->new();
my $db = $mol;
my $http = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?email=givans\@missouri.edu&tool=gi_fetch&api_key=6ad2ae5229a12863da697058ef31e477a808&db=$db";

open(GI,">$file") || die "can't open '$file': $!" if ($file);

my $URL = $http . "&term=$term";

# use LWP::UserAgent
my $esearch_count_result;
my $esearch_count_response = $ua->get($URL);
if ($esearch_count_response->is_success()) {
    print "success!\n";
    $esearch_count_result = $esearch_count_response->decoded_content();
} else {
    print $esearch_count_response->status_line();
    die();
}

# $esearch_count_result will contain how many records
# match the query.  We will need this number when
# fetching the GI's from NCBI.
#

if ($opt_v) {
    print STDERR "eutils query URL: $URL\n";
}

my $count = "";
if ($esearch_count_result && $esearch_count_result =~ /\<Count\>(\d+)\<\/Count\>/) {
    $count = $1;
} else {
    print STDERR "can't extract count from result file\n" unless ($opt_q);
    print STDERR "result: '$esearch_count_result'\n" if ($opt_v);
}

print STDOUT "$count GI's returned\n" unless ($opt_q);

exit(0) if ($opt_c);

sleep(5);

#
# Now that we have the number of GI's to retrieve, send the query
# to return the full GI list
#
print STDOUT "Fetching $count GI's from NCBI\n";
my $total = 0;
for (my ($retstart,$retmax) = (0,0); $retstart < $count; $retmax += 100000, $retstart = $retmax - 100000) {

    if (!$retmax) {
        $retmax += 100000;
    } else {
        #  $retstart = $retmax + 1;
    }

    sleep(1);
    print "fetching $retstart to $retmax GI's\n";

    my $esearch2_URL = $http . "&retstart=$retstart&retmax=$retmax&" . "term=$term" ;
    print STDERR "URL: '$esearch2_URL'\n" if ($opt_v);

    my $esearch_response = $ua->get($esearch2_URL);

    my $esearch_result;
    if ($esearch_response->is_success()) {
        print STDERR "fetched up to ID #$retmax\n" if ($opt_v);
        $esearch_result = $esearch_response->decoded_content();
    } else {
        print STDERR "failed to fetch up to ID #$retmax\n";
        print STDERR "status line: " . $esearch_response->status_line();
        exit(1);
    }

    my @esearch = split /\n/, $esearch_result;

    foreach my $line (@esearch) {

        if ($line =~ /\<Id\>(\d+)\<\/Id\>/) {
            ++$total;
            no strict 'refs';
            print { $file ? "GI" : "STDOUT" } "$1\n";
            use strict 'refs';
        } else {
            next;
        }
    }

}

close(GI) if ($file);

print STDOUT "$total gi's added to $file\n" unless ($opt_q);
