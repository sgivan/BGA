#!/usr/bin/env perl

# $Id: cog_load_local_missing.pl,v 3.2 2005/12/08 17:49:50 givans Exp $

use warnings;
use strict;
use Carp;
use lib '/home/sgivan/projects/COGDB';
use COGDB_Load;
use COGDB;

my $file = $ARGV[0];
if (! $file) {
  my $script = $0;
  $script =~ s/.+\///;
  print "usage:  $script <file name>\n";
  exit(0);
}

my $organism_id = $file;
$organism_id =~ s/whogs_missing_//;
#print "organism ID = '$organism_id'\n";


my $dbload = COGDB_Load->new();
$dbload->localcog_load();

my $cogdb = COGDB->new();
my $local_cogdb = $cogdb->localcogs();
my $organism = $local_cogdb->organism({ ID => $organism_id});
print "organism name: ", $organism->name(), "\n";

my $cat_load = $dbload->whog();

$cat_load->parse_missing($file,$organism_id);

