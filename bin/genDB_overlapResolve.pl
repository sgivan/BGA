#!/usr/bin/perl
# $Id: genDB_overlapResolve.pl,v 3.17 2006/10/03 23:59:01 givans Exp $
use warnings;
use strict;
use Carp;
use Getopt::Std;
use vars qw/ $opt_v $opt_d $opt_h $opt_p $opt_c $opt_r $opt_z $opt_Z $opt_A $opt_i /;
use lib '/local/cluster/genDB/share/perl';
use Projects;

$SIG{QUIT} = $SIG{INT} = $SIG{TERM} = $SIG{KILL} = $SIG{ABRT} = $SIG{STOP} = \&death;
$SIG{HUP} = \&death;

getopts('izZAvdhp:c:r:');

my($verbose,$debug,$help,$usage,$project,$contig,$range,%orfIgnore,%flag);

#
# $orfStatus will be a global hash containing GENDB::orf objects;
my %orfStatus;
#
#

my($minOverlap);
$debug = $opt_d;
$verbose = $opt_v;
$verbose = 1 if ($debug);
$usage = "usage:  genDB_overlapResolve.pl -p <project name> [<options>]";
$minOverlap = 30;

%flag = (
	 '0'	=>	'putative',
	 1	=>	'annotated',
	 2	=>	'ignored',
	 3	=>	'finished',
	 4	=>	'attention needed',
	 5	=>	'user state 1',
	 6	=>	'user state 2',
	 99	=>	'ambiguous',
	 );

#
###############################
# Parse command-line flags
#

if ($opt_h) {
  $help = 1;
  _debug("printing help menu") if ($debug);
  _help($usage);
  exit(0);
}

if ($opt_p) {
  $project = $opt_p;
} else {
  _debug("no project name was provided; print usage statement") if ($debug);
  print "$usage\n";
  exit(0);
}

print "GenDB project: '$project'\n" if ($verbose);

#
###############################
# Initialize GenDB project
#

Projects::init_project($project);
require GENDB::contig;
require GENDB::orf;
require GENDB::fact;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::tool;
#
# End of GenDB initialization
###############################
#

my $contig_name = $opt_c;
if (!$contig_name) {
  my $contig_names = GENDB::contig::contig_names();
  print "Select contig by name:\n\n";
  foreach my $temp_contig_name (keys %$contig_names) {
    print "\t$temp_contig_name\n";
  }
  print "q: quit this program\n\n";
  print "Select a contig:  ";
  $contig_name = <STDIN>;
  chomp($contig_name);
}
if ($contig_name eq 'q') {
  _debug("user quit") if ($debug);
  exit(0);
} else {
  $contig = GENDB::contig->init_name($contig_name);

  if ($contig < 0) {
    _debug("contig '$contig_name' cannot be initialized") if ($debug);
    exit(0);
  } else {
    print "contig '", $contig->name(), "' initialized\n" if ($verbose);
  }
}

#my $Qtools = good_tools();

my($start,$stop);
if ($opt_r) {
  $range = $opt_r;
  ($start,$stop) = split  /:/, $range;

  if (!$start || !$stop) {
    _debug("invalid range coordinates") if ($debug);
    exit(0);
  }
}

print "start = $start, stop = $stop\n" if ($verbose && ($start && $stop));

#
#
# End of commnand-line flag parsing
####################################
#

#
#####################################
# Fetch ORFs and resolve overlaps
#
#

registerOrfs($contig);

my @orfs = get_orfNames($contig,$start,$stop); # fetch GENDB::orf objects, optionally betw start and stop coords
#print "number of ORFs: ", scalar(@orfs), "\n";

my ($cnt,$cnt2,$cnt3,$cnt4,$cnt5,$cnt6) = (0,0,0,0,0,0);
foreach my $orfName (sort { getOrf($a)->start() <=> getOrf($b)->start() } @orfs) {
  ++$cnt;
  classify($orfName);
}

