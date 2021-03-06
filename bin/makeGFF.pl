#!/usr/bin/env perl
# $Id: makeGFF.pl,v 3.6 2008/08/15 16:09:35 givans Exp $

use warnings;
use strict;
use Carp;
use Getopt::Std;
#use COGDB;
use Bio::SeqFeature::Generic;
use Bio::Tools::GFF;
use vars qw/ $opt_p $opt_v $opt_d $opt_D $opt_h /;

use lib '/home/sgivan/projects/COGDB/lib';
use lib '/home/sgivan/projects/BGA/share/genDB/share/perl';
use COGDB;
use Projects;

my ($project,$verbose,$debug,$desc);
getopts('p:vdDh');
$project = $opt_p;
$verbose = $opt_v;
$debug = $opt_d;
$desc = $opt_D;

my $usage = "usage: makeGFF.pl -p <project name>";
if ($opt_h) {
  _help($usage);
  exit(0);
}

if (!$project) {
  print "$usage (use -h to see help menu)\n";
  exit(0);
}

if ($opt_h) {
  _help($usage);
  exit(0);
}
print "initializing GenDB project\n" if ($debug);
Projects::init_project($project);
print "finished initializing GenDB project\n" if ($debug);
require GENDB::contig;
print "finished initializing GENDB::contig\n" if ($debug);
require GENDB::orf;
print "finished initializing GENDB::orf\n" if ($debug);
require GENDB::annotation;
print "finished initializing GENDB::annotation\n" if ($debug);
require GENDB::funcat;
print "finished initializing GenDB project\n" if ($debug);

my $GFFfile = "$project.gff";
my $DESCfile = "$project" . "_D.gff";
print "initializing COGDB object\n"  if ($debug);
my $cogdb = COGDB->new();
print "\$cogdb is a '", ref($cogdb), "'\n" if ($debug);
print "finished initializing COGDB object; fetching localcogs\n" if ($debug);
my $localcogs = $cogdb->localcogs();
print "\$localcogs is a '", ref($localcogs), "'\n" if ($debug);
print "fetching organism data\n" if ($debug);
my $organism = $localcogs->organism({ Code => $project });
print "\$organism is a '", ref($organism), "'\n" if ($debug);
print "fetching whogs\n" if ($debug);
my $whog = $localcogs->whog();
print "\$whog is a '", ref($whog), "'\n" if ($debug);
print "fetching whogs for organism\n" if ($debug);
my $whogs = $whog->fetch_by_organism($organism);
#my $whogs;
print "organism is ", $organism->name(), "\n";
#exit();
my %funcat = ();

foreach my $whog (@$whogs) {
  my $cog = $whog->cog();
  my $categories = $cog->categories();
  foreach my $category (@$categories) {
    $funcat{$whog->name()} = $category->name() . " [" . $category->id() . "]" unless ($funcat{$whog->name()} || $category->id() == 24);
  }
}
  
#foreach my $orfname (keys %funcat) {
#  print "$orfname\t$funcat{$orfname}\n";
#}

#exit(0);

open(GFF, ">$GFFfile") or die "can't open '$GFFfile': $!";
open(DESC, ">$DESCfile") or die "can't open '$DESCfile': $!" if ($desc);
#open(TEMP, ">newGFF.gff") or die "can't open 'temp.gff': $!";

#  my $gff_version = 2;
#  my $GFFout = Bio::Tools::GFF->new(
#  				-file		=>	">testGFF.gff" . $gff_version,
#  				-gff_version	=>	$gff_version,
#  				);



