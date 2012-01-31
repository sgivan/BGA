#!/usr/bin/perl
# $Id: genDB_contigRBSadjust.pl,v 3.3 2005/11/17 00:38:55 givans Exp $
use warnings;
use Carp;
use strict;
use Getopt::Std;
#use Cwd;
use vars qw/ $opt_d $opt_h $opt_g $opt_r $opt_o $opt_M $opt_p $opt_R /;

getopts('dhgrR:oM:p:');

my ($debug,$help,$glimmer,$rbsfinder,$RBS,$orfadjust,$model_file,$project_name) = ($opt_d,$opt_h,$opt_g,$opt_r,$opt_R,$opt_o,$opt_M,$opt_p);
my ($contig_file);

if (!$model_file && $glimmer) {
  print "must use -M to designate a model file for glimmer2\n";
  exit(0);
}

if ($orfadjust && !$project_name) {
  print "you must provide a GenDB project name (-p) if you are going to use genDB_orfAdjust\n";
  exit(0);
}

opendir(THIS,'.');
my @dirs = readdir(THIS);
closedir(THIS);

foreach my $dir (sort @dirs) {
  next if ($dir eq '.' || $dir eq '..');
  if (-d $dir) {
    print "'$dir' is a directory\n";

    foreach my $file (@dirs) {
      if ($file =~ /.+_$dir$/) {
	$contig_file = $file;
      }
    }

    if ($contig_file) {
      print "\twill use file '$contig_file'\n";
    } else {
      die "can't identify a contig file\n";
    }

    if (chdir($dir)) {
      print "\tchanged working directory to '$dir'\n";
      if ($glimmer) {
	my $glimmer_cmd = "glimmer2 ../$contig_file $model_file -g 100 -l -X | get-putative > contig.coord";
	print "\trunning glimmer:\n\t\t$glimmer_cmd\nglimmer output:\n";
	open(GLIMMER, "$glimmer_cmd |") or die "can't open glimmer2: $!";

	if (!close(GLIMMER)) {
	  print STDERR "can't close glimmer2 properly\n";
	  exit(1);
	}

	if ($rbsfinder) {
	  my $rbsfinder_cmd = "rbs_finder.pl ../$contig_file contig.coord contig.rbs.coord 30";
	  $rbsfinder_cmd = "$rbsfinder_cmd $RBS" if ($RBS);
	  print "\trunning rbs_finder.pl:\n\t\t$rbsfinder_cmd\n";
#	  system($rbsfinder_cmd);
	  open(RBSFIND,"$rbsfinder_cmd |") or die "can't open rbs_finder: $!";
	  my @rbsfinder = <RBSFIND>;

	  if (!close(RBSFIND)) {
	    warn "can't close rbs_finder.pl properly\n";
	    if ($orfadjust) {
	      chdir('..');
	      die "can't proceed without rbs_finder.pl output\nperhaps delete '$dir' directory?\n";
	    }
	  } else {
	    print "rbs_finder.pl output:\n@rbsfinder\n" if (scalar(@rbsfinder));
	  
	    if ($orfadjust) {
	      my $contig_number;

	      my $id_line = `grep '>' ../$contig_file`;
	      chomp($id_line);
	      print "id_line = '$id_line'\n";
	      if ($id_line =~ /\>(.+)/) {
		$contig_number = $1;
	      } else {
		die "can't determine contig number\n";
	      }

	      my $orfadjust_cmd = "genDB_orfAdjust.pl -f contig.rbs.coord -p $project_name -c '$contig_number' -v -A -a";
	      print "running genDB_orfAdjust.pl:\n\t$orfadjust_cmd\n";
 	      open(ORFADJ,"$orfadjust_cmd |") or die "can't open genDB_orfAjust.pl\n";
 	      my @orfadj = <ORFADJ>;

 	      if (!close(ORFADJ)) {
 		die "can't close genDB_orfAdjust.pl properly: $!";
 	      } else {
 		print "genDB_orfAdjust.pl output:\n";
 		print "@orfadj\n" if (scalar(@orfadj));
 	      }

	    }
	  }
	}

      }


      chdir('..');
    } else {
      print "\tcannot change working directory to '$dir'\n";
    }


  }
  exit(0) if ($debug);
}
