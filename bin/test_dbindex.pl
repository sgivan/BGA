#!/usr/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;    # Automatically throw fatal exceptions for common unrecoverable
                #   errors (e.g. trying to open a non-existent file)
use Getopt::Long;
use Bio::DB::Flat;
my $index_dir = "/home/cgrb/givans/lib/annotator/indices";

my $write_flag = 0;

my $toolDB = Bio::DB::Flat->new(
			 -directory  =>  $index_dir,
			 -dbname     =>  'sprot.idx',
			 -format     =>  'swiss',
			 -write_flag =>  $write_flag,
			 #			       -index      =>  'binarysearch',
			 -index	   =>	'bdb',
			);

say "\$toolDB isa '" . ref($toolDB) . "'";

#my $seq_id = 'Q8FVU9';
my $seq_id = shift;
$seq_id = 'Q8FVU9' unless ($seq_id);

my $seq;
say "fetching sequence '$seq_id'";
#
# get seq by id
#
#say "fetching seq by id";
if ($seq = $toolDB->get_Seq_by_id($seq_id)) {

    say "\$seq ($seq) isa '" . ref($seq) . "'";

#
# get seq by acc
#
} elsif ($seq = $toolDB->get_Seq_by_acc($seq_id)) {

    say "\$seq isa '" . ref($seq) . "'";
}
#
# check seq object
#
if ($seq->isa('Bio::Seq')) {
    say "\$seq enherits from 'Bio::Seq' object";
} else {
    say "\$seq does not enherit from 'Bio::Seq'";
}

say "keywords: '" . $seq->keywords() . "'";
say "description: '" . $seq->description() . "'";

my $ac = $seq->annotation();

say "\$ac isa '" . ref($ac) . "'";

foreach my $key ( $ac->get_all_annotation_keys() ) {
   my @values = $ac->get_Annotations($key);
   foreach my $value ( @values ) {
      # value is an Bio::AnnotationI, and defines a "as_text" method
      print "Annotation ",$key," stringified value ",$value->as_text,"\n";

      # also defined hash_tree method, which allows data orientated
      # access into this object
      my $hash = $value->hash_tree();
   }
}

say "Getting EC number";
if ($seq->description() && $seq->description() =~ /EC\=(.+?)\s/) {
    my $EC = $1;
    say "EC=$EC";
}

