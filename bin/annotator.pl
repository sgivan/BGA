#!/usr/bin/env perl
# $Id: annotator.pl,v 3.18.2.1 2008/01/31 03:44:37 givans Exp $
#
# standard version
#

use 5.10.0;
use warnings;
use strict;
use lib '/home/sgivan/data/projects/BGA/lib';
use Carp;
use Getopt::Std;
use vars qw/ $opt_p $opt_d $opt_D $opt_v $opt_o $opt_O $opt_f $opt_F $opt_c $opt_b $opt_a $opt_A $opt_t $opt_T $opt_h $opt_i $opt_I $opt_l $opt_g $opt_G $opt_r $opt_R $opt_z $opt_E $opt_C $opt_S $opt_e $opt_X /;
use Bio::DB::Flat;
#use CGRB::PFAM;
use BGA::PFAM;
use SOAP::Lite;
use Statistics::Distributions;
use Statistics::Descriptive;
#use lib '/local/cluster/genDB/share/perl';
use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";
use Projects;

getopts('p:o:c:b:Aa:l:g:F:r:RdDvfthOe:EiITzEC:GSX');

if ($opt_X) {
  $opt_G = 1;
  $opt_v = 1;
  $opt_D = 1;
  $opt_T = 1;
  $opt_R = 1;
  $opt_F = 'annotator.out';
  $opt_O = 1;
  $opt_g = 'T'; # name genes after E. coli names
}

my ($project,$debug,$verbose,$allOrfs,$filter,$cutoff,$toolCutoff,$annotTool,$overlapLength,@namingStd,@orfs,$addAnnot,$keepEC,$kegg_soap,%ecoli,@annotTool,$exclude,$force);
my $usage = "usage:  annotator.pl -p <project> [-d (debug) -v (verbose) -h (help menu)]\n";

#
#########################################
#  Collect command-line options		#
#########################################
#
$debug = $opt_d;
print "debug enabled\n" if ($debug);
$verbose = $opt_v;
$verbose = 1 if ($debug);
print "verbose enabled\n" if ($verbose);
$force = $opt_A || 0;
print "force enabled\n" if ($force && $verbose);

if ($opt_h) {			## print help menu and exit
  _debug("printing help menu") if ($debug);
  _help($usage);
  exit(0);
}

$project = $opt_p;

if (!$project) {
  _debug("no project name was provided; printing usage summary") if ($debug);
  print $usage;
  exit(0);			## must have a project name
}
print "project: $project\n" if ($verbose);

Projects::init_project($project); # Initialize GenDB project
require GENDB::orf;
require GENDB::annotation;
require GENDB::annotator;
require GENDB::fact;
require GENDB::tool;
require GENDB::contig;
#
# Note that I've had problems using some Bio::* modules because of version diffs
# betw what's on waterman and what's on the cluster.  Some of the GENDB::* modules
# use Bio::* modules, which can conflict with the namespace of this script.  If you
# observe strange problems with sequences or sequence annotations look at the Bio::*
# modules in /local/cluster/lib/perl5/site_perl.
#
#
my $annotator = GENDB::annotator->init_name('auto');

if ($opt_t) {			# list tools by their id's
  print "Tools for project '$project'\n\n";
  my $tools = GENDB::tool->fetchallby_id();
  foreach my $tool (sort { $a->id() <=> $b->id() } values %$tools) {
    print "\tid: ", $tool->id, ", ", $tool->description(), "\n";
  }
  print "\n\n";
  exit(0);
}
#
# User can choose to annotate all ORFs or a single ORF
#
if ($opt_o) {			# use to annotate a single ORF
	my @temp_orfs = split /\,/, $opt_o;
	foreach my $temp_orf (@temp_orfs) {
  	#push(@orfs,$opt_o);
  	push(@orfs,$temp_orf);
  	#print "annotating orf '$opt_o'\n" if ($verbose);
  	print "annotating orf '$temp_orf'\n" if ($verbose);
  }
  #exit();
} elsif ($opt_C) { # annotate all ORFs on a single contig
    _debug("annotating orfs on contig '$opt_C'") if ($debug);
    print("annotating orfs on contig '$opt_C'") if ($verbose);
    my $contig = GENDB::contig->init_name($opt_C);
    print "contig ID for '$opt_C': " . $contig->id() . "\n";
    @orfs = @{$contig->fetchorfs_arrayref()};
    _debug("number of orfs: " . scalar(@orfs)) if ($debug);
} elsif ($opt_O) {		# annotate all ORFs
    $allOrfs = 1;
    @orfs = @{GENDB::orf->fetchall()};
    print "annotating all orfs\n" if ($verbose);
    _debug("number of orfs: " . scalar(@orfs)) if ($debug);
}

$filter = $opt_f || 1;	  ## manually set this to true if not provided
print "filter enabled\n" if ($verbose && $filter);
$cutoff = $opt_c; ## % of unique words to print in verbose mode - no functional consequence
$cutoff = 0.05 unless ($cutoff); # % of unique words to print in verbose mode
print "cutoff = $cutoff\n" if ($verbose && $cutoff);

$overlapLength = $opt_l; ## minimum size of overlap betw query and db hit
$overlapLength = 0.65 unless ($overlapLength); # % overlap of gene product with db hit
print "overlap length = $overlapLength\n" if ($verbose && $overlapLength);

$toolCutoff = $opt_b;	     ## minimum tool score to accept (E-value)
$toolCutoff = 1e-06 unless ($toolCutoff);
print "tool cutoff = $toolCutoff\n" if ($verbose && $toolCutoff);

$keepEC = $opt_E;
$keepEC = 0 unless ($keepEC);
print "keeping old EC numbers\n" if ($verbose && $keepEC);

if ($opt_g) {	   ## attempt to name genes after a reference organism
  print "naming after reference organism\n" if ($verbose);
  if ($opt_g =~ /\,/) {
    @namingStd = split ',', $opt_g;
  } elsif ($opt_g eq 'T' || $opt_g eq 't') {
    push(@namingStd, 'Escherichia coli');
  } else {
    push(@namingStd,$opt_g);
  }
}


if ($opt_F) {			## generate an output file
  print "output file: '$opt_F'\n" if ($verbose);
  open(OUT,">$opt_F") or die "can't open file '$opt_F': $!";
}

my $tools = GENDB::tool->fetchallby_id();
if ($opt_a) {
  $annotTool = $opt_a;
} else {
  #
  # if user hasn't selected a tool, show this menu until one is selected or script quits
  #
 ToolCHOOSE: while (!$annotTool) {
    print "Tools for project '$project'\n\n";
    foreach my $tool (sort { $a->id() <=> $b->id() } values %$tools) { # tools retrieved from GenDB database for this organism
      print "\tid: ", $tool->id, ", ", $tool->description(), "\n";
    }
    print "\tq: quit this script\n";
    print "\n\n";
    print "Choose a tool by it's id:  ";
    my $tempTool = <stdin>;
    chomp($tempTool);
    if ($tempTool) {
      exit(0) if ($tempTool =~ /^q/i);
      if ($tools->{$tempTool}) {
	$annotTool = $tempTool;
	last ToolCHOOSE;
      }
    }
    redo ToolCHOOSE;
  }
}