#
# print summary of orf states
#
#
if ($verbose) {
  print "\n\n\tSummary:\n\n";
  foreach my $orf (sort { $a->name() cmp $b->name() } values %orfStatus) {
    my $orf_name = $orf->name();

    if (getStatus($orf)) {
      print "$orf_name: $flag{getStatus($orf)}\n";
    } else {
#      print "unknown";
    }
  }
}



#
#
# Update annotation in GenDB
####################################
#

if (!$opt_z) {
#  print "\tinitializing GenDB annotator object\n" if ($debug);
  my $annotator = GENDB::annotator->init_name('overlapResolve');
  my $id = $annotator->id();
#  print "\tannotator id = $id\n" if ($debug);

  print "\n\nupdating GenDB annotation\n" if ($verbose);

  foreach my $orf (sort { $a->name() cmp $b->name() } values %orfStatus) {
    my $orf_name = $orf->name();
    my $orf_id = $orf->id();
    my $loc_status = getStatus($orf);
    my $db_status = $orf->status();
    if ($loc_status) {
      if ($db_status && $db_status == $loc_status && !$opt_Z) {
	print "skipping GenDB $orf_name update: local status ('$flag{$db_status}') == GenDB status ('$flag{$loc_status}')\n" if ($debug);
	next;
      }
#      print "\tcreating GenDB annotation object: orf name = '$orf_name', orf id = '$orf_id'\n" if ($debug);
      print "ORF: $orf_name\n" if ($debug);
      print "<-- Description -->\ndescription: ", oa_description($orf), "\n<-- End of description -->\n" if ($debug && oa_description($orf));
#      print "setting status of $orf_name in GenDB to '", $flag{getStatus($orf)}, "'\n" if ($debug);

      if (!$opt_A) {
	my $annot = GENDB::annotation->create($orf_name,$orf_id);
	$annot->annotator_id($id);
	if (oa_description($orf)) {
	  $annot->comment(oa_description($orf));
	}
	$orf->status($loc_status);
	$annot->date(time);
      }
    }
  }


}

#
#
# End of GenDB update
####################################
#


#
#
# Subroutines
#
#