foreach my $contig (@{GENDB::contig->fetchall()}) {
  my $contigID = $contig->id();
  my $contigName = $contig->name();
  print "contig $contigID:  '$contigName'\nlength: '", $contig->length(), "'\n" if ($debug);
  
  my $contigfeature = Bio::SeqFeature::Generic->new(
  						-start	=>	1,
						-end	=>	$contig->length(),
						-strand	=> '',
						-source_tag	=>	'GENDB',
						-primary	=>	'chromosome',
#						-display_name	=>	'display_name',
						-seq_id	=>	"C" . $contigID,
#						-display_id	=>	'display_id',
						-tag    => {
								Chromosome => "C" . $contigID,
							}
						);
						
#  $GFFout->write_feature($contigfeature);
#  print TEMP $contigfeature->gff_string(), "\n";

  print GFF "C$contigID\tGENDB\tchromosome\t1\t", $contig->length(), "\t.\t.\t.\tChromosome C$contigID\n";

  my $cnt = 0;
  my $orfs = $contig->fetchorfs();

  foreach my $orf (values %$orfs) {
    my $orfName = $orf->name();
    my $orfStatus = $orf->status();
    next if ($orfStatus && $orfStatus == 2);
    ++$cnt;
#    last if ($cnt == 10);
    next unless ($orfName);
    print "orf name: '$orfName'\n" if ($debug);

    if ($orfName) {# !~ /deprecated/ && $orfName =~ /^C$contigID[_]/) {
      my ($Note,$description,$Funcat) = ("","");

      my $orfType = 'orf';
      if ($orfName =~ /([\w_]*tRNA[\w_]*)(.+)/) {
        print "\t\tthis is a tRNA\n" if ($debug);
        $orfType = 'trna';
        $orfName = $1;
      } elsif ($orfName =~ /\d{1,2}S.*?rRNA/) {
        print "\t\tthis is a rRNA\n" if ($debug);
        $orfType = 'rRNA';
      }

      my $annot = GENDB::annotation->latest_annotation_init_orf_id($orf->id());
      my ($commonName,$category,$ec);
      if ($annot) {

    #	my ($commonName,$category,$ec) = ();
        $commonName = value($annot->name());
        $description = value($annot->product());
        $ec = value($annot->ec());

        $Funcat = $funcat{$orfName} || 'Function unknown [25]';

        if ($commonName) {
            $commonName =~ s/\"/_/g;
            $commonName =~ s/\n/ /g;# Swissprot has \n in TagTree structure
            $commonName =~ s/TagTree.+?Name.+?(\w+)$/$1/g;# another Swissprot workaround
        }
        if ($description) {
          $description =~ s/[\"\n\t\r]{1,}/_/g;
        }

        $Note = "; Note \"$commonName\"" if ($commonName ne '.');
        $Note = "$Note; Funcat \"$Funcat\"; Description \"$description\"" if ($Funcat =~ /\w/);
        $Note = "$Note; EC \"$ec\"" if ($ec ne '.');
        $description = "GeneFCN \"$description\"" if ($desc && $description ne '.');
      }
	       my $gffORF = eval { $orfType eq 'orf' ? ucfirst($orfType) : lcfirst(uc($orfType)) };
	       #$gffORF = "00aa" . $gffORF; ## this is a total hack.
	       ## If I don't append these characters, the GFF tags aren't sorted so that gbrowse
	       ## works properly.  Maybe in newer versions of gbrowse this won't be necessary.
	       ## I remove characters later.

	       my $orf_feature = Bio::SeqFeature::Generic->new(
						      -source_tag	=>	'GENDB',
						      -seq_id		=>	"C" . $contigID,
						      -primary		=>	'orf',
						      -start		=>	value($orf->start()),
						      -end		=>	value($orf->stop()),
						      -strand		=>	strand($orf),
						      -frame		=>	frame($orf),
						      -display_name    	=>	$gffORF,
 						      -tag		=>	{
										 group		=>	"$gffORF $orfName",
 										 $gffORF	=>	$orfName,
 										 ID		=>	$orfName,
 										 Note		=>	$commonName ne '.' ? $commonName : value($annot->name()),
 										 Name		=>	$commonName || $annot->name(),
 										 EC		=>	value($ec), #$ec if ($ec ne '.'),
 										 Funcat		=>	value($Funcat),
 										 Description	=>	value($description),
 										}
						     );


#       my $gff_string = $orf_feature->gff_string();
#       my @stringvals = split /\t/, $gff_string;
#       my $last_elem = $#stringvals;
#       my $tagstring = $stringvals[$last_elem];
#       $tagstring = "$gffORF $orfName ; " . $tagstring;
#       $stringvals[$last_elem] = $tagstring;
#       print TEMP join "\t", @stringvals, "\n";

#      $GFFout->write_feature($orf_feature);

			print GFF "C$contigID\tGENDB\t", $orfType, "\t", value($orf->start()), "\t", value($orf->stop()), "\t1\t", strand($orf), "\t", frame($orf), "\t", eval { $orfType eq 'orf' ? ucfirst($orfType) : lcfirst(uc($orfType)) }, " $orfName", eval { $Note ? $Note : '' }, "\n";



      print DESC "C$contigID\tGENDB\tgenefcn\t", value($orf->start()), "\t", value($orf->stop()), "\t1\t", strand($orf), "\t", frame($orf), "\tgenefcn \"$Funcat\"\n" if ($desc);

    }
  }

}
close(GFF);
close(DESC) if ($desc);


sub strand {
  my $orf = shift;
  my $frame = $orf->frame();
  if ($frame) {
    if ($frame =~ /([-])[123]/) {
      return $1;
    }
    return '+';
  }
}

sub frame {
  my $orf = shift;
  my $frame = $orf->frame();
  if ($frame) {
    if ($frame =~ /[-]*([123])/) {
#      return --$1;
	$frame = $1;
    }
    return --$frame || '0';
  }
}

sub value {
  my $value = shift;
  if ($value) {
    return $value;
  } else {
    return '.';
  }
}

sub _help {
  my $usage = shift;

  print <<HELP;


This script generates a file in GFF format from a GenDB database.

Usage:  $usage

Command-line options

-h\tPrint this help menu
-p\tGenDB project name (Required)
-D\tGenerate GFF file of ORF functional classifications
-v\tVerbose output to terminal
-d\tDebugging mode

Output file will be named after GenDB project name
<GenDB project name>.gff
ie, E_coli.gff

HELP
}
