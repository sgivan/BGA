#!/bin/env perl

use 5.010;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use Getopt::Long; # use GetOptions function to for CL args

use Bio::Tools::GFF;

my ($debug,$help,$verbose,$infile,$outfile,$in_gff_version,$out_gff_version,$remove_extra_tags,$separate_chroms);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "help"      =>  \$help,
    "verbose"   =>  \$verbose,
    "sepchroms" =>  \$separate_chroms,
    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "out-gff:i"     =>  \$out_gff_version,
    "in-gff:i"     =>  \$in_gff_version,
    "remove"    =>  \$remove_extra_tags,
);

if ($help) {

say <<END
This script was developed to convert a GFF2-ish file,
created with makeGFF.pl (part of the BGA suite), 
into a GFF3 file to load into a gbrowse SQL database
using db_seqfeature_load.pl.

    "debug"     =>  debugging mode
    "help"      =>  print this help menu
    "verbose"   =>  verbose output to stdout
    "sepchroms" =>  generate separate file for chromosomes
    "infile:s"  =>  input file name
    "outfile:s" =>  outfile file name
    "out-gff:i"     => output GFF version (default = 3)
    "in-gff:i"     =>  input GFF version (use 2 for makeGFF.pl file)
    "remove"    =>  removes extra tags in col 9 

END

}
exit if ($help);

if ($debug) {

say "
debug   =   '$debug'
help    =   '$help'
verbose =   '$verbose'
infile  =   '$infile'
outfile =   '$outfile'
out-gff =   '$out_gff_version'
in-gff  =   '$in_gff_version'
";

};

# provide some sensible defaults

$infile ||= 'infile';
$outfile ||= 'outfile';
$out_gff_version ||= 3;
$in_gff_version ||= 2;# usually the right choice
$verbose = 1 if ($debug);
my $chromfilename = $outfile . ".chroms" if ($separate_chroms);

my $dbin = Bio::Tools::GFF->new(-file => $infile, -gff_version => $in_gff_version) or die "can't open '$infile': $!";
my $dbout = Bio::Tools::GFF->new(-file => ">$outfile", -gff_version => $out_gff_version) or die "can't open '$outfile': $!";
my $chromfile;
if ($separate_chroms) {
    #open(my $chromfile,'>',$chromfilename) if ($separate_chroms);
    open($chromfile,'>',$chromfilename);
    say $chromfile "##gff-version 3";
}

#$dbin->features_attached_to_seqs(1);

while (my $f = $dbin->next_feature()) {
    if ($debug) {
        say "\n",$f->gff_string();
        say "\$f isa '", ref($f), "'";
        say "seq_id = '", $f->seq_id(), "'";
        say "display_name = '", $f->display_name(), "'" if ($f->display_name());
    }
    my @tags = $f->get_all_tags();
    say "# of tags: '", scalar(@tags), "'" if ($debug);
    for my $tag (sort {$b cmp $a} @tags) {# this ensures that Note comes before Description, otherwise Note is lost
        say "\t\$tag = '$tag'" if ($debug);
        # deal with Chromosome
        if ($tag eq 'Chromosome') {
            if ($separate_chroms) {
                say $chromfile "##sequence-region " . $f->seq_id() . "\t1\t" . $f->end();

            } else {
                $f->add_tag_value('ID',$f->get_tag_values('Chromosome'));
                $f->add_tag_value('Name',$f->get_tag_values('Chromosome'));
                $f->remove_tag('Chromosome');
            }
        }
        # convert Orf to ID
        if ($tag eq 'Orf') {
            $f->add_tag_value('ID',$f->get_tag_values('Orf'));
            $f->remove_tag('Orf');
        }
        # convert Note to Name
        if ($tag eq 'Note') {
            $f->add_tag_value('Name',$f->get_tag_values('Note'));
            $f->remove_tag('Note');
        }
        # convert Description to Note
        if ($tag eq 'Description') {
#            if ($f->get_tag_values('Description') ne '.') {
#                $f->add_tag_value('Note',$f->get_tag_values('Description'));
#            } else {
#                $f->remove_tag('Note');
#            }
            $f->add_tag_value('Note',$f->get_tag_values('Description')) unless (length(($f->get_tag_values('Description'))[0]) <= 1);
            $f->remove_tag('Description');
        }
    }
    if ($remove_extra_tags) {
        $f->remove_tag('EC') if ($f->has_tag('EC'));
        $f->remove_tag('Funcat') if ($f->has_tag('Funcat'));
    }
    $dbout->write_feature($f);
}