sub classify {
  my $orfName = shift;
  my $force = shift;
  my $orf = getOrf($orfName);
  my $status = getStatus($orf);
  if ($debug) {
    my $string = "\n\nclassifying $orfName";
    $string .= $force ? "with force option\n" : "\n";
    print "$string";
  }

  if (!$force) {
    if ($status && ($status == 1 || $status == 4 || $status == 2)) { ## skip if ORF has been assigned a status code
      print "\t\tskipping because status = $flag{$status}\n" if ($debug);
      return;
    }
  }

  my @hq = HQfacts($orf);
#  $orf->{_tRNA} = 0;

  print "orf: ", $orf->name(), "\t# facts: ", HQfactCount($orf), "\tstart: ", $orf->start(),"; stop: ", $orf->stop(), "\t\tlength: ", $orf->length(), "\n" if ($verbose);

  #
  # tRNA's are special
  #


  tRNA($orf);
  rRNA($orf);

  my @overlapOrfs = get_overlapNames($orf);
  if (scalar(@overlapOrfs)) {
    print "   overlapping ORFs [", scalar(@overlapOrfs), "]:\n" if ($verbose);
    oa_description($orf, "overlapping ORFs [" . scalar(@overlapOrfs) . "]:");
    print "\tthis is a tRNA\n" if ($verbose && tRNA($orf));
    print "\tthis is a rRNA\n" if ($verbose && rRNA($orf));
    ++$cnt3;

    foreach my $oOrfName (sort { getOrf($a)->start() <=> getOrf($b)->start() } @overlapOrfs) {
      my $oOrf = getOrf($oOrfName);
      print "\t$oOrfName\n" if ($debug);
      if (getStatus($orf) && getStatus($orf) == 2) {
	print "\t\tskipping $oOrfName since ", $orf->name(), " has been assigned status ", $flag{getStatus($orf)}, "\n";
	oa_description($orf,"skipping $oOrfName since " . $orf->name() . " has been assigned status " . $flag{getStatus($orf)});
	next;
      }
      ++$cnt4;
      if ($oOrf->status() && $oOrf->status() == 2 && !$opt_i) { ## skip if ORF has been annotated with a status = 2 (ignored)
	print "\tskipping $oOrfName since it's status is ", $flag{$oOrf->status()}, "\n";
	oa_description($orf,"skipping $oOrfName since it's status is " . $flag{$oOrf->status()});
#	setStatus($orf,1);
	next;
      }
      ++$cnt5;
      next if (tRNA($oOrf));
      next if (rRNA($oOrf));
      ++$cnt6;

      HQfacts($oOrf);

      if ($orf->name() ne $oOrf->name()) {
#	next if (getStatus($oOrf) && getStatus($oOrf) == 2);
	print "\t", $oOrf->name(), "[", $oOrf->start(), ":", $oOrf->stop(), ":", $oOrf->length(), "]\n" if ($verbose);
	oa_description($orf, $oOrf->name() . "[" . $oOrf->start() . ":" . $oOrf->stop() . ":" . $oOrf->length() . "]");

	my $overlap = determineOverlap($orf,$oOrf);

	if ($overlap) {
	  print "\t\toverlap = $overlap\n" if ($verbose);
	  oa_description($orf,"overlap = $overlap");
	  if ( tRNA($oOrf) ) {
	    print "\t\toverlap includes a tRNA\n" if ($verbose);
	    oa_description($orf,"overlap includes a tRNA");
	  } elsif ( rRNA($oOrf) ) {
	    print "\t\toverlap includes a rRNA\n" if ($verbose);
	    oa_description($orf,"overlap includes a rRNA");
	  } elsif ($overlap <= $minOverlap) {
	    print "\t\toverlap is within acceptable limit\n" if ($verbose);
	    oa_description($orf,"overlap is within acceptable limit");
	    setStatus($orf,1);
	    next;
	  } elsif ($overlap == $oOrf->length()) {
	    print "\t\t", $orf->name(), " completely encompasses ", $oOrf->name(), "\n" if ($verbose);
	    oa_description($orf, $orf->name() . " completely encompasses " . $oOrf->name());
	  } else {

	  }
	} else {
	  print "\t\tno overlap of coding DNA\n";
	  oa_description($orf,"no overlap of coding DNA");
	  setStatus($orf,1);
	  next;
	}


	determineStatus($orf,$oOrf);

      }
    }
    print "\n" if ($verbose);
  } else {
    print "\t\tno overlaps\n" if ($verbose);
    oa_description($orf,"no overlaps");
    setStatus($orf,1);
    setOrf($orf);
  }


}


