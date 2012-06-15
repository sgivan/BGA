#!/usr/bin/env perl
# $Id: novelcogGFF.pl,v 3.2 2005/08/04 18:59:59 givans Exp $
use warnings;
use strict;
use Carp;
use lib '/home/sgivan/projects/BGA/share/genDB/share/perl';
use lib '/home/sgivan/projects/COGDB';
use COGDB;
use Getopt::Std;
use vars qw/ $opt_h $opt_v $opt_d $opt_o $opt_O /;
use Projects;

getopts('hvdo:O');

my $usage = "novelcogGFF.pl -o <organism code>";

my $org_code = $opt_o;
my $verbose = $opt_v;
my $orfan = $opt_O;
my $novel = 1;
$novel = 0 if ($orfan);

if ($opt_h) {

print <<HELP;

This program generates a GFF format file containing the coordinates
of ORFs contained within the genome of the user-selected organism
that have been classified as "novel".

usage:  $usage

Options		Description
-o text		Organism Code
-O		Generate Orphan COG GFF file [orfanCOGs.gff]
-h		print this help menu
-v		verbose output to the terminal
-d		debugging mode


HELP
exit(0);
}

if (!$org_code) {
  print "usage:  $usage\n";
  exit(0);
}

Projects::init_project($org_code);
require GENDB::orf;
require GENDB::contig;

my ($output_file,$GFF_class,%orfs,%label);
if ($novel) {
  $output_file = 'novelCOGs.gff';
  $GFF_class = 'novelcog';
} elsif ($orfan) {
  $output_file = 'orfanCOGs.gff';
  $GFF_class = 'orfan';
}
open(OUT, ">$output_file") or die "can't open '$output_file': $!";

my $cogdb = COGDB->new();
my $localcogdb = $cogdb->localcogs();
my $localwhog = $localcogdb->whog();
my $org = $localcogdb->organism({Code => $org_code});
my $whogs = $localwhog->fetch_by_organism($org);


if ($novel) {

  foreach my $whog (@$whogs) {
    next unless ($whog->novel());

    print "gene: ", $whog->name(), "; COG: ", $whog->cog()->name(), "\n" if ($verbose);
    push(@{$orfs{$whog->name()}},$whog->cog()->name());
  }
} elsif ($orfan) {
  my %whoglist;
  foreach my $whog (@$whogs) {
    ++$whoglist{$whog->name()};
  }

  my @contigs = values %{GENDB::contig->fetchallby_name()};
  my (@gendb_orfs,@orfans);
  foreach my $hashref (map { $_->fetchorfs() } @contigs) {
    push(@gendb_orfs, values %{$hashref});
  }
  print "number of orfs:  ", scalar(@gendb_orfs), "\n";

  foreach my $orf (@gendb_orfs) {
    next if ($orf->status == 2 || !$orf->frame());
    next if ($whoglist{$orf->name()});
    my $facts = $orf->fetchfacts();
    my $fact_count = keys %$facts;
    print $orf->name() . "\t" . "facts: $fact_count\n" if ($verbose);

    if (! $fact_count) {
      push(@{$orfs{$orf->name}}, $orf->name());
    } else {


      my $minscore;
      foreach my $fact (values %$facts) {

	$minscore = extractE($fact->toolresult()) unless ($minscore);
	$minscore = extractE($fact->toolresult()) if (extractE($fact->toolresult()) && extractE($fact->toolresult()) < $minscore);

      }
      push(@{$orfs{$orf->name}}, $orf->name()) if ($minscore && $minscore > 1e-04);
    }
  }
}

foreach my $name (keys %orfs) {
  my $orf = GENDB::orf->init_name($name);
  my $start = $orf->start();
  my $stop = $orf->stop();
  my $strand = '+';
  $strand = '-' if ($orf->frame() && $orf->frame() < 0);
  my $chrom = $orf->name();
  $chrom =~ s/_\w+//;

  foreach my $label (@{$orfs{$name}}) {
    print OUT "$chrom\t.\t$GFF_class\t$start\t$stop\t.\t$strand\t.\t$GFF_class $label\n";
  }

#  print OUT "$chrom\t.\t$GFF_class\t$start\t$stop\t.\t$strand\t.\t$GFF_class " . $obj->cog()->name() . "\n";
}


close(OUT);

sub extractE {
  my $toolresult = shift;

  if ($toolresult) {

    if ($toolresult =~ /e\:(.+?)\)/) {
      return $1;
    }
  }
  return $toolresult;
}
