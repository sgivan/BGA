#!/usr/bin/env perl
# $Id: MMGdump.pl,v 3.5 2007/03/14 23:27:45 givans Exp $

use warnings;
use strict;
use Carp;
use Getopt::Std;
use vars qw/ $opt_d $opt_c $opt_z $opt_v $opt_h $opt_a /;

if (!@ARGV) {
  print "no argumens passed -- use $0 -h for help\n";
  exit();
}


getopts('dczvha');


while ($opt_h) {

print <<HELP;

usage:  MMGdump.pl <options> dbcode

Options:

-a dump all GENDB databases
-d debugging
-c include CREATE DATABASE statement
-z gzip compress output files
-v verbose output to terminal
-h print this help menu

HELP
} continue {
exit();
}

use lib '/home/sgivan/projects/BGA/share/genDB/share/perl';

use Projects;

my $verbose = $opt_v;
my $debug = $opt_d;
my $dbname = $ARGV[0];
my @DB = ();

if ($dbname) {
  push(@DB,$dbname);
} elsif ($opt_a) {
  print "dumping all MMG databases\n" if ($verbose);

  my $project = Projects->new();

  my $projects = $project->list_projects();
  foreach my $name (@$projects) {
    push(@DB,$name);
  }
}


foreach my $DB (@DB) {
  #my $dump = "mysqldump --opt --quote-names -u genDB_cluster -h pearson.science.oregonstate.local ";
  my $dump = "mysqldump --opt --quote-names -u genDB_cluster -h lewis2.rnet.missouri.edu -P 53307 -pmicrobes ";
  $dump .= "-B " if ($opt_c);## include create database statements

  $DB .= "_gendb";

  my $outfile = $DB . ".mysql";
  $outfile .= ".gz" if ($opt_z);

  print "dumping database '$DB' to file '$outfile'\n" if ($verbose);
  if ($opt_z) {
    $dump .= "$DB | gzip > $outfile";
  } else {
    $dump .= "$DB > $outfile";
  }

  open(DUMP,"$dump |") or die "can't open dump cmd: $!";
  close(DUMP) or die "can't close dump cmd: $!";

  print "finished\n" if ($verbose);

}