sub determineStatus {
  my ($orf,$oOrf) = @_;
  if (HQfactCount($orf) && HQfactCount($oOrf)) {
    print "\t\tboth ", $orf->name(), " and ", $oOrf->name(), " have HQ facts\n" if ($verbose);
    oa_description($orf,"both " . $orf->name() . " and " . $oOrf->name() . " have HQ facts");
    attention($orf,$oOrf);
  } elsif (! HQfactCount($orf) && ! HQfactCount($oOrf)) {
    if (tRNA($orf)) {
      print "\t\t", $oOrf->name(), " overlaps tRNA and has no HQ facts\n" if ($verbose);
      oa_description($orf, $oOrf->name() . " overlaps tRNA and has no HQ facts");
      ignore($oOrf,2);
    } elsif (rRNA($orf)) {
      print "\t\t", $oOrf->name(), " overlaps rRNA and has no HQ facts\n" if ($verbose);
      oa_description($orf, $oOrf->name() . " overlaps rRNA and has no HQ facts");
      ignore($oOrf,2);
    } else {
      print "\t\tneither ", $orf->name(), " nor ", $oOrf->name(), " have HQ facts\n" if ($verbose);
      oa_description($orf,"neither " . $orf->name() . " nor " . $oOrf->name() . " have HQ facts");

      if (getStatus($oOrf) && getStatus($oOrf) == 2) {
	print "\t\t", $oOrf->name(), " is $flag{getStatus($oOrf)}\n" if ($debug);
	oa_description($orf, $oOrf->name() . " is $flag{getStatus($oOrf)}");
	setStatus($orf,1);
      } else {
	attention($orf,$oOrf);
      }

    }
  } else {  # one of the 2 ORFs has facts while the other has no facts
    if (HQfactCount($orf)) {
      print "\t\t", $orf->name(), " has ", HQfactCount($orf), " HQ facts, but ", $oOrf->name(), " has no facts\n" if ($verbose);
      oa_description($orf, $orf->name() . " has " . HQfactCount($orf) . " HQ facts, but " . $oOrf->name() . " has no facts");
      ignore($oOrf);
      setStatus($orf,1);
    } else {
      if (tRNA($orf)) {
	print "\t\t", $oOrf->name(), " overlaps a tRNA, but has HQ facts\n" if ($verbose);
	oa_description($orf, $oOrf->name() . " overlaps a tRNA, but has HQ facts");
	attention($orf,$oOrf);
      } elsif (rRNA($orf)) {
	print "\t\t", $oOrf->name(), " overlaps a rRNA, but has HQ facts\n" if ($verbose);
	oa_description($orf, $oOrf->name() . " overlaps a rRNA, but has HQ facts");
	attention($orf,$oOrf);
      } else {
	print "\t\t", $oOrf->name(), " has ", HQfactCount($oOrf), " HQ facts, but ", $orf->name(), " has no facts\n" if ($verbose);
	oa_description($orf, $oOrf->name() . " has " . HQfactCount($oOrf) . " HQ facts, but " . $orf->name() . " has no facts");
	ignore($orf);
	setStatus($oOrf,1);
      }
    }
  }
}

sub registerOrfs {
  my $contig = shift;
  my $orfs = $contig->fetchorfs();
  print "registering ORFs from contig ", $contig->name(), "\n" if ($verbose);
  foreach my $orf (values %$orfs) {
    $orfStatus{$orf->name()} = $orf;
  }
}

sub get_orfNames { ## retrieves ORFs between given coordinates 
  my ($contig,$start,$stop) = @_;
  my @orfs = keys %{$contig->fetchorfs($start,$stop)};

  if ($start && $stop) {
    my $startOrf = $contig->fetchOrfsatPosition($start);
    my $stopOrf = $contig->fetchOrfsatPosition($stop);

    foreach my $endOrf ((@$startOrf, @$stopOrf)) {
#        print "endOrf: ", $endOrf->name(), "\n";
        push(@orfs,$endOrf->name());
    }
  }
  return @orfs;
}

sub get_overlapNames { ## retrieve a non-redundant list of genes that overlap a specific ORF
  my $orf = shift;

  my @orfs = get_orfNames($contig,$orf->start(),$orf->stop());
  my %uniqueOrfs;

  foreach my $temporfName (@orfs) {
#    if ($orf->name() eq 'C26_0059') {
#      print "overlapping name: '$temporfName'\n" if ($debug);
#    }
    next if ($temporfName eq $orf->name());
    $uniqueOrfs{$temporfName} = 1 unless ($uniqueOrfs{$temporfName});
  }
  return keys %uniqueOrfs;
}

sub good_tools { ## retrieve a list of tools that return E-values
  my %tools;

  foreach my $tool (@{GENDB::tool->fetchall()}) {
    my $helper = $tool->helper_package();
    if ($helper eq 'blast_helper' || $helper eq 'pfam_helper') {
      $tools{$tool->id()} = $tool;
    }
  }
  return \%tools;
}

sub determineOverlap { ## determine length of overlapping region
  my ($orf1,$orf2) = @_; ## $orf1 should always be 5' of $orf2 <-- not true

  # Since orf1 isn't always 5' of orf2 ... make it so
  if ($orf1->start() > $orf2->start()) {
    my $tempOrf = $orf1;
    $orf1 = $orf2;
    $orf2 = $tempOrf;
  }

#  return if (getStatus($orf2));
  my $overlap = 0;
  if (abs(($orf1->frame + $orf2->frame)) > abs($orf1->frame())) { # both ORFs on same strand
    print "\t\tboth orfs are on same strand\n" if ($verbose);
    
  } else {
    print "\t\torfs are on opposite strands\n" if ($verbose);
  }
  #
  # strands actually don't matter because GenDB start pos
  # is always less than stop pos
  #
  $overlap = $orf1->stop() - $orf2->start();
  if ($overlap > $orf2->length()) {
    $overlap = $orf2->length();
  }
  return $overlap;
}

