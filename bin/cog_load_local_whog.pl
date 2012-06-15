#!/usr/bin/env perl

# $Id: cog_load_local_whog.pl,v 3.1 2005/12/08 17:48:16 givans Exp $

use warnings;
use strict;
use Carp;
use lib '/home/sgivan/projects/COGDB';
use COGDB_Load;

my $file = $ARGV[0];
if (! $file) {
  my $script = $0;
  $script =~ s/.+\///;
  print "usage:  $script <whog file name>\n";
  exit(0);
}

my $dbload = COGDB_Load->new();
$dbload->localcog_load();

my $cat_load = $dbload->whog();

my $whognum = $cat_load->parse_file($file);

print "$whognum whogs loaded\n";
