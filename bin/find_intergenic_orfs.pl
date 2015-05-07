#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  find_intergenic_orfs.pl
#
#        USAGE:  ./find_intergenic_orfs.pl  
#
#  DESCRIPTION:  Script to find intergenic ORFs in a bacterial genome. Uses blastx
#                   searches as input.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  10/28/14 16:19:14
#     REVISION:  ---
#===============================================================================

use 5.010;       # use at least perl version 5.10
use strict;
use warnings;
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
#use lib '/ircf/ircfapps/opt/Bioperl/lib/perl5';
use Bio::SearchIO;
use File::Temp qw/ tempfile tempdir /;
use Bio::SearchIO;

my ($debug,$verbose,$help);
my ($infolder,$infile,$outfile,$minE,$min_translated_length,$hmmscan,$minhmmE);

my $result = GetOptions(
    "debug"         =>  \$debug,
    "verbose"       =>  \$verbose,
    "help"          =>  \$help,
    "infolder:s"    =>  \$infolder,
    "infile:s"      =>  \$infile,
    "outfile:s"     =>  \$outfile,
    "minE:f"        =>  \$minE,
    "mtl:i"         =>  \$min_translated_length, # min translated length of hit
    "hmmscan"       =>  \$hmmscan,
    "minhmmE:f"     =>  \$minhmmE,
);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;
   
    debug        
    verbose     
    help       
    infolder:s      name of directory containing blastx files [default = infolder]
    infile:s        name of a single blastx file to parse
    outfile:s       name ouf output file [default = outfile.intergenicORFs.txt]
    minE:f          minimum E value for blastx hit [default = 1e-10]
    mtl:i           min translated length of blastx hit
    hmmscan         do hmmscan search
    minhmmE:f       minimum E value for hmmscan [default = 1e-08]

HELP

}

$infolder = 'infolder' unless ($infolder && !$infile);
$minE = 1e-10 unless ($minE);
$min_translated_length = 66 unless ($min_translated_length);
$minhmmE = 1e-8 unless ($minhmmE);
$outfile = 'outfile.intergenicORFs.txt' unless ($outfile);

open(OUT,">",$outfile);
say OUT "Query\t# of hits\tHit Acc\tE\tQuery Length(nt)\tHit Length(aa)\tQuery Strand\tHit Frame\tHSP Length(aa)\tQuery Start\tQuery End\tQ Align Len\tA Align %\tHSP Seq\tHMM Domain\tHMM E";

my @infiles = ();

if (!$infile) {
    opendir(my $dh, $infolder);
    while (readdir $dh) {
        next unless ($_ =~ /.+\.blastx$/);
        my $infile = $_;
        say "\nfile: '$infile'" if ($debug);
        push(@infiles,"$infolder/$infile");
    }
} else {
    push(@infiles,$infile);
}

