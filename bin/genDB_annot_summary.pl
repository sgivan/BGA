#!/usr/bin/env perl
# $Id: genDB_annot_summary.pl,v 3.3 2005/06/30 23:16:39 givans Exp $

use warnings;
use strict;
use Carp;
use DB_File;
use Fcntl;
use Getopt::Std;
use vars qw/ $opt_h $opt_v $opt_d $opt_p $opt_g $opt_P $opt_I $opt_t /;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('hvdp:g:P:I:t:');

my ($help,$verbose,$debug,$project,$gene,$prefix,$seqID,$transl_table);
$help = $opt_h;
$verbose = $opt_v;
$project = $opt_p;
$debug = $opt_d;
$verbose = 1 if ($debug);
$gene = $opt_g;
$prefix = $opt_P;
$prefix = 'PRE' unless ($prefix);
$seqID = $opt_I;
$seqID = 'SEQ' unless ($seqID);
$transl_table = $opt_t;
$transl_table = 11 unless ($transl_table);
my $usage = "genDB_annot_summary.pl <options>";

my $help_mssg = <<HELP;

This script summarizes the annotations for genes in a GenDB
project and outputs a table that can be read by the NCBI
program tbl2asn or Sequin.

$usage

options
-p	GenDB project name (required)
-g	Specific gene from GenDB project (optional)
-P	locus tab prefix (optional; default = PRE)
-I	sequence ID (optional; default = SEQ)
-t	translation table (default = 11 [bacterial])
-v	verbose output to terminal
-d	debug mode
-h	print this help menu


HELP

if (!$project || $help) {
  print $help_mssg;
  exit(0);
}

Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;
require GENDB::annotation;
require GENDB::fact;


my %id_map;
tie %id_map, "DB_File", 'id_map.db', O_CREAT|O_RDWR, 0666;

print ">Feature $seqID\n";

my $orfs = GENDB::orf->fetchallby_id();
my %locus_tags;
my @sorted_loci;
my %orfs_valid;
foreach my $orf_id (keys %$orfs) {
  next if (!$orfs->{$orf_id}->status() || $orfs->{$orf_id}->status() == 2);
  $orfs_valid{$orf_id} = $orfs->{$orf_id};
}

foreach my $orf_id (sort { $orfs_valid{$a}->start() <=> $orfs_valid{$b}->start() } keys %orfs_valid) {
  my $orf = $orfs_valid{$orf_id};
  next if (!$orf->status() || $orf->status() == 2);

  my $coords = $orf->get_new_coords($orf->id());
  my ($start,$stop) = ($coords->[0], $coords->[1]);
  my $latest_annot = GENDB::annotation->latest_annotation_init_orf_id_old($orf_id);
  my $name = $latest_annot->name() || '';
  my $ec = $latest_annot->ec() || undef;
  my $product = $latest_annot->product() || undef;
  my $gene = $latest_annot->name() || undef;
  if ($gene) {
    $gene =~ s/C134/$prefix/;
    $gene =~ s/SAR11_chromosome/$prefix/;
    $gene =~ s/\s/_/g;
  }

  my $locus_tag = $orf->name() || undef;
  if ($locus_tag) {
    $locus_tag =~ s/C134/$prefix/;
    $locus_tag =~ s/SAR11_chromosome/$prefix/;
    $locus_tag =~ s/\s/_/g;
    ++$locus_tags{$locus_tag};
    if ($locus_tags{$locus_tag} > 1) {
      print STDERR "$locus_tag duplicated $locus_tags{$locus_tag}X\n";
    }
  }

  $id_map{$orf->name()} = $locus_tag;

  if ($orf->frame()) {

    if ($orf->frame() < 0) {
      my $temp = $stop;
      $stop = $start;
      $start = $temp;
    }

    gene($start,$stop,$gene,$locus_tag);
    print "$start\t$stop\tCDS\n";
    product($product);
    protein_id($locus_tag);
    ec_number($ec);
    transl_table();
  
  } else {

    if ($locus_tag =~ /_tRNA_.+?\(AA\:_(\w+)\,/) {
      my $aa = $1;
      $gene = undef;
      $locus_tag =~ s/_\(.+?\)//;
      gene($start,$stop,$gene,$locus_tag);
      print "$start\t$stop\ttRNA\n";
      product("tRNA-$aa");
    } elsif ($locus_tag =~ /(\d{1,2})S_rRNA/) {
      gene($start,$stop,$gene,"$prefix" . "_$locus_tag");
      print "$start\t$stop\trRNA\n";
      product("$1S ribosomal RNA");
    }
  }
}


sub gene {
  my ($start,$stop,$gene,$locus_tag) = @_;

  print "$start\t$stop\tgene\n";
#  print "\t\t\tgene\t$gene\n" if ($gene && $gene !~ /HTCC1062/);
  print "\t\t\tgene\t$gene\n" if ($gene && $gene !~ /$prefix/);
  print "\t\t\tlocus_tag\t$locus_tag\n";
}

sub product {
  my $product = shift;
  my $note;

  if ($product) {
    $product =~ s/\n//g;

    if ($product =~ /(.+?)\,\s(.+)\b/) {
      $product = $1;
      $note = $2;
    }
    $product =~ s/\(EC.+?\)//g;
#    $product =~ s/(\s\[imported\])*\s+\-\s+[A-Z][a-z0-9]+\s[a-z0-9]+(\s+\([\w\s\d\-]+\))*//;
    $product =~ s/(\s\[imported\])*\s+\-\s+[A-Z][a-z0-9]+\s[a-z0-9.]+(\s+\([\w\s\d\-]+\))*.+//;


    print "\t\t\tproduct\t$product\n";
    note($note) if ($note);
  }
}

sub transl_table {
  print "\t\t\ttransl_table\t$transl_table\n";
}

sub protein_id {
  my $id = shift;

  print "\t\t\tprotein_id\tgnl|ncbi|$id\n";
}

sub ec_number {
  my $ec = shift;

  print "\t\t\tEC_number\t$ec\n" if ($ec);
}

sub note {
  my $note = shift;

  print "\t\t\tnote\t$note\n";
}
