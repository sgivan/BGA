#!/usr/bin/env perl

use v5.10.0;
use warnings;
use strict;
use Carp;
use vars qw/ $opt_p $opt_o $opt_c $opt_i $opt_d $opt_v $opt_h $opt_I $opt_D $opt_A $opt_u $opt_f $opt_s $opt_e $opt_n $opt_H /;
use Getopt::Std;
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('p:o:c:i:dvhID:Auf:s:e:n:H:');

my $debug = $opt_d;
my $verbose = $opt_v;
$verbose = 1 if ($debug);
my $usage = "usage:  genDB_orfCreate.pl -p <project> -f <file name>\n\t\tor\n\tcat file | genDB_orfCreate.pl -F -p <project>\n";

my $helpmssg = <<HELP;

This script is meant to be a lightweight tool to quickly add
ORFs to a GenDB annotation project from a tsv input file.

$usage

Command-line options

Option  Description
-p  GenDB project name
-i  Input file name.  Should have one entry per line and each
        each entry should be
        Orf name<tab>ORF frame<tab>start position<tab>stop position
        separated by tabs
-I  Takes all input from STDIN.  Should be same format as input file
-H      skip this number of lines of input file; ie, for a header [default = 1]
-n      column with name of ORF [default = 1]
-f      column with frame of ORF [default = 2]
-s      column with start coordinate of ORF [default = 3]
-e      column with end coordinate of ORF [default = 4]
-d  debugging mode
-v  verbose output to terminal
-h  print this help menu
-A  Don't update GenDB annotations

HELP

if ($opt_h) {
  print "$helpmssg";
  exit(0);
}

my $project = $opt_p;
my $infile = $opt_i;
my $headerlines = $opt_H || 1;
my @lines;
#
# *_pos variables contain array indices, which start with zero
# these must be converted from column number, which start with 1
#
my $name_pos = $opt_n ? $opt_n - 1 : 0;
my $frame_pos = $opt_f ? $opt_f - 1 : 1;
my $start_pos = $opt_s ? $opt_s - 1 : 2;
my $stop_pos = $opt_e ? $opt_e - 1 : 3;

if ($debug) {
    say " \
        name index\t$name_pos \
        frame index\t$frame_pos \
        start index\t$start_pos \
        end index\t$stop_pos \
        header lines\t$headerlines\
        ";
}

if (!$project && (!$opt_i && !$opt_I)) {
  print $usage;
  exit;
}

if (($infile || $opt_I)) {
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
#  my ($start,$stop) = split /:/, $coord;
#  push(@lines,"$orf\t$start\t$stop\n");
}

#
# Initialize GenDB stuff
#

Projects::init_project($project);
require GENDB::orf;
require GENDB::contig;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::Common;
#require Job;