if ($annotTool =~ /\,/) {
  @annotTool = split /\,/, $annotTool;
} else {
  push(@annotTool,$annotTool);
}
foreach my $tool_id (@annotTool) {
#  print "Annotating with results of ", $tools->{$annotTool}->description(), "\n\n" if ($verbose);
  print "Will use results of '", $tools->{$tool_id}->description(), "'\n\n" if ($verbose);
}

if ($opt_r) {
  if ($opt_r == 1 || $opt_r == 2) {
    $addAnnot = $opt_r;
  } else {
    print "invalid option for -r, see help menu using the -h option\n";
    exit(0);
  }
} else {
  $addAnnot = 0;
}

if ($opt_e) {
  $exclude = $opt_e;
}

#
#########################################
#  End of command-line options		#
#########################################
#

my @annotation_calls;
my %annotation_calls;
#@annotTool = (1,2);
foreach my $annotTool (@annotTool) {

  print "\n\n", "*" x 60, "\n\n*** Annotating with results of '", $tools->{$annotTool}->description(), "'  ***\n\n", "*" x 60, "\n\n" if ($verbose);

  my $pfam = BGA::PFAM->new();	# create a BGA::PFAM object no matter which tool we are using
  my $toolDB; # this will be a reference to a class that interacts/retrieves data from selected database
  #my $index_dir = "/home/cgrb/givans/lib/annotator/indices";
  my $index_dir = "/home/sgivan/lib/annotator/indices";
  if ($tools->{$annotTool}->description() =~ /swiss/i) {
    #  my $index_dir = "/home/cgrb/givans/lib/annotator/indices";
    my $write_flag = 0;
    $write_flag = 1 if ($opt_I);

    $toolDB = Bio::DB::Flat->new(
				 -directory  =>  $index_dir,
				 -dbname     =>  'sprot.idx',
				 -format     =>  'swiss',
				 -write_flag =>  $write_flag,
				 #			       -index      =>  'binarysearch',
				 -index	   =>	'bdb',
				);
	if ($opt_I) {
      #$toolDB->build_index('/dbase/scratch/swiss/sprot.dat') if ($opt_I);
      $toolDB->build_index('/ircf/dbase/swissprot/uniprot_sprot.dat') if ($opt_I);
      print "new swissprot index complete\n";
#      exit();
    }
    print "using swissprot index\n" if ($debug);

  } elsif ($tools->{$annotTool}->description() =~ /kegg/i) {
    #  my $index_dir = "/home/cgrb/givans/lib/annotator/indices";
    my $write_flag = 0;
    $write_flag = 1 if ($opt_i);

    $toolDB = Bio::DB::Flat->new(
				 -directory  =>  $index_dir,
				 -dbname     =>  'kegg.idx',
				 -format     =>  'fasta',
				 -write_flag =>  $write_flag,
				 -index	   =>	'bdb',
				);
    if ($opt_i) {
        #$toolDB->build_index('/dbase/KEGG/genes') if ($opt_i);
        $toolDB->build_index('/ircf/dbase/KEGG/genes') if ($opt_i);
        print "new KEGG index complete\n";
    }
    print "using KEGG index\n" if ($debug);

    # Initialize KEGG SOAP interface

    $kegg_soap = SOAP::Lite->service('http://soap.genome.jp/KEGG.wsdl') if ($opt_S);
    #  print "getting KEGG organisms\n";
    #  my $korgs = $kegg_soap->list_organisms();
    #  print "\@korgs contains " . scalar(@$korgs) . " organisms\n";
    #  foreach my $korg (@$korgs) {
    #     print "\$korg is a " . ref($korg) . "\n";
    #     my @keys = keys(%$korg);
    #     foreach my $key (@keys) {
    #       print "key: '$key'\n";
    #     }
    #     exit();
    #    print  $korg->{entry_id}, ":\t", $korg->{definition}, "\n";
    #  }
    #  exit();

  } elsif ($tools->{$annotTool}->description() =~ /pfam/i) {
    $toolDB = $pfam;
  } else {
    $toolDB = undef;
  } # end of setting up $toolDB


#---------------------------------------------------------------------------
#  $opt_I and $opt_i are meant to be used when you just want to
#  create new indices of a database
#---------------------------------------------------------------------------

  next if ($opt_I || $opt_i);

  my $loopcnt = 0;
  foreach my $orfName (@orfs) { # loop through all the ORFs in the genome project
    print "\$orfName isa '", ref($orfName), "'\n" if ($debug);

    if ($orfName) {
      print "if (\$orfName)\n" if ($debug);
      my ($orf,$orfCommonName);

      if (ref($orfName) && $orfName->isa('GENDB::orf')) {
        print "if (\$orfName->isa('GENDB::orf'))\n" if ($debug);
        $orf = $orfName;
        $orfName = $orf->name();
      } else {
        print "\$orfName is not a GENDB::orf\n" if ($debug);
        $orf = GENDB::orf->init_name($orfName);
      }
      next if (!$orf->frame());
      #
      # Honor -r options
      #

      if ($addAnnot) {
        if ($addAnnot == 1) {
          next if ($orf->status() && $orf->status() == 3);
        } elsif ($addAnnot == 2) {
          my $annotations = $orf->fetch_annotations($annotator->id()); # fetch all annotations from database
          #	print "number of annotations:  ", scalar(keys %$annotations), "\n";
          my @annotations = keys %$annotations;
          
          next if (scalar(@annotations)); # go to next ORF if there are no annotations
        }
      }

      #
      #

      #
      # Skip "ignored" ORFs
      #
      if ($orf->status() == 2) { # these are 'ignored' ORFs
        if (!$force) {
          print "not annotating ", $orf->name(), " since it's status is ", $orf->status(), "\n" if ($verbose);
          next;
        }
      }
      my $orfID = $orf->id();
      next unless ($orfID);

      ++$loopcnt;
      print "$orfName; loopcnt = $loopcnt\n" if ($verbose);
      #
      # fetch facts for this ORF from GenDB
      #
      my $facts = $orf->fetchfacts(); # fetchfacts returns a hash reference of GENDB::fact objects keyed by FactID
      my ($cnt,$protLength,%factDB,%EC,%toolData,%geneName);
      #
      #

      #
      # Determine length of protein
      #    
      if ($orf->stop() && $orf->start()) {
        $protLength = int(abs($orf->stop() - $orf->start())/3);
      } else {
        $protLength = 10;
      }
      #   print "length of product = '$protLength'\n" if ($verbose);
      #
      #   


      #
      # Loop through facts
      #
      foreach my $factID (keys %$facts) {
          
        my $description = $facts->{$factID}->description();
        my $toolResult = $facts->{$factID}->toolresult();
        my $tool = GENDB::tool->init_id($facts->{$factID}->tool_id());
        my $toolName = $tool->name();
        my $dbRef = $facts->{$factID}->dbref();
        #my $dbRef = 'Q3KCC5';
        if ($toolName eq 'BLASTP-swissprot') {
            if (substr($dbRef,0,3) eq 'sp|') {
                my @spvals = split /\|/, $dbRef;
                $dbRef = $spvals[1];
            }
        } 
        my ($toolScore,$toolE);
          
        if ($tool->id() == $annotTool) { # only cycle through facts from selected tool
          print "\n\nTesting:  $toolName [$toolResult]: $description\n" if ($debug && $toolName && $toolResult && $description);
          if ($toolResult =~ /\(s\:(\d+)\,e\:([0-9e\-\.]+)\)/) {
            $toolScore = $1;
            $toolE = $2;
          } elsif ($toolResult =~ /([\d\-e\.]+)/) {
            $toolE = $1;
            $toolScore = 1;
          } else {
            # Set scores to 0
            $toolScore = 0;
            $toolE = 0;
          }
          #	_debug("toolE = '$toolE', toolScore = '$toolScore'") if ($debug);
          next unless ($toolE <= $toolCutoff);
          #	_debug("$toolE passed toolCutoff ($toolCutoff)") if ($debug);
          #
          # fact is from correct tool and satisfies E-value threshold
          #

          #
          # Go to next fact if fact is from excluded organism (only really applies to KEGG database)
          #
          if ($exclude) {
            next if ($facts->{$factID}->dbref() =~ /^$exclude\:/);
          }

          #
          # Check if db hit satisfies minimum overlap parameter
          #
          if ($facts->{$factID}->dbto() && $facts->{$factID}->dbfrom()) {
            my $span = (int(abs($facts->{$factID}->dbto() - $facts->{$factID}->dbfrom()))) / $protLength;
            #	  print "span = '$span'\n";
            #	  next unless ($span >= $overlapLength);
            if ($span >= $overlapLength) {
              _debug("span ($span) >= $overlapLength") if ($debug);
            } else {
              _debug("span ($span) < $overlapLength") if  ($debug);
              next;
            }
          }

          _debug('
          #
          # All preliminary parameters have been met
          # Add this fact to set of high-quality hits
          #
          ') if ($debug);
          
          #
          # populate %toolData with HQ hits
          #
          $toolData{$factID} = [$toolScore, $toolE, $description, $dbRef];# not sure if I need this - only exists on 2 lines
          #
          print "$toolName\n\tResult: [$toolResult]\n\tDBID: $dbRef\n\tDescr: $description\n" if ($debug && $toolName && $toolResult && $description);
          if ($toolDB) {
            #_debug('$toolDB exists') if ($debug);
            my $seq = $toolDB->get_Seq_by_id($dbRef);# $seq should be a Bio::Seq object
    	    _debug("seq: '" . ref($seq) . "'") if ($debug);

            if (!$seq || !$seq->isa('Bio::Seq')) {
                $seq = $toolDB->get_Seq_by_acc($dbRef);
                die "can't retrieve Bio::Seq object from $toolDB\n" if (!$seq);
            }
            # use the description from the $seq object
            $description = $seq->description();

            # push Bio::Seq object onto the end of the array in %toolData
            push(@{$toolData{$factID}},$seq); # not sure if I need this, $toolData only exists on 2 lines


            #
            #	Try to assign a gene name from reference species
            #
            if ($seq && $seq->isa('Bio::Seq')) {
              #_debug("OK, " . $seq->id()) if ($debug);
              if ($opt_g) {
                _debug('
                #
                #	Gene Names determined by best hit in specificed species
                #
                ') if ($debug);
                if ($debug) {
                  print "\tspecies: ", $seq->species()->binomial(), "\n" if ($seq->species() && $seq->species()->binomial());
                }

                foreach my $namingStd (@namingStd) {

                  if ($seq->species() && $seq->species()->binomial() eq $namingStd) {
                    if ($tools->{$annotTool}->description() =~ /swiss/i) {
    #                 print "sequence is from $namingStd\n";
                      my $ac = $seq->annotation();
                      my @geneName = $ac->get_Annotations('gene_name');
                      #print "geneName: '", scalar(@geneName), "'\n";
                      next if (!@geneName);
                      my $tmpName = $geneName[0]->as_text();
                      $tmpName =~ s/Value:\s//;
    #                 print "adding potential name: '$tmpName'\n";
                      $geneName{$toolE} = $tmpName;
    #                 print "\tGene: $tmpName\n" if ($debug);
                    }


                  } elsif ($tools->{$annotTool}->description() =~ /kegg/i) {
                    my $korg;
                    if ($namingStd eq 'Escherichia coli') {
                      $korg = 'ec[ojesc]';
                    } else {
                      $korg = $namingStd;
                    }

                    if ($seq->id() =~ /^$korg:/) {
                      #		    print "\nKEGG method (" . $seq->id() . "; " . $seq->description() . ")\n";
                      if ($seq->description =~ /^(\w+)[,;]/) {
                    #		      print "\tpotential homolog in $korg: $1 (E: $toolE)\n\n";
                    $geneName{$toolE} = $1;
                      }
                    }
                  }
                }
              } elsif ($opt_G) {
                _debug('
                #
                #	Try to assign a gene name from best BLAST hit
                #
                ') if ($debug);
                if ($tools->{$annotTool}->description() =~ /kegg/i) {
                  #print "opt_G KEGG\n";
                  $geneName{$seq->id()} = $seq->description();
                  _debug("Gene Name: '" . $seq->description() . "'") if ($debug);
#                } elsif ($seq->species() && $seq->species()->binomial()) {  # why am I checking for this here?
#                                                                            # maybe just to make sure std methods 
#                                                                            # are available for this obj
                 } elsif ($seq->isa('Bio::Seq')) {
                    #print "opt_G swiss()\n";
                    # $seq isa Bio::Seq::RichSeq
                    if ($tools->{$annotTool}->description() =~ /swiss/i) {
                        my $ac = $seq->annotation();
#                        my @geneName = $ac->get_Annotations('gene_name');
#                            print "Gene Names for '" . $seq->display_name() . "'\n";
#                            for my $geneName (@geneName) {
#                                print "\$geneName isa '" . ref($geneName) . "'\n";
#                                my $gname = $geneName->find('Name');
#                                print "\$gname: '" . $gname . "'\n";
#                                #print "gene name: '" . $geneName->value('Name') . "'\n";
#                            }
#                        
                        my @geneName = $ac->get_Annotations('gene_name');# will return an array of Bio::Annotation::TagTree 
#                        print "\@geneName has '" . scalar(@geneName) . "' elements\n";
#                        if (scalar(@geneName)) {
#                        my $tmpName = $geneName[0]->as_text();
                        #  $tmpName =~ s/Value:\s//;
                        if ($geneName[0] && $geneName[0]->can('find')) {# fancy introspection
                            $geneName{$toolE} = $geneName[0]->find('Name');#find is a Bio::Annotation::TagTree method
                            #$geneName{$toolE} = $tmpName;
                            #_debug("Gene Name: $tmpName") if ($debug);
                            _debug("Gene Name: $geneName{$toolE}") if ($debug);
                        } else {
                        _debug('unable to assign gene name from BLAST description') if ($debug);
                        }


                    } # end of swissprot name extract bracket
                } else {
                    print "unknown object '" . ref($seq) . "' - cannot retrieve annotations\n" if ($verbose);
                }

              } else {
                #print "annotation for this gene is not available" if ($debug);
                print "annotation for this gene is not available" if ($verbose);
              }
            }
          }
          #
          #	End of gene name assignment
          #

          #
          #	For each fact, extract words and EC numbers and add to the running tally & score
          #

          my @EC = getEC($description,$tools->{$annotTool}->description());
          _debug("sending '$description' to getWords()") if ($debug);
          my @words = getWords($description); # extract all "words" from hit description
          $cnt += scalar(@words);
          uniqueWords(\%factDB,\@words,$toolScore); # identify and tally unique words
          uniqueWords(\%EC,\@EC,$toolScore); # identify and tally EC numbers
        } # end of if ($tool->id() == $annotTool)
        #
        #
      }

      if ($verbose) {
	my $sortedWords = sort_by_value(\%factDB);
	my $numUnique = scalar(@$sortedWords);
	print "total words = $cnt\n" if ($cnt);
	print "total unique words = $numUnique\n";
    
	my $top = $numUnique * $cutoff;
	if ($debug) {
	  _debug("top = $top");
	  printHash($sortedWords,\%factDB,$top) if (%factDB);
	}
      }
 
      #
      #
      #############################################
      #				    		#
      # Start assigning values to annotation	#
      # variables ($A_*).  These will be used	#
      # for annotations.				#
      #						#
      #############################################
      #
      #

      my ($A_product,$A_name,$A_description,$A_ec,$A_db_id,$hit_geneName,$hit_seq,$hit_binomial,$hit_id) = ('NULL','','NULL','','','','','');
      #
      #########################
      # Determine Gene Name   #
      #########################
      #
      if ($opt_g) {
        my @minE = keys %geneName;
        if (@minE) {
            if (scalar(@minE) > 1) {
                @minE = sort { $a <=> $b } @minE;
            }
            $A_name = $geneName{$minE[0]};
        } elsif (0) {

        } else {
            $A_name = $orf->name();
        }
        print "gene name (\$A_name) = '$A_name'\n" if ($verbose);
      }

      #
      # End of Gene Name
      #####################
      #

      #
      #############################
      # Determine EC assignment	#
      #############################
      #

      #    $A_ec = ECscore(\%EC)->[1];
      #    $A_ec = '' unless ($A_ec);

      print "determined EC number to be '$A_ec'\n" if ($A_ec && $verbose);

      #
      # End of EC assignment
      ###########################
      #

      if (%factDB && %toolData) {
        #	my ($bestHit,$bestscore) = bestHit(\%factDB,\%toolData,\%EC);
        my $maxScore = 0;
        foreach my $tool_data (values %toolData) {
            $maxScore = $tool_data->[0] if ($tool_data->[0] > $maxScore);
        }

        my ($bestHit,$bestscore,$best_scoredata,$scores) = bestHit(\%factDB,\%toolData,$A_ec,$maxScore);
        my $A_ec = '';

        print "trying to determine EC number\n" if ($verbose);
        $A_ec = (getEC($bestHit->[2],$tools->{$annotTool}->description()))[0];
        my @dash = $A_ec =~ /-/g if ($A_ec);

        if (! $A_ec || scalar(@dash) >= 2) {
            print "using alternative EC algorithm '@dash'\n" if ($verbose);
            print "no A_ec\n" if (!$A_ec && $verbose);
            $A_ec = ECscore(\%EC,$scores,$bestHit->[0])->[1];
        }
        $A_ec = '' unless ($A_ec);
        print "EC number: $A_ec\n" if ($verbose);
        #
        # $bestHit is a reference to an array:
        #  [0] tool score
        #  [1] tool E-value
        #  [2] hit description
        #  [3] ID of hit from it's particular database
        #  [4] Bio::Seq or Bio::PrimarySeq object containing the hit sequence
        #
        #


        if ($bestHit && ref $bestHit eq 'ARRAY') {
            print "using hit ($bestscore): $bestHit->[0] $bestHit->[1] $bestHit->[2] $bestHit->[3]\n" if ($verbose);
            $A_description = $bestHit->[2];
            $A_product = $bestHit->[2];
            $A_db_id = $bestHit->[3];

            if ($tools->{$annotTool}->description() =~ /kegg/i) {
                if ($opt_G) {
                    print "determining gene Name from best hit\n" if ($verbose);
                    #	    if ($A_description =~ /(\w+?)\;/) {
                    
                    #	    if ($A_description =~ /([\S]+?)\;/) {
                    if ($A_description =~ /^([\S]{2,})\;/) {
                        print "best hit has decipherable gene name: '$1'\n" if ($verbose);
                        $A_name = $1;
                    } else {
                        foreach my $id (keys %geneName) {
                            if ($id =~ /^ec[ojesc]\:/) {
                                print "resorting to E. coli gene name\n\tid: '$id'; $geneName{$id}\n" if ($verbose);
                                if ($geneName{$id} =~ /^([\S]+?)[;,]/) {
                                    print "\tgene name will be set to: '$1'\n" if ($verbose);
                                    $A_name = $1;
                                    last;
                                }
                            }
                        }
                    }
                }
            } elsif ($tools->{$annotTool}->description() =~ /swiss/i) {
                #	    foreach my $key (keys %geneName) {
                #	      print "key: $key; value: $geneName{$key}\n";
                #	    }
            }


            #
            # The best hit sequence can be either a Bio::Seq object
            # or a Bio::PrimarySeq object.  Bio::Seq objects
            # carry more annotation.
            #
            my $seq = $bestHit->[4];
            if ($seq && $seq->isa('Bio::Seq')) {
                #print "using Bio::Seq object\n";
                my $ac = $seq->annotation();
                $hit_id = $seq->id();

                foreach my $dblink ($ac->get_Annotations('dblink')) {
                    if ($dblink->database eq 'Pfam') {
                        #	      print "\tPfam link: ", $dblink->primary_id(), "\n";
                                my $pfam_id = $pfam->acc_to_id($dblink->primary_id());
                        #		my $pfam_id = $toolDB->acc_to_id($dblink->primary_id());
                        #	      print "\t\tInterpro abstract: ", $pfam->interpro_abstract($pfam_id)->[0], "\n";
                        #	      print "GO fcn: ", $pfam->go_function($pfam_id)->[0], "\n" if (defined $pfam->go_function($pfam_id)->[0]);
                        #	      print "GO process: ", $pfam->go_process($pfam_id)->[0], "\n" if (defined $pfam->go_process($pfam_id)->[0]);
                        #	      print "GO component: ", $pfam->go_component($pfam_id)->[0], "\n" if (defined $pfam->go_component($pfam_id)->[0]);
                    }
                }

                if (0) { # not used, but illustrates how to retrieve annotations from Bio::Seq objects
                    if ($verbose) {
                        my @aKeys = $ac->get_all_annotation_keys();
                        foreach my $aKey (@aKeys) {
                            print "annot key: '$aKey'\n";
                            my @values = $ac->get_Annotations($aKey);
                            foreach my $value (@values) {
                                print "\t'",$value->as_text(),"'\n";
                            }
                        }
                    }
                }
            
                my @hit_geneNames = $ac->get_Annotations('gene_name');

                if ($bestHit->[4] && ref($bestHit->[4]) =~ /Bio\:\:/) {
                    $hit_seq = $bestHit->[4]->seq();
                }

                #
                #	For file output, we can provide name of best hit and species
                #
                if ($hit_geneNames[0] && $hit_geneNames[0]->can('find')) {
                    $hit_geneName = $hit_geneNames[0]->find('Name');
                } elsif ($hit_geneNames[0] && $hit_geneNames[0]->can('as_text')) {
                    $hit_geneName = $hit_geneNames[0]->as_text();
                    $hit_geneName =~ s/Value\:\s//;
                }

                $hit_binomial = $seq->species()->binomial() if ($seq && $seq->isa('Bio::Seq') && $seq->species());

            } elsif ($seq && $seq->isa('Bio::PrimarySeq')) {
                $hit_id = $seq->id();
                $hit_geneName = $seq->id();
                $hit_seq = $seq->seq() || '';
            } else {
                print "\$seq is a ", ref($seq), "\n" if ($seq && $debug);
            }

            if ($verbose && ref($toolDB) =~ /BGA::PFAM/) {

                print "PFAM id = '$bestHit->[3]'\n";
                print "PFAM acc = ", $toolDB->id_to_acc($bestHit->[3]),"\n";
        # 	    my $abstracts = $toolDB->interpro_abstract($bestHit->[3]);
        # 	    if (ref($abstracts)) {
        # 	      my $abstract_cnt;
        # 	      foreach my $abstract (@$abstracts) {
        # 		print "abstract ", ++$abstract_cnt, ": '$abstract'\n\n";
        # 	      }
        # 	    }
                
                my $interpro_info = $toolDB->interpro_info($bestHit->[3]);
                foreach my $ref (@$interpro_info) {
                print "interpro id: '", $ref->[0], "\n";
                print "interpro abstract: '", $ref->[1], "\n";
                }


                my $go_info = $toolDB->go_info($bestHit->[3]);
                foreach my $ref (@$go_info) {
                print "GO ID: '", $ref->[0], "'\n";
                print "GO term: '", $ref->[1], "'\n";
                print "GO category: '", $ref->[2], "'\n";
                }

        #  	    map { print $_ if ($_) } $toolDB->go_id($bestHit->[3]);
        # 	    print "\n";
        # 	    print "GO:  ", $toolDB->go_category($bestHit->[3]), " -> ", $toolDB->go_term($bestHit->[3]), "\n";
        # 	    print "\n";
            }

        #	  print "hopefully the gene name will be '$geneName{$bestHit->[1]}' $bestHit->[1]\n";

            push(@{$annotation_calls{$orf->id()}},
                    {
                        tool_descrip	=>	$tools->{$annotTool}->description(),
                        orf_name	=>	$orfName,
                        orf_id		=>	$orf->id(),
                        A_name		=>	$A_name || $hit_geneName || $geneName{$bestHit->[1]} || $orf->name(),
                        A_product	=>	$A_product,
                        A_description	=>	$A_description,
                        A_ec		=>	$A_ec,
                        tool_id		=>	$annotTool,
                        hit_score	=>	$bestHit->[0],
                        hit_E		=>	$bestHit->[1],
                        hit_id		=>	$bestHit->[3],
                        hit_description	=>	$bestHit->[2],
                        hit_gene_name	=>	$hit_geneName,
                        hit_sequence	=>	$hit_seq,
                        hit_binomial	=>	$hit_binomial,
                        best_score	=>	$bestscore,
                        score_data	=>	$best_scoredata,
                        summary		=>	$tools->{$annotTool}->description() . "; dbid=" . $bestHit->[3] . "; $A_description",
                        scores		=>	$scores,
                    }
                );
            #
            #
            #print "one\n" if ($debug);
            }
            #print "two\n" if ($debug);
            }
            #print "three\n" if ($debug);
            }
            #print "four\n" if ($debug);
    }				## end of foreach $orf
    #print "five\n" if ($debug);
}
print "number of annotations to load: '" . scalar(keys(%annotation_calls)) . "'\n";
#print "six\n" if ($debug);
#
#
print "\n\n", "+" x 60,"\ndeciding which annotation to use ...\n", "+" x 60, "\n\n" if ($verbose);

my $annot_cnt;
foreach my $annotation_calls (values %annotation_calls) {
    @annotation_calls = @$annotation_calls;
    if ($opt_D) {
        my %probs;
        my $stat = Statistics::Descriptive::Full->new();
        my @scores;
        foreach my $annot (@annotation_calls) {
            push(@scores,@{$annot->{scores}});
        }

        $stat->add_data(@scores);

        if ($stat->standard_deviation()) {
            $stat->sort_data();
            my $mean = $stat->mean();
            my $sd = $stat->standard_deviation();
            my $count = $stat->count();
            foreach my $pt ($stat->get_data()) {
                my $t = ($pt - $mean) / $sd;
                my $tprob = Statistics::Distributions::tprob(($count - 1),$t);
                print "t-test for '$pt': t = $t, tprob = $tprob\n" if ($debug);
                $probs{$pt} = $tprob;
            }


            foreach my $annot (@annotation_calls) {
                $annot->{tprob} = $probs{$annot->{best_score}};
                $annot->{summary} .= "; t-prob = $probs{$annot->{best_score}}";
            }



            @annotation_calls = sort { $a->{tprob} <=> $b->{tprob} } @annotation_calls;
        }

    } else {
        @annotation_calls = sort { $b->{best_score} <=> $a->{best_score} } @annotation_calls;
    }

    my $annot = $annotation_calls[0];

    if ($verbose) {
        print "\n\nAnnotation call [" . $tools->{$annot->{tool_id}}->description() . "]:\n\n";

        foreach my $characteristic (sort {$a cmp $b}  keys %$annot) {
            printf "%30s\t%80s\n", $characteristic, length($annot->{$characteristic}) > 80 ? substr($annot->{$characteristic},0,70) . " ..." : $annot->{$characteristic};
        #    print "$characteristic\t $annot->{$characteristic}\n";
        }
    }

    #
    #
    #################################
    #	File Output		#
    #################################
    #
    #
    if ($opt_F) {			## file output
        #	    print OUT "'$orfName'\t'$A_name'\t'$A_product'\t'$A_description'\t'$A_ec'\t'$bestHit->[0]'\t'$bestHit->[1]'\t'$bestHit->[3]'\t'$bestHit->[2]'\t'$hit_geneName'\t'$hit_seq'\t'$hit_binomial'\n";
        my $line = '';
        my @columns = ('orf_name','A_name','A_product','summary','A_ec','hit_score','hit_E','hit_id','hit_description','hit_gene_name','hit_sequence','hit_binomial');

        foreach my $column (@columns) {
            my $value = $annot->{$column} || '';
            $line .= "\t$value";
        }
        $line .= "\n";
        print OUT $line;
    }
    #
    #	End of File Output
    ##############################
    #

    #exit();

    #comment start

    # #
    # #
    # #########################################
    # # Insert into GenDB annotation table	#
    # #########################################
    # #
    # #

    # 	  my $annotations = {
    # 			     product		=>	$A_product,
    # 			     name		=>	$A_name || $orf->name(),
    # 			     description	=>	$A_description,
    # #			     ec			=>	$A_ec,
    # 			     date		=>	time(),
    # #			     db_id		=>	$A_db_id,
    # 			    };
    my $annotations = {
                product		=>	$annot->{A_product},
                name	    	=>	$annot->{A_name},
                #name	    	=>	'blah',
                #description	=>	$annot->{A_description},
                description	=>	$annot->{A_description},
                #ec			=>	$A_ec,
                date		    =>	time(),
                #db_id		=>	$A_db_id,
            };
                    
    if ($keepEC) {
    #my $latest_annotation = GENDB::annotation->latest_annotation_init_orf_id($orf->id());
    my $latest_annotation = GENDB::annotation->latest_annotation_init_orf_id($annot->{orf_id});
    my $ec = $latest_annotation->ec();
    if ($ec && $ec =~ /[0-9\.\-]+/) {
        print "old EC = '$ec'\n" if ($verbose);
        # 		$A_ec = $ec;
        $annot->{A_ec} = $ec;
    } elsif ($annot->{A_ec}) {
        print "new EC\n" if ($verbose);
    }
    }
	     
    print "EC number will be set to: " . $annot->{A_ec} . "\n\n\n\n" if ($verbose);
    $annotations->{ec} = $annot->{A_ec};
# 	    $annotations->{comment} = "auto-annotation derived from facts\nTool: " . $tools->{$annotTool}->description() . "\nDB ID: $hit_id";
    $annotations->{comment} = "auto-annotation derived from facts\n" . $annot->{summary};
    $annotations->{annotator_id} = $annotator->id();

    if ($kegg_soap) {
        my ($KO,$korg);
        if ($annotations->{description} =~ /\[(KO:\w+)\]/) {
            $KO = $1;
    #	      print "\$KO = '$KO'\n" if ($verbose);
        }
        if (defined($annotations->{db_id}) && $annotations->{db_id} =~ /(\w+):/) {
            $korg = $1;
    #	      print "\$korg = '$korg'\n" if ($verbose);
        }
            
        if ($KO && $korg) {
    #	      my $kgenes = $kegg_soap->get_genes_by_ko($KO,$korg);
            my $kgenes = $kegg_soap->get_genes_by_ko($KO,'eco');
            if ($kgenes) {
                foreach my $gene (@$kgenes) {
                    print "gene: '",$gene->{entry_id}, "'\t'", $gene->{definition}, "'\n" if ($verbose);

            # 		  my $motifs = $kegg_soap->get_motifs_by_gene($gene->{entry_id},'pfam');
            # 		  foreach my $motif (@$motifs) {
            # 		    print "motif:  " . $motif->{definition} . "\n";
            # 		    kdump($motifs);
            # 		    print "\n\n";
            # 		  }

                }
            }
        }
    }

    if ($verbose) {
        print "adding to annotations:\n";
        foreach my $key (sort {$a cmp $b} keys %$annotations) {
            my $value = $annotations->{$key};
            $value =~ tr/\n/ /;
            printf "\t%s = %s\n", $key, length($value) > 70 ? substr($value,0,70) . " ..." : $value;
        }
        print "\n\n";
    }


    if (!$opt_z) {
    #   my $Annot = GENDB::annotation->create($orfName,$orfID);
        my $Annot = GENDB::annotation->create($annot->{orf_name},$annot->{orf_id});
        $Annot->mset($annotations);
    #    $Annot->tool_id($annotTool);
        $Annot->tool_id($annot->{tool_id});
        my $orf = GENDB::orf->init_name($annot->{orf_name});
        $orf->status('1');
        ++$annot_cnt;
    }
}
# #
# # End of database insertion
# ################################
# #

print $annot_cnt . " ORFs annotated\n" if ($opt_T && $annot_cnt);

# comment end


close(OUT) if ($opt_F);



#
#
#########################################
#					#
#	Subroutines			#
#					#
#########################################
#
#

sub getWords {			# returns an array of 'words'
    my $line = shift;
    _debug("getWords() received '$line'") if ($debug);
    my @words = ();

    #  print "getWords('$line')\n";
    if (!$filter) {
        #    print "not using custom filter\n";
        @words = split /\s/, $line;
    } else {
        #    print "using custom filter, min word size = 4\n";
        @words = $line =~ /\s*([\w\-\d\(\)\+\/\.]{4,})[\,\s\-]*/g;

        #     if (scalar(@words) <= 1) {
        #       print "too few words, use custom filter min word size = 4\n";
        push(@words,$line =~ /\s*([\w\-\d\(\)\+\/\.]+\s[\w\-\d\(\)\+\/\.]+)[\,\s\-]*/g);
        #       push(@words,$line =~ /\s*(([\w\-\d\(\)\+\/\.]+[\s\b]){2,4})[\,\s\-]*/g);
        #     }
        map { s/[()]//g } @words;
        #    foreach my $word (@words) {
        #      print "word:  '$word'\n";
        #    }
    }
    _debug("getWords() returning '@words'") if ($debug);
    return @words
}

sub uniqueWords {		##  Tallies and scores each "word"

  my $unique = shift;		# a hash reference
  my $words = shift;		# an array reference
  my $toolScore = shift;
  $toolScore = 1 unless ($toolScore);

  foreach my $word (@$words) {
    #    print "tallying '$word'\n";
    #
    # Don't count low information content words
    #
    #    next if ($word =~ /protein/i);
    next if ($word eq 'protein');
    #    next if ($word =~ /family/i);
    next if ($word eq 'family');
    #    next if ($word =~ /strain/i);
    next if ($word eq 'strain');
    #    next if ($word =~ /imported/i);
    next if ($word eq 'imported');
    #    next if ($word =~ /subsp/i);
    next if ($word eq 'subsp');
    #    next if ($word =~ /function/i);
    next if ($word eq 'function');
    #    next if ($word =~ /probable/i);
    next if ($word eq 'probable');
    next if ($word eq 'homolog');
    next if ($word eq 'putative');
    next if ($word eq 'domain');
    #     next if ($word =~ /homolog/i);
    #     next if ($word =~ /putative/i);
    #    $unique->{$word} += $toolScore;
    #    ++$unique->{$word}; ## original
    #    print "\$word = '$word'\n";
    #    print "'$word' has passed all tests, adding to tally\n";
    ++$unique->{$word}->{tally};
    $unique->{$word}->{score} += $toolScore;
    push(@{$unique->{$word}->{scores}},$toolScore);
  }
  return ($unique);
}

sub sort_by_value {
  my $hashref = shift;

  my @sorted = sort {$hashref->{$b}->{score} <=> $hashref->{$a}->{score}} keys %$hashref;
  return [@sorted];
}

sub printHash {	       # prints the top X% words from the sorted array
  my $arrayref = shift;
  my $hashref = shift;
  my $cutoff = shift; # this is a value like '0.3', which would print the top 30% most frequent words
  $cutoff = 1 unless ($cutoff && $cutoff >= 1);

  my $cnt = 0;
  foreach my $key (@$arrayref) {
    #    print "cnt = $cnt, cutoff = $cutoff\n";
    last if (++$cnt > $cutoff);
    print "'$key', score: $hashref->{$key}->{score}, count: $hashref->{$key}->{tally}\n";
  }
}

sub mostFrequent { ## this was previously used to determine EC number, but the newer ECscore() method replaces that function
  my $hashref = shift;
  my $sorted = sort_by_value($hashref);
  #  print "mostFrequent called\n";
  printHash($sorted,$hashref,5) if ($verbose);

  if ($sorted && ref($sorted) eq 'ARRAY') {
    return $sorted->[0];
  } else {
    return undef;
  }
}

sub getEC {
  my $description = shift;
  my $tool_description = shift;
  my @EC;
#  print "description: '$description'\n";
  #  @EC = $description =~ /\(EC\s([\d\.\-]+)\)/g;

  if (!$tool_description || $tool_description =~ /swiss/i) {
    #@EC = $description =~ /\(EC\s([\d\.\-]+)\)/g;
    @EC = $description =~ /\sEC[\s\=]([\d\.\-]+);/g;
  } elsif ($tool_description =~ /kegg/i) {
    @EC = $description =~ /\[EC\:([\d\.\-\s]+)\s*\]/g;
  }

#  print "\n\n\ngetEC() is returning these potential EC numbers: '@EC'\n\n\n" if (scalar(@EC));
  return @EC;
}

sub ECscore {
  my $EC = shift;
  my $scores = shift;
  my $best_hit_score = shift;
  my $min = 0.05;
  my $min_hits = 10;
  my $num_scores = scalar(@$scores);
  my $min_score = 0.6 * $best_hit_score;
  my $stat = Statistics::Descriptive::Full->new();

  my @best = (0,'');
  print "\n\nECscore()\n" if ($verbose);
  print "scores: $num_scores\n" if ($verbose);
  print "best hit score: $best_hit_score\n" if ($verbose);
  print "minimum acceptable score = $min_score\n" if ($verbose);

  foreach my $ec (keys %$EC) {

    if ($opt_R) {
      my @ec_scores =  sort { $b <=> $a } @{$EC->{$ec}->{scores}};
      my $best_score_ec = $ec_scores[0];
      print "\nbest score for $ec = $best_score_ec\n" if ($verbose);

      if ($best_score_ec < $min_score) {
	print "best hit score for $ec = $best_score_ec, which is too low (min = $min_score)\n" if ($verbose);
	next;
      }
      my ($ec_total,$ec_avg,$ec_slice) = sum_slice(\@ec_scores,$min_score);

      print "$ec total = $ec_total\n" if ($verbose);
      $EC->{$ec}->{score} = $ec_total;

#       print "\n\nnew stats\n";

#       $stat->add_data($ec_slice);
#      print "stat sum = ", $stat->sum(), "\n";
#       print "number of scores: ", $stat->count(), "\n";
#       my $mean = $stat->mean();
#       my $trimmed_mean = $stat->trimmed_mean(0.6,0);
#       my $geom_mean = $stat->geometric_mean();
#       my $harm_mean = $stat->harmonic_mean();
#       my $median = $stat->median();
#       print "mean = $mean\ntrimmed mean = $trimmed_mean\ngeometric mean = $geom_mean\nharmonic mean = $harm_mean\nmedian = $median\n";
#       print "\n\n";
    }

    my $tempScore = $EC->{$ec}->{score};

    my @spc = $ec =~ /(\d+)/g;
#    print "ec: $ec\n" if ($verbose);
    if (scalar(@spc) >= 4) {
      print "specific ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($verbose);
      $tempScore .= 3;
      #      print "$tempScore]\n";
    } elsif (scalar(@spc) == 3) {
      print "semi-specific ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($verbose);
      $tempScore .= 1.5;
    } else {
      print "nonspecific  ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($verbose);
    }
#    $tempScore = $tempScore / $EC->{$ec}->{tally};

    print "$tempScore]\n\n" if ($verbose);
    #    $tempScore = $EC->{$ec}->{score} / $EC->{$ec}->{tally};
    if ($tempScore && $tempScore > $best[0]) {
      @best = ($tempScore, $ec);
    }
  }
  return \@best;
}

sub bestHit { # arguments should be 2 hash references and the computed EC number
  my $factDB = shift;
  my $data = shift;		## ref to %toolData
  my $EC = shift;
  my $maxScore = shift;
  my ($bestScore,$bestData,$scoredata_value,$best_scoredata_value,@scores) = (0,[]);
  my $minScore = int($maxScore - $maxScore * 0.3);
  #  my $stat = Statistics::Descriptive::Full->new();
  
  foreach my $factID (keys %$data) {
    print "\n\nfact # $factID score = ", $data->{$factID}->[0], ", E = ", $data->{$factID}->[1], "\n" if ($debug);

    my $score = 0;
    #    if ($data->{$factID}->[0] < $minScore) {
    #      next;
    #    }

    $score = scoreData($data->{$factID}->[2],$factDB,$EC); # + $data->{$factID}->[0];
    $score = 1 unless ($score);
    $scoredata_value = $score;
    print "\$score = '$score'\n" if ($debug);
    #    $score = log($score + 2.7183**$data->{$factID}->[0]); # add tool score
    $score = $score + sqrt(2.7183**(0.1 * $data->{$factID}->[0])); # add tool score
    #    $score = $score + sqrt(2.7183**$data->{$factID}->[0]); # add tool score
    #    $score += log(2.7183**$data->{$factID}->[0]); # add tool score
    #    $score = log((2.7183**$data->{$factID}->[0]) * $score); # add tool score

    #    $score = log($score);

    print "tool score = " . $data->{$factID}->[0] . ", E = " . $data->{$factID}->[1] . ":  $score:'" . $data->{$factID}->[2] . "'\n" if ($debug);
    push(@scores,$score);
    next unless ($score);


    if ($score > $bestScore) {
      $bestScore = $score;
      $bestData = $data->{$factID};
      $best_scoredata_value = $scoredata_value;
    }

  }				## end of foreach factID
  #    $stat->add_data(@scores);
  #    if ($stat->count() && $stat->count() > 1) {
  #    $stat->sort_data();
  #    my $mean = $stat->mean();
  #    my $sd = $stat->standard_deviation();
  #    my $count = $stat->count();
  #    foreach my $pt ($stat->get_data()) {
  #      my $t = ($pt - $mean) / $sd;
  #      my $tprob = Statistics::Distributions::tprob(($count - 1),$t);
  #      print "t-test for '$pt': t = $t, tprob = $tprob\n";
  #    }
  #  }

  return ($bestData,$bestScore,$best_scoredata_value,\@scores);
}

sub sum_slice {
  my $array = shift;
  my $min = shift;
  my ($total,$cnt,@slice) = (0,0);
  foreach my $val (@$array) {
    if ($val > $min) {
      $total += $val;
      ++$cnt;
      push(@slice,$val);
    }
  }
  if ($cnt) {
    return ($total, $total/$cnt, \@slice);
#    return $total/$cnt;
  } else {
    return 0;
  }
}

sub scoreData {
  my $description = shift;	# a text string
  my $factDB = shift;		# a hash ref 
  my $EC = shift;		# the most frequent EC number
  my ($uniqueWords,$totalScore) = ();
  
  my @words = getWords($description);
  $uniqueWords = uniqueWords($uniqueWords,\@words); # return value will be a hash ref
  my @uniqueWords = keys %$uniqueWords;
  push(@uniqueWords,$description) unless (scalar(@uniqueWords));
  
  foreach my $word (@uniqueWords) {
    #    print "word: '$word', tally: ", $factDB->{$word}->{tally}, ", score: ", $factDB->{$word}->{score}, "\n";
    #    $totalScore += int(eval { $factDB->{$word}->{score} ? $factDB->{$word}->{score} : 0 } / $factDB->{$word}->{tally});
    $totalScore += $factDB->{$word}->{tally} if ($factDB->{$word}->{tally});
    #    $totalScore = $totalScore / $factDB->{$word}->{tally};
  }

  #   if ($EC && $description =~ /\Q$EC/) {
  #     $totalScore *= 1.2;
  #   }
  return $totalScore;
}

sub _help {
  my $usage = shift;
  $usage = "$0" unless ($usage);

  my $HELP = <<HELP;

$usage

This is a perl script that attempts to assign
functional information to every ORF in a genDB database.
Previous to running this script all of the necessary
database/motif-searching programs should be run.

Command line options:

-h\tPrint this help menu
-p\tName of GenDB project (required)
-o\tName of specific ORF to annotate
-O\tAnnotate all ORFs
-d\tDebugging output to terminal
-T\tWhen finished, print number of ORFs annotated
-v\tVerbose output to terminal
-z\tTesting mode: don't actually add anything to GenDB database
-A\tforce annotation even if ORF status is "ignored"
-b\tMinimum tool score for annotation to be considered (default = 1e-06)
-f\tUse custom algorithm for word searhces (default and highly recommended)
-D\tUse distribution statistics for final annotation call (recommended)
-g\tName genes after this organism's gene names, if possible (default [-g t] = E. coli)
\tYou can provide multiple species; separate with commas, enclose whole list in quotes
\tTo use Escherichia coli, use -g t
\tTo avoid naming genes, don't use -g
-G\tName genes after best hit, if available
-c\t% of unique words to print in verbose mode (has no affect on anything else)
-t\tPrint list of tools available for project
-a\tID of tool to use for annotation (comma-separated list)
-I\tCreate new index of SwissProt database (otherwise uses a previously-created index)
-i\tCreate new index of KEGG database (otherwise uses a previously-created index)
-l\tMinimum overlap length between gene/protein and database hit.  Default = 0.65 (65%)
-F\tSend output to this file
-r\tAnnotation addition behavior (default = 0)
\t\t0: default behavior - if possible, add annotation to all ORFs except those that are "ignored"
\t\t1: only add annotation to ORFs that aren't "finished"
\t\t2: only add annotation if no auto-annotations already exist
-E\tIf ORF already has an EC number, don't change the EC number
-R\tWhen EC number isn't found first round, use a conservative algorithm to find EC (recommended)
-e\tExclude database hits from this organism (only works with KEGG hits)
-C\tAnnotate the ORFs on this contig (by name, ie; C4)
-S\tUse SOAP interface to KEGG database (experimental)
-X\tinvoke typical set of options
\t\tequivalent to -G -v -D -T -R -F annotator.out -O -g T
\t\tthese values supercede any options given on command-line
\t\tstill must provide -p and -a values


HELP

  print $HELP;

}

sub _test { ## internal method to test interactions betw Bio::DB::Flat and Bio::Seq::RichSeq
  my $seqID = shift;
  $seqID = 'YCJD_ECOLI' unless ($seqID);
  print "_test called with seqID = '$seqID'\n";
  my $index_dir = "/home/cgrb/givans/lib/annotator/indices";
  my $write_flag = 0;
  
  my $toolDB = Bio::DB::Flat->new(
                                  -directory  =>  $index_dir,
                                  -dbname     =>  'sprot.idx',
                                  -format     =>  'swiss',
                                  -write_flag =>  $write_flag,
                                  -index	   =>	'bdb',
				 );
  $toolDB->build_index('/dbase/scratch/swiss/sprot.dat') if ($write_flag);
  
  
  my $seq = $toolDB->get_Seq_by_id($seqID);
  print "\$seq is a ", ref($seq), "\n";
  print "seq id:\t", $seq->id(), "\n";
  print "seq name:\t", $seq->display_name(), "\n";
  
  print "seq binomial:\t", $seq->species()->binomial(), "\n";
  
  my $ac = $seq->annotation();
  print "\$ac is a ", ref($ac), "\n";
  my @geneName = $ac->get_Annotations('gene_name');
  print "geneName: '", scalar(@geneName), "'\n";
  my $tmpName = $geneName[0]->as_text();
  $tmpName =~ s/Value:\s//;
  print "adding potential name: '$tmpName'\n";
  
  
  print "gene name:\t'", $geneName[0]->as_text(), "'\n"; 
}

sub _debug {
  my $mssg = shift;
  print "DEBUG [" . (caller())[2] . "]:\t$mssg\n";
}

sub kdump {
  my $ref = shift;
  return unless ($ref);
  my $type = ref($ref);
  print "KDUMP:\n";
  if ($type && $type eq 'HASH') {
    foreach my $key (keys %$ref) {
      print "\tkey: '$key'; value: '" . $ref->{$key} . "'\n";
    }
  } elsif ($type && $type eq 'ARRAY') {
    foreach my $el (@$ref) {
      kdump($el);
      #      print "array element: '$el'\n";
    }
  } elsif ($type) {
    print "\tpassed argument is a '$type'\n";
  } else {
    print "\tpassed argument is not a reference\n";
  }
}