my %intergenicORFs = ();
for my $infile (@infiles) {

    my $report = Bio::SearchIO->new(
                                        -file       =>  $infile,
                                        -format     =>  'blast',
                                    );

#    my %intergenicORFs = ();
    while (my $result = $report->next_result()) {
        my $query_name = $result->query_name();
        my ($qstart,$qend,$qlength) = o_gene($result);
        my $num_hits = $result->num_hits();
        next unless ($num_hits);

        if ($debug) {
            say "$infile: query name is '$query_name'";
            say "qstart: '$qstart', qend: '$qend', qlength: '$qlength'";
            say "number of hits in result: '$num_hits'";
        }

        my $hitnum = 0;
        my %hits = ();
        while (my $hit = $result->next_hit()) {

            my @hsps = $hit->hsps();
            last if (scalar(@hsps) == 0);
            next if ($hit->significance > $minE);
            next if ($hit->hsp('best')->length() < $min_translated_length);
            next if $hits{$hit->hsp('best')->seq_str()};
            ++$hits{$hit->hsp('best')->seq_str()};
            ++$hitnum;
            my $h_sig = $hit->significance();
            $h_sig = "1" . "$h_sig" if ($h_sig =~ /^e/); ## sometimes E-value is just ie, e-100.

            #
            # hmmscan section
            # hmmscan searches for domains within the query sequence
            # presence of domain supports that a coding region is present
            #
            my ($hmmscanIO,@hmmscan,$hmmhit) = ();
            if ($hmmscan) {
                my $tmpfile = File::Temp->new( DIR => '.', UNLINK => 1, TEMPLATE => "tmpfileXXXXXXX", SUFFIX => '.fa');
                my $tmpoutfile = File::Temp->new( DIR => '.', UNLINK => 1, TEMPLATE => $tmpfile . "XXXX", SUFFIX => '.hmmscan');
                print $tmpfile ">$tmpfile\n" . $hit->hsp('best')->seq_str() . "\n";
                #open(HMMSCAN,"-|","hmmscan /ircf/dbase/PFAM/Pfam-A $tmpfile");
                open(HMMSCAN,"-|","hmmscan /ircf/dbase/PFAM/Pfam-A $tmpfile > $tmpoutfile");
                @hmmscan = <HMMSCAN>;
                close(HMMSCAN);

                $hmmscanIO = Bio::SearchIO->new(
                                                -format =>  'hmmer',
                                                -file    => $tmpoutfile,
                                            );

                while (my $hmm_rslt = $hmmscanIO->next_result()) {
                    $hmmhit = $hmm_rslt->next_hit();# for this, I only care about the best hit
                    #say "\t" . $hmmhit->name() . "\t" . $hmmhit->significance();
                    last;
                }
            }

            # end of hmmscan section, although some information from the hmmscan section will be used below
            # specifically, $hmmhit->significance()

            if ($debug) {

                print "$hitnum\t" . $hit->accession . "\t" . $hit->description . "\t" . $hit->significance() 
                . "\t$qlength\t" . $hit->logical_length('hit') . "\t" . $hit->strand('query') . "\t" . reading_frame($hit,1) 
                . "\t" . $hit->hsp('best')->length() . "\t" . $hit->hsp('best')->seq_str();
                if (ref($hmmhit)) {
                    if ($hmmhit->significance() < $minhmmE) {
                        print "\t" . $hmmhit->name() . "\t" . $hmmhit->significance();
                    }
                }
                print "\n";

                say @hmmscan if ($hmmscan);
            }
            # if script has progressed to this point:
            #   there is a blastx hit that satisfies criteria
            #   there may be hmmscan data
            #
            # this is all I really care about
            # so, print to output file of potential intergenic coding regions

            $intergenicORFs{$result->query_name()} =
            [$num_hits,$hit->accession,$hit->significance(),$qlength,$hit->logical_length('hit'),$hit->strand('query'),reading_frame($hit,1),$hit->hsp('best')->length(),$hit->hsp('best')->start(),$hit->hsp('best')->end(),$hit->hsp('best')->end()-$hit->hsp('best')->start(),($hit->hsp('best')->end()-$hit->hsp('best')->start())/$qlength,$hit->hsp('best')->seq_str()];

            if (ref($hmmhit)) {
                if ($hmmhit->significance() < $minhmmE) {
                    push(@{$intergenicORFs{$result->query_name()}},($hmmhit->name(),$hmmhit->significance()));
                }
            }
            
            last; 
        }
        say "$hitnum hits E < $minE & mtl > $min_translated_length\n" if ($debug);
    }

}
# print to output file
#
my @output = ();
my ($hits,$E,$qlen,$cnt) = ();
for my $query_name (sort {$a cmp $b} keys %intergenicORFs) {
    ++$cnt;
    say "$query_name, cnt = $cnt" if ($debug);
    if ($cnt > 1) {
        say "comparing '" . $intergenicORFs{$query_name}->[0] . "' to '$hits'" if ($debug);
#        next if ($intergenicORFs{$query_name}->[0] eq $hits && $intergenicORFs{$query_name}->[2] == $E && $intergenicORFs{$query_name}->[3] == $qlen);
        if ($intergenicORFs{$query_name}->[0] eq $hits && $intergenicORFs{$query_name}->[2] == $E && $intergenicORFs{$query_name}->[3] == $qlen) {
            say "looks like the same sequence region -- check strand: '" . $intergenicORFs{$query_name}->[5] . "'" if ($debug);
            if ($intergenicORFs{$query_name}->[5] > 0) {
                pop(@output);
            } else {
                next;
            }
        }
    }

    my $string = join "\t", @{$intergenicORFs{$query_name}};
#    say OUT $query_name . "\t" . $string;
    push(@output,"$query_name\t$string");

    $hits = $intergenicORFs{$query_name}->[0];
    $E = $intergenicORFs{$query_name}->[2];
    $qlen = $intergenicORFs{$query_name}->[3];
}
say OUT map { "$_\n" } @output;

sub o_gene {
  my $result = shift;
  my($start,$end, $descr,$length,$o_length);

  $descr = $result->query_description();
  $length = $result->query_length();

  if ($descr =~ /\[\+\s(\d+)\supstream\s\:\s\+\s(\d+)\sdownstream\]/) {
    $start = $1;
    $end = $length - $1;
  } else {
    $start = 1;
    $end = $length;
  }

  return ($start,$end,$length);
}

sub reading_frame {
    my $hit = shift;
    my $prefix = shift;# prefix with "+" for positive strand
    my $strand = $hit->strand('query');
    my $frame = $hit->hsp()->query()->frame();

    if ($strand > 0) {
        ++$frame;
        $frame = "+" . $frame if ($prefix);
    } elsif ($strand < 0) {
        ++$frame;
        $frame = $frame - 2*$frame;
        #$frame = "-" . $frame;
    } else {
        $frame = 0;
    }

    return $frame;
}
