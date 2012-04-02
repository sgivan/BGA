package GENDB::Tools::tRNAScan;

########################################################################
#
# This module provides methods to parse tRNAScan results and create
# "ORFs" for GENDB 1. 
#
# CONSIDER IT A MEAN, DIRTY HACK !

# $Id: tRNAScan.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: tRNAScan.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
    
use GENDB::contig;
use GENDB::orf;
use GENDB::annotator;
use GENDB::annotation;
use GENDB::feature_type;
use GENDB::Common qw(create_fasta_file remove_dir);
use GENDB::GENDB_CONFIG;
use Carp qw(croak);
use strict;
use POSIX qw(tmpnam);

my $debug = 0;

1;

	
# the annotator name for this importer
sub annotator_name {
    #return "tRNAScan Predictor";
    return "tRNAscan-SE";
}

# helper for creating and retrieving the annotator 
# object of this module
sub _get_annotator {
    my $annotator = GENDB::annotator->init_name(&annotator_name);
    if ($annotator == -1) {
        $annotator = GENDB::annotator->create();
        $annotator->name(&annotator_name);
        $annotator->description('tRNAScan-SE trna prediction');
    }
    return $annotator;
}

# read the file (arg 1) and insert observations in db for region arg2
sub _parse_trnascan{

    my ($resultfile,$contig) = @_; 
    my $counter = 0;
    #$file = '/homes/fm//work/sample.trnascan';
    open (OUTPUT, "$resultfile") || croak "Can't open file $resultfile";
    my ($rnanr,$start,$stop,$tRNAtype,$anticodon,$score);
    my $annotator=_get_annotator;
    my $trna_feature = GENDB::feature_type->init_by_feature_name('tRNA');
    while (<OUTPUT>) {
        chomp;
        if (/^\S+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\w+)\s+(\w+)\s+\S+\s+\S+\s+([0123456789.]+)/) {
            ($rnanr,$start,$stop,$tRNAtype,$anticodon,$score) = ($1, $2, $3, $4, $5, $6);  
            my $orf;
            if ($start < $stop) {
                $orf = GENDB::orf->create($contig->id, $start, $stop, 
                              sprintf ("C%d_tRNA_f_%d (AA: %s, Cod: %s)",
                                   $contig->id,$counter,
                                   $tRNAtype, $anticodon));
            } else {
                $orf = GENDB::orf->create($contig->id, $stop, $start,
                              sprintf ("C%d_tRNA_r_%d (AA: %s, Cod: %s)",
                                   $contig->id,$counter,
                                   $tRNAtype, $anticodon));
            }
            if ($debug) {
                print "\$orf isa '", ref($orf), "'\n";
                print "orf id: '", $orf->id(), "'\n";
                print "contig id: '", $contig->id(), "'\t";
                print "start: '$start'; stop: '$stop'\n";
            }
            $counter++;
            $orf->frame(0);
            $orf->startcodon("");
            $orf->status($ORF_STATE_ANNOTATED);

            print "write an annotation for the trna\n" if ($debug);
            my $annotation=GENDB::annotation->create(sprintf ("tRNA, AA:%s, Anticodon:%s",
                                      $tRNAtype,
                                      $anticodon), 
                                 $orf->id);
            $annotation->date(time());
            $annotation->annotator_id($annotator->id);
            $annotation->feature_type($trna_feature->id);
        } else {
            warn("parse_trnascan can't parse this line:\n'$_'\n") if ($debug);
        }
    }

}

#########################################
# compute tRNAscan result for given region 
# store in file and return tmpfilename
sub run_on_contig{
    
    my ($contig) = @_;
    
    # avoid creating redundant data.. was this tool already run on this region ?
    if (&check_for_trnas($contig)) {
	printf STDERR "skipping contig %s, since ORF(s) with frame 0 do exists\n",$contig->name;
	return;
    }

    # the filenames to use
    my $contigfile    = tmpnam();
    my $outfile       = tmpnam();

    # create a sequence file in FASTA format for region prediction
    create_fasta_file($contigfile, $contig->name, $contig->sequence);

    # create the command line
    # assume bacteria (-B)
    # be quiet (-q)
    my $cmdline = "$GENDB_TRNASCANSE -B -q $contigfile > $outfile";
    print "tRNAscan cmd: '$cmdline'\n";
    system($cmdline);
    
    # call parser
    &_parse_trnascan($outfile,$contig);
    
    # clean up
    unlink $outfile;
    unlink $contigfile;
}

sub check_for_trnas {
    my ($contig) = @_;
    
    my $dummy = GENDB::orf->fetchbySQL(sprintf("contig_id=%d && frame=0",
					       $contig->id));
    return (scalar @$dummy) > 0;
}


sub remove_trnas {
    my ($contig) = @_;
    my $trnas = GENDB::orf->fetchbySQL(sprintf("contig_id=%d && frame=0",
					       $contig->id));
    foreach (@$trnas) {
	$_->delete_complete;
    }
}
