#!/usr/bin/env perl
# $Id: genDB_orfCoord.pl,v 3.9 2005/03/25 01:16:44 givans Exp $
use warnings;
use strict;
use Carp;
use vars qw/ $opt_p $opt_o $opt_c $opt_f $opt_d $opt_v $opt_h $opt_F $opt_D $opt_A $opt_u /;
use Getopt::Std;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('p:o:c:f:dvhFD:Au');

my $debug = $opt_d;
my $verbose = $opt_v;
$verbose = 1 if ($debug);
my $usage = "usage:  genDB_orfCoord.pl -p <project> -o <orf> -c <orf coordinates like 'start:end'>\n\t\tor\n\tgenDB_orfCoord.pl -p <project> -f <file name>\n\t\tor\n\tcat file | genDB_orfCoord.pl -F -p <project>\n";

my $helpmssg = <<HELP;

This script is meant to be a lightweight tool to quickly change the
start and stop coordinates of ORFs in a GenDB annotation project.

$usage

Command-line options

Option		Description
-p		GenDB project name
-o		Name of orf you want to change
-c		Coordinates of orf
			Coordinates can be either relative (ie, '+3:-6'),
			or absolute (ie, '23498:35875').
			Either way, enclose in quotes.
-f		Input file name.  Should have one entry per line and each
			each entry should be
			Orf name start position stop position
			separated by tabs
-F		Takes all input from STDIN.  Should be same format as input file
-u		undo change of start/stop coordinates specified
		only works if change is specified with relative syntax
-d		debugging mode
-v		verbose output to terminal
-h		print this help menu
-D		Description to include if updating GenDB annotation; enclose in quotes
-A		Don't update GenDB annotations

A note about ORF coordinates:
If you are using absolute coordinates, the order of the coordinates
  in the '23498:35875' specification doesn't matter.
If you are using the relative syntax (ie, '+3:-6'), the first value 
  is for the start location and the second value is for the stop location,
  irrespective of reading frame or coding strand.


HELP

if ($opt_h) {
  print "$helpmssg";
  exit(0);
}

my $project = $opt_p;
my $orf = $opt_o;
my $coord = $opt_c;
my $infile = $opt_f;
my $descr = $opt_D;
my $undo = $opt_u;
my @lines;

if (!$project || (!$orf || !$coord) && (!$opt_f && !$opt_F)) {
  print $usage;
  exit;
}

if (($infile || $opt_F) && (!$orf && !$coord)) {
  if ($infile && !-e $infile) {
    print "'$infile' doesn't exist\n";
    exit(0);
  }
  if ($infile) {
    open(IN,$infile) or die "can't open '$infile': $!";
    @lines = <IN>;
    close(IN);
  } else {
    foreach (<STDIN>) {
      chomp($_);
      push(@lines,$_) if ($_ =~ /\W/);
    }
  }
} else {
  my ($start,$stop) = split /:/, $coord;
  push(@lines,"$orf\t$start\t$stop\n");
}

#
# Initialize GenDB stuff
#

Projects::init_project($project);
require GENDB::orf;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::Common;
#require Job;

#
#