sub HQfacts { ## return list of facts satisfying an E-value threshold
  my $orf = shift;

  if ($orf->{_HQfacts}) {
#    print "\t\treturning previously collected HQ facts for ", $orf->name(), "\n" if ($debug);
    return $orf->{_HQfacts};
  }

  my $facts = $orf->fetchfacts();
  my $HQtools = good_tools();
  my (@HQ,$minE);
  $minE = 1e-06;

  foreach my $fact (values %$facts) {
    if ($HQtools->{$fact->tool_id()}) {
      my $toolresult = $fact->toolresult();
      if ($toolresult) {
	my $e_value;
	if ($toolresult =~ /\(s\:\d+\,e\:(.+?)\)/) {
	  $e_value = $1;
	} else {
	  $e_value = $toolresult;
	}
	if ($e_value <= $minE) {
	  push(@HQ,$fact);
	}
      }
    }
  }

  $orf->{_HQfacts} = \@HQ;
  setOrf($orf);

  if (@HQ) {
#    print "\t\treturning ", scalar(@HQ), " HQ facts for ", $orf->name(), "\n" if ($debug);
    return @HQ;
  } else {
#    print "\t\t", $orf->name(), " has no HQ facts\n" if ($debug);
    return undef;
  }

}

sub HQfactCount {
  my $orf_passed = shift;
  my $orf = getOrf($orf_passed->name());
  my $cnt = 0;
  my $HQ = HQfacts($orf);

  $cnt = @$HQ if (@$HQ);
#  print "\t\tHQfactCount: \$cnt = '$cnt'\n" if ($debug);
  return $cnt;
}

sub max {
  my ($first,$sec) = @_;
  if ($first > $sec) {
    return $first;
  } else {
    return $sec;
  }
}

sub min {
  my ($first,$sec) = @_;
  if ($first < $sec) {
    return $first;
  } else {
    return $sec;
  }
}

sub getStatus {
  my $orf = shift;
#  $orf = getOrf($orf->name());

  if ($orf->{_status}) {
    return $orf->{_status};
  } else {
    return undef;
  }
}

sub setStatus { 
  my $orf = shift;
  my $statusCode = shift;
  my $override = shift;
#  $statusCode = '0' if ($statusCode && $statusCode == 99);

  my $currStatus = getStatus($orf);

  if ($currStatus && $currStatus == 4) { ## 4 = attention needed
    print "\t\tstatus of ", $orf->name(), " is already '$flag{$currStatus}'; not changing\n" if ($verbose);
    if ($override) {
      print "\t\toverride: set status of ", $orf->name(), " to '$flag{$statusCode}'\n" if ($verbose);
    } else {
      return getStatus($orf);
    }
  }

  if (($currStatus && $currStatus != 2) || !$currStatus) { ## can't change status of an ignored ORF
    print "\t\tsetting status of ", $orf->name(), " to $flag{$statusCode}\n\n" if ($verbose);
    oa_description($orf,"setting status of " . $orf->name() . " to $flag{$statusCode}");
    $orf->{_status} = $statusCode;
    setOrf($orf);
  }
  return getStatus($orf);
}

