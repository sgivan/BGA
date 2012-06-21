package BGA::Util;

use 5.010;
use Moose;
use autodie;
use strict;

# the following variables were originally defined in annotator.pl
# I've redefined them here for convenience

has 'debug' => (
    is      =>  'rw',
    isa     =>  'Int',
    default =>  0,
);

has 'filter'    =>  (
    is      =>  'rw',
    isa     =>  'Int',
    default =>  0,
);

has 'verbose'   =>  (
    is          =>  'rw',
    isa         =>  'Int',
    default     =>  0,
);

has 'coverage'    =>  (
    is          =>  'rw',
    isa         =>  'Num',
    default     =>  0.65,
);

has 'evalue'    =>  (
    is          =>  'rw',
    isa         =>  'Num',
    default     =>  1e-6,
);

has 'maxScore'   => (
    is          =>  'rw',
    isa         =>  'Num',
    default     =>  0,
);

has '_joined_titles'    => (
    is          =>  'rw',
    isa         =>  'Str',
);

has 'query_id'      =>  (
    is          =>  'rw',
    isa         =>  'Str',
);
    
my $opt_R = 1;
# I don't think I need to provide any access to these hashes, so define them locally:
my %toolData = ();
my %factDB = ();

1;

# getWords() extracts "words" from a description line
sub getWords {			# returns an array of 'words'
    my $self = shift;
    my $line = shift;
    $self->_debug("getWords() received '$line'") if ($self->debug);
    my @words = ();

    #  print "getWords('$line')\n";
    if (!$self->filter) {
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
    $self->_debug("getWords() returning '@words'") if ($self->debug);
    return @words
}

sub uniqueWords {		##  Tallies and scores each "word"
    my $self = shift;
    my $unique = shift;		# a hash reference
                            # hash ref will be modified and returned
    my $words = shift;		# an array reference
    my $toolScore = shift;
    $toolScore = 1 unless ($toolScore);

    foreach my $word (@$words) {
        #
        # Don't count low information content words
        #
        next if ($word eq 'protein');
        next if ($word eq 'family');
        next if ($word eq 'strain');
        next if ($word eq 'imported');
        next if ($word eq 'subsp');
        next if ($word eq 'function');
        next if ($word eq 'probable');
        next if ($word eq 'homolog');
        next if ($word eq 'putative');
        next if ($word eq 'domain');

        ++$unique->{$word}->{tally};
        $unique->{$word}->{score} += $toolScore;
        push(@{$unique->{$word}->{scores}},$toolScore);
    }
    return ($unique);
}

# sub sort_by_value sorts a hash by the "score" attribute 
# returns an array reference
sub sort_by_value {
    my $self = shift;
    my $hashref = shift;

    my @sorted = sort {$hashref->{$b}->{score} <=> $hashref->{$a}->{score}} keys %$hashref;
    return [@sorted];
}

sub printHash {	       # prints the top X% words from the sorted array
    my $self = shift;
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

sub getEC {
    my $self = shift;
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
    my $self = shift;
    my $EC = shift;
    my $scores = shift;
    my $best_hit_score = shift;
    my $min = 0.05;
    my $min_hits = 10;
    my $num_scores = scalar(@$scores);
    my $min_score = 0.6 * $best_hit_score;
    my $stat = Statistics::Descriptive::Full->new();

    my @best = (0,'');
    print "\n\nECscore()\n" if ($self->verbose);
    print "scores: $num_scores\n" if ($self->verbose);
    print "best hit score: $best_hit_score\n" if ($self->verbose);
    print "minimum acceptable score = $min_score\n" if ($self->verbose);

    foreach my $ec (keys %$EC) {

        if ($opt_R) {
        my @ec_scores =  sort { $b <=> $a } @{$EC->{$ec}->{scores}};
        my $best_score_ec = $ec_scores[0];
        print "\nbest score for $ec = $best_score_ec\n" if ($self->verbose);

        if ($best_score_ec < $min_score) {
        print "best hit score for $ec = $best_score_ec, which is too low (min = $min_score)\n" if ($self->verbose);
        next;
        }
        my ($ec_total,$ec_avg,$ec_slice) = $self->sum_slice(\@ec_scores,$min_score);

        print "$ec total = $ec_total\n" if ($self->verbose);
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
    #    print "ec: $ec\n" if ($self->verbose);
        if (scalar(@spc) >= 4) {
        print "specific ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($self->verbose);
        $tempScore .= 3;
        #      print "$tempScore]\n";
        } elsif (scalar(@spc) == 3) {
        print "semi-specific ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($self->verbose);
        $tempScore .= 1.5;
        } else {
        print "nonspecific  ec: $ec [score:" . $EC->{$ec}->{score} . ", tally:" . $EC->{$ec}->{tally} . ", total: " if ($self->verbose);
        }
    #    $tempScore = $tempScore / $EC->{$ec}->{tally};

        print "$tempScore]\n\n" if ($self->verbose);
        #    $tempScore = $EC->{$ec}->{score} / $EC->{$ec}->{tally};
        if ($tempScore && $tempScore > $best[0]) {
        @best = ($tempScore, $ec);
        }
    }
    return \@best;
}

sub bestHit { # arguments should be 2 hash references and the computed EC number
    # bestHit() returns a reference to an array:
    #  [0] tool score
    #  [1] tool E-value
    #  [2] hit description
    #  [3] ID of hit from it's particular database
    #  [4] Bio::Seq or Bio::PrimarySeq object containing the hit sequence

    my $self = shift;
    my $factDB = \%factDB; # this is the hash populated by uniqueWords subroutine
    my $data = \%toolData; # ref to %toolData
    # $toolData{$factID} = [$toolScore, $toolE, $description, $dbRef]
    #my $EC = shift;
    #my $maxScore = shift;

    my ($bestScore,$bestData,$scoredata_value,$best_scoredata_value,@scores) = (0,[]);
    my $minScore = int($self->maxScore - ($self->maxScore * 0.3));
    
    foreach my $factID (keys %$data) {
        print "\n\nfact # $factID score = ", $data->{$factID}->[0], ", E = ", $data->{$factID}->[1], "\n" if ($self->debug);
        my $joined_title = $data->{$factID}->[2];
        my @titles = $self->split_titles();
        my $first_title = $titles[0];
        print "will use '$first_title' description" if ($self->debug);

        my $score = 0;

        $score = $self->scoreData($first_title,$factDB); # + $data->{$factID}->[0];
        $score = 1 unless ($score);
        $scoredata_value = $score;
        $score = $score + sqrt(2.7183**(0.1 * $data->{$factID}->[0])); # add tool score

        print "tool score = " . $data->{$factID}->[0] . ", E = " . $data->{$factID}->[1] . ":  $score:'" . $data->{$factID}->[2] . "'\n" if ($self->debug);
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
    my $self = shift;
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
    my $self = shift;
    my $description = shift;	# a text string
    my $factDB = shift;		# a hash ref 
    #my $EC = shift;		# the most frequent EC number
    my ($uniqueWords,$totalScore) = ();
    
    my @words = $self->getWords($description);
    $uniqueWords = $self->uniqueWords($uniqueWords,\@words); # return value will be a hash ref
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

sub _debug {
    my $self = shift;
    my $mssg = shift;
    print "DEBUG [" . (caller())[2] . "]:\t$mssg\n";
}

sub get_title {
    my $self = shift;
    my $db = shift;
    my $subid = shift;
    my $cmd = "blastdbcmd -db $db -entry '$subid' -outfmt %t";

    open(my $CMD,'-|',$cmd);
    chomp(my @rtn = <$CMD>);

    return @rtn;
}

sub joined_title {
    my $self = shift;
    my $db = shift;
    my $subid = shift;
    my @titles = $self->get_title($db,$subid);
    #my $titles = join ",", @titles;
    my $titles = join "!!", @titles;

    $self->_joined_titles($titles);
    return $titles;
}

sub split_titles {
    my $self = shift;
    my @titles = ();

    @titles = split /!!/, $self->_joined_titles();
    return @titles;
}

sub calc_coverage {
    my $self = shift;
    my $start = shift; 
    my $stop = shift;
    my $totlen = shift;

    my $coverage = (int(abs($start - $stop))) / $totlen;

    print "coverage: '$coverage'\n" if ($self->debug);
    return $coverage;
}

sub coverage_pass {
    my $self = shift;
    my $relspan = shift;
    my $rtn = -1;

    if ($relspan >= $self->coverage) {
        $rtn = 1;
    }

    return $rtn;
}

sub check_query_coverage {
    my $self = shift;
    my $hr = shift;
#    my $qstart = shift;
#    my $qstop = shift;
#    my $qlength = shift;

    #return $self->coverage_pass($self->calc_coverage($qstart,$qstop,$qlength));
    return $self->coverage_pass($self->calc_coverage($hr->{qstart},$hr->{qend},$hr->{qlen}));
}


sub read_blast_tabline {
    my $self = shift;
    my $line = shift;

    chomp($line);
    #my @vals = map { s/\s//g; } split /\t/, $line;
    my @vals = split /\t/, $line;
    # format of default blast tab line:
    # $qid,$sid,$pident,$alength,$mismatches,$gapopens,$qstart,$qend,$sstart,$send,$evalue,$bitscore

    return \@vals;
}

sub readHit {
    my $self = shift;
    my $line = shift;
    my %rslt = ();

    my $tabvals = $self->read_blast_tabline($line);
    # the last two values require the -outfmt '6 std qlen slen' argument to blast
    ($rslt{qid},$rslt{sid},$rslt{pident},$rslt{alength},$rslt{mismatches},$rslt{gapopens},$rslt{qstart},$rslt{qend},$rslt{sstart},$rslt{send},$rslt{evalue},$rslt{bitscore},$rslt{qlen},$rslt{slen}) = @$tabvals;
    $rslt{bitscore} =~ s/\s//g;

    return \%rslt;
}

sub parse_report {
    my $self = shift;
    my $file = shift;

    open(my $IN,'<',$file);

    my $cnt = 0;
    while (<$IN>) {
        next if (substr($_,0,1) eq '#');
        my $hit = $self->readHit($_);
        # the last two values require the -outfmt '6 std qlen slen' argument to blast
        #my ($qid,$sid,$pident,$alength,$mismatches,$gapopens,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$qlen,$slen) = @$tabvals;
        next if ($self->check_query_coverage($hit) < 0);
        next if ($hit->{evalue} > $self->evalue);
        ++$cnt;
        $hit->{title} = $self->joined_title('NR/nr',$hit->{sid});
        $toolData{++$cnt} = [$hit->{bitscore}, $hit->{evalue}, $hit->{title}, $hit->{sid}, $hit->{qid}];# not sure if I need this - only exists on 2 lines
        $self->query_id($hit->{qid}) if ($cnt == 1);

        my @words = $self->getWords($hit->{title}); # extract all "words" from hit title
        $self->uniqueWords(\%factDB,\@words,$hit->{bitscore}); # identify and tally unique words
    }
    $self->find_maxScore();
}

sub find_maxScore {
    my $self = shift;
    my $maxScore = 0;
    foreach my $tool_data (values %toolData) {
        $maxScore = $tool_data->[0] if ($tool_data->[0] > $maxScore);
    }
    $self->maxScore($maxScore);
    say "returning max score = '$maxScore'" if ($self->debug);
    return $maxScore;
}