foreach my $line (@lines) {
  chomp($line);
  print "\n\nline: '$line'\n" if ($debug);
  my ($iorf,$istart,$istop,$description) = split /\t/, $line;
  $iorf =~ s/\s//g;
  $istart =~ s/\s//g if ($istart);
  $istop =~ s/\s//g if ($istop);
  
  if ($undo) {
    $istart =~ tr/\-\+/\+\-/ if ($istart);
    $istop =~ tr/\-\+/\+\-/ if ($istop);    
  }
  
  next unless ($iorf);
  my $annotate = 0;
  if (!$description) {
    $description = "orf coordinates changed by genDB_orfCoord.pl\n";
  }

  my $gorf = GENDB::orf->init_name($iorf);
  my $annotator = GENDB::annotator->init_name('orfCoord');

  if (!$istart && !$istop) {
    print $gorf->name(), "\t", $gorf->start(), "\t", $gorf->stop(), "\n";
  }


#
# Use correct start and stop for +/- strand ORFs
#
  my ($gframe,$gstart,$gstop) = $gorf->frame();
  if ($gorf->frame() < 0) {
    print "neg strand ORF\n" if ($debug);
    $istart = $gorf->stop unless($istart);
    $istop = $gorf->start unless ($istop);
    $gstart = $gorf->stop();
    $gstop = $gorf->start();

    if ($istart !~ /[+-]/ && $istop !~ /[+-]/) {
      if ($istart < $istop) {
	my $temp = $istart;
	$istart = $istop;
	$istop = $temp;
      }
    }

  } else {
    print "pos strand ORF\n" if ($debug);
    $istart = $gorf->start unless ($istart);
    $istop = $gorf->stop unless ($istop);
    $gstart = $gorf->start();
    $gstop = $gorf->stop();

    if ($istart !~ /[+-]/ && $istop !~ /[+-]/) {
      if ($istart > $istop) {
	my $temp = $istart;
	$istart = $istop;
	$istop = $temp;
      }
    }

  }
  print "second: istart = $istart; istop = $istop\n" if ($debug);
#  exit(0);
   if ($istart !~ /^[+-]/) {

   } else {
    if ($istart =~ /^[+-]/) {
      if ($istart =~ /^-/) { # move start upstream
	print "move start upstream\n" if ($debug);
	$istart =~ s/-//;
	if ($gorf->frame() > 0) {
	  $istart = $gstart - $istart;
	} else {
	  $istart = $gstart + $istart;
	}
      } else {		    # move start downstream
	print "move start downstream\n" if ($debug);
	$istart =~ s/\+//;
	if ($gorf->frame() > 0) {
	  $istart += $gstart;
	} else {
	  $istart = $gstart - $istart;
	}
      }
    }
  }

  if ($istop !~ /^[+-]/) {

  } else {
    if ($istop =~ /^[+-]/) {
      if ($istop =~ /^\-/) { # move stop upstream
	print "move stop upstream\n" if ($debug);
	$istop =~ s/-//;
	if ($gorf->frame() > 0) {
	  $istop = $gstop - $istop;
	} else {
	  $istop = $gstop + $istop;
	}
      } else {		   # move stop downstream
	print "move stop downstream\n" if ($debug);
	$istop =~ s/\+//;
	if ($gorf->frame() > 0) {
	  $istop = $gstop + $istop;
	} else {
	  $istop = $gstop - $istop;
	}
      }
    }
  }
  print "\$istart = $istart; \$istop = $istop\n" if ($debug);
  print "\$gstart = $gstart; \$gstop = $gstop\n" if ($debug);
  
#  exit(0);
  
  if ($istart && $gstart != $istart) {
    $description .= "changing start position from $gstart to $istart\n";
    print $gorf->name(), ":  changing start position from $gstart to $istart\n" if ($verbose);
    if ($gframe > 0) {
      setstartposition($gorf,$istart);
    } else {
      setstartposition($gorf,$istart);
    }
    $annotate = 1;
  }
  if ($istop && $gstop != $istop) {
    $description .= "changing stop position from $gstop to $istop\n";
    print $gorf->name(), ":  changing stop position from $gstop to $istop\n" if ($verbose);
    if ($gframe > 0) {
    	$gorf->stop($istop) unless ($debug);
    } else {
      $gorf->start($istop) unless ($debug);
    }
    $annotate = 1;
  }

  if ($annotate) {
    if (!$opt_A) {
      print "adding annotation\n" if ($debug);
      if (!$debug) {
	my $annotation = GENDB::annotation->create("", $gorf->id());
	$annotation->annotator_id($annotator->id());
	$annotation->date(time());
	$annotation->comment($description);
      }
    }
    print "updating iep\n" if ($debug);
    $gorf->isoelp(GENDB::Common::calc_pI($gorf->aasequence())) unless ($debug);
    print "updating MW\n" if ($debug);
    GENDB::orf::molweight($gorf, GENDB::Common::molweight($gorf->aasequence)) unless ($debug);

    $gorf->status('1') unless ($debug);
    print $description if ($debug);
  }
}

 sub setstartposition {## adapted from a GenDB module
   my ($orf, $newposition) = @_;
   print "setstartposition: newposition = $newposition, \$orf->start = " . $orf->start() . ", \$orf->stop = " . $orf->stop(), "\n" if ($debug);
   if ($orf->frame() > 0) {
     if (($newposition < $orf->stop()) && (($orf->stop() - $newposition) % 3 == 2)) {
       if (!$debug) {
	 $orf->start($newposition);
	 $orf->startcodon(substr ($orf->sequence(), 0, 3));
       }
     } else {
       print "new start position failed test\n";
       exit(0);
     }
    } elsif (($newposition > $orf->start()) && (($newposition - $orf->start()) % 3 == 2)) {
      if (!$debug) {
	$orf->stop($newposition);
	$orf->startcodon(substr ($orf->sequence(), 0, 3));
      }
    } else {
      print "new start position failed neg strand test\n";
      exit(0);
    }
 }