sub ignore {
  my $orf = shift;
  my $HQ = HQfactCount($orf);
  my $rtn;
  if (!$HQ) {
    print "\t\tforcing status to 'ignored' for ", $orf->name(), "\n" if ($debug);
    $rtn = setStatus($orf,2,1);
  } else {
    $rtn = setStatus($orf,2);
  }

  setOrf($orf);

   if ($rtn == 2) {
     print "\t\tchecking whether any other ORFs are affected\n" if ($verbose);
     foreach my $attOrf (@{$orf->{_attention}}) {
       print "\t\tstatus of ", $$attOrf->name(), " may need to be changged\n" if ($debug);
       setStatus($$attOrf,6,1);
       print "\t\treclassifying ", $$attOrf->name(), "\n" if ($debug);
       oa_description($$attOrf, "reclassifying " . $$attOrf->name());
       classify($$attOrf->name());
#        if (scalar(@{$$attOrf->{_attention}}) == 1) {
#  	if (! HQfacts($$attOrf)) {
#  	  print "\t\tresetting status of ", $$attOrf->name(), " to $flag{2}\n" if ($verbose);
#  	  setStatus($$attOrf,2,1);
#  	} else {
#  	  print "\t\tresetting status of ", $$attOrf->name(), " to $flag{1}\n" if ($verbose);
#  	  setStatus($$attOrf,1,1);
#  	}
#        } else {
#  	print "\t\t", $$attOrf->name(), " has more than one orf in its _attention array\n" if ($debug);
#        }
#       setOrf($$attOrf);
     }

     return 1;
   } else {
     return undef;
   }
}

sub attention {
  my $orf1 = shift;
  my $orf2 = shift;

  setStatus($orf1,4);
  setStatus($orf2,4);

  push(@{$orf1->{_attention}},\$orf2);
  push(@{$orf2->{_attention}},\$orf1);
  setOrf($orf1);
  setOrf($orf2);
  return 1;
}


sub getOrf {
  my $orfName = shift;
  my $rtn = undef;
  return unless ($orfName);

  if ($orfStatus{$orfName}) {
    $rtn = $orfStatus{$orfName};
  } elsif (ref($orfName) eq 'GENDB::orf') {
    print "found a new ORF: ", $orfName->name(), "\n" if ($debug);
    setOrf($orfName);
    $rtn = getOrf($orfName->name());
  } else {
    print "don't know what to do with: '$orfName'\n" if ($debug);
  }
  return $rtn;
}

sub setOrf {
  my $orf = shift;
  $orfStatus{$orf->name()} = $orf;
}

sub tRNA {
  my $orf = shift;
  my $lorf = getOrf($orf->name());
  my $tRNA = undef;

  if ($lorf->{_tRNA}) {
    $tRNA = $lorf->{_tRNA};
  } elsif ($lorf->name() =~ /tRNA/i) {
    $lorf->{_tRNA} = 1;
    $tRNA = 1;
    setOrf($lorf);
  } else {

  }
  return $tRNA;
}

sub rRNA {
  my $orf = shift;
  my $lorf = getOrf($orf->name());
  my $rRNA = undef;

  if ($lorf->{_rRNA}) {
    $rRNA = $lorf->{_rRNA};
  } elsif ($lorf->name() =~ /rRNA/i) {
    $lorf->{_rRNA} = 1;
    $rRNA = 1;
    setOrf($lorf);
  } else {

  }
  return $rRNA;
}

sub oa_description {
  my $orf = shift;
  my $string = shift;

  $orf->{_orfAdjDescription} .= "$string\n" if ($string && $string =~ /\w+/);
  return $orf->{_orfAdjDescription};
}

sub _help {
  my $usage = shift;

  print <<HELP

This script attempts to resolve overlaps between microbial genes in 
a GenDB genome annotation project.

$usage

Command-line Options

Option\tDescription
-h\tprint this help menu
-d\tdebugging mode
-v\tverbose output to STDOUT
-p\tGenDB project name
-c\tcontig name
-r\tregion of contig to focus (ie, 1:5000)
  \tenclose in quotation marks
-z\tdon't update GenDB database
-Z\tforce update of GenDB database
-A\trun through GenDB update routine, but don't actually touch database
-i\tignore status of ORF in GenDB when deciding current status


HELP

}

sub _debug {
  my $mssg = shift;
  print "DEBUG:\t$mssg\n";
}

sub death {
  my $signal = shift;
  print "\n\nSIG$signal received\n";
  exit();
}