#
#
my $cnt = 0;
foreach my $line (@lines) {
    next if (++$cnt <= $headerlines);
    chomp($line);
    print "\n\nline: '$line'\n" if ($debug);
    my @vals = split /\t/, $line;
    #my ($iorf,$istart,$istop,$description) = ('',$vals[$start_pos], $vals[$stop_pos],'');
    my ($iorf,$istart,$istop,$frame,$description) = ($vals[$name_pos], $vals[$start_pos], $vals[$stop_pos], $vals[$frame_pos]);
    $iorf =~ s/\s//g;
    $istart =~ s/\s//g if ($istart);
    $istop =~ s/\s//g if ($istop);

    if ($istop < $istart) {
        die "start coordinate must always be less than stop coordinate"
    }

    my ($gmol,$gstart,$gstop) = ();
    if ($iorf =~ /(C\d+?)\.(\d+?)\.(\d+)$/) {
        $gmol = $1;
        $gstart = $2;
        $gstop = $3;
    } else {
        die("can't parse region name from '$iorf'");
    }

    my ($molstart,$molstop) = ();
    $molstart = $istart + $gstart - 1;
    $molstop = $istop + $gstop - 1;
    
    next unless ($iorf);
    my $annotate = 0;
    if (!$description) {
        $description = "ORF fragment created by genDB_orfCreate.pl -- it likely requires additional annotation.\n";
    }

    if ($debug) {
        say "name:\t'$iorf'\nstart:\t'$istart'\nstop:\t'$istop'\n";
        say "gmol:\t'$gmol'\ngstart:\t'$gstart'\ngstop:\t'$gstop'\n";
        say "molstart:\t'$molstart'\nmolstop:\t'$molstop'\n";
    }

    unless ($debug) {
        # change next line b/c this ORF doesn't yet exist
        my $contig = GENDB::contig->init_name($gmol);
        my $gorf = GENDB::orf->create($contig->id(),$molstart,$molstop,$iorf . "_i");
        exit();
        my $annotator = GENDB::annotator->init_name('orfCreate');

#        if (!$istart && !$istop) {
#            print $gorf->name(), "\t", $gorf->start(), "\t", $gorf->stop(), "\n";
#        }


#
# Use correct start and stop for +/- strand ORFs
#
#    my ($gframe,$gstart,$gstop) = $gorf->frame();
#    if ($gorf->frame() < 0) {
#        print "neg strand ORF\n" if ($debug);
#        $istart = $gorf->stop unless($istart);
#        $istop = $gorf->start unless ($istop);
#        $gstart = $gorf->stop();
#        $gstop = $gorf->start();
#
#        if ($istart !~ /[+-]/ && $istop !~ /[+-]/) {
#        if ($istart < $istop) {
#        my $temp = $istart;
#        $istart = $istop;
#        $istop = $temp;
#        }
#        }
#
#    } else {
#        print "pos strand ORF\n" if ($debug);
#        $istart = $gorf->start unless ($istart);
#        $istop = $gorf->stop unless ($istop);
#        $gstart = $gorf->start();
#        $gstop = $gorf->stop();
#
#        if ($istart !~ /[+-]/ && $istop !~ /[+-]/) {
#        if ($istart > $istop) {
#        my $temp = $istart;
#        $istart = $istop;
#        $istop = $temp;
#        }
#        }
#
#    }
#    print "second: istart = $istart; istop = $istop\n" if ($debug);
#    if ($istart !~ /^[+-]/) {
#
#    } else {
#        if ($istart =~ /^[+-]/) {
#        if ($istart =~ /^-/) { # move start upstream
#        print "move start upstream\n" if ($debug);
#        $istart =~ s/-//;
#        if ($gorf->frame() > 0) {
#        $istart = $gstart - $istart;
#        } else {
#        $istart = $gstart + $istart;
#        }
#        } else {		    # move start downstream
#        print "move start downstream\n" if ($debug);
#        $istart =~ s/\+//;
#        if ($gorf->frame() > 0) {
#        $istart += $gstart;
#        } else {
#        $istart = $gstart - $istart;
#        }
#        }
#        }
#    }
#
#    if ($istop !~ /^[+-]/) {
#
#    } else {
#        if ($istop =~ /^[+-]/) {
#        if ($istop =~ /^\-/) { # move stop upstream
#        print "move stop upstream\n" if ($debug);
#        $istop =~ s/-//;
#        if ($gorf->frame() > 0) {
#        $istop = $gstop - $istop;
#        } else {
#        $istop = $gstop + $istop;
#        }
#        } else {		   # move stop downstream
#        print "move stop downstream\n" if ($debug);
#        $istop =~ s/\+//;
#        if ($gorf->frame() > 0) {
#        $istop = $gstop + $istop;
#        } else {
#        $istop = $gstop - $istop;
#        }
#        }
#        }
#    }
#    print "\$istart = $istart; \$istop = $istop\n" if ($debug);
#    print "\$gstart = $gstart; \$gstop = $gstop\n" if ($debug);
#    
#    
#    if ($istart && $gstart != $istart) {
#        $description .= "changing start position from $gstart to $istart\n";
#        print $gorf->name(), ":  changing start position from $gstart to $istart\n" if ($verbose);
#        if ($gframe > 0) {
#        setstartposition($gorf,$istart);
#        } else {
#        setstartposition($gorf,$istart);
#        }
#        $annotate = 1;
#    }
#    if ($istop && $gstop != $istop) {
#        $description .= "changing stop position from $gstop to $istop\n";
#        print $gorf->name(), ":  changing stop position from $gstop to $istop\n" if ($verbose);
#        if ($gframe > 0) {
#            $gorf->stop($istop) unless ($debug);
#        } else {
#        $gorf->start($istop) unless ($debug);
#        }
#        $annotate = 1;
#    }

        $annotate = 1;
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
}

 sub setstartposition {## adapted from a GenDB module
    my ($orf, $newposition) = @_;
    print "setstartposition: \$orf->start = " . $orf->start() . ", \$orf->stop = " . $orf->stop(), "\n" if ($debug);
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
