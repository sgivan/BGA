package SeqDB::EMBL::Entry;

# this package is a generic parser for EMBL formatted
# sequences files
# it parses one single sequence of a multiple EMBL file

# $Id: Entry.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: Entry.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.7  2001/08/01 16:16:46  blinke
# short hack to fix feature locations without qualified ends
#
# Revision 1.6  2001/06/05 12:12:20  blinke
# readded dot at end of id line to regexp (error was due to illegal chop in EMBL.pm)
#
# Revision 1.5  2001/06/05 12:04:37  blinke
# dot at end of id line is optional
#
# Revision 1.4  2001/04/27 12:34:02  blinke
# added code to get sub sequence of a feature
#
# Revision 1.3  2001/04/19 15:09:44  blinke
# corrected regexp in sequence parser
#
# Revision 1.2  2001/04/19 13:20:03  blinke
# fixed requirements
#
# Revision 1.1  2001/04/05 14:52:52  blinke
# Initial revision
#

use IO::File;
use Carp qw (croak);

require SeqDB::EMBL::FeatureTable;

my $fields = { entryname => 1,
	       dataclass => 1,
	       molecule => 1,
	       division => 1,
	       sequencelength => 1,
	       accnumbers => 1,
	       sequence_version => 1,
	       date_lines => 1,
	       description => 1,
	       keywords => 1,
	       organism_species => 1,
	       organism_classifications => 1,
	       organella => 1,
	       references => 1,
	       database_references => 1,
	       featuretable => 1,
	       sequence => 1,
	       comments => 1
	       };

1;

# access entry fields by AUTOLOAD

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if ($method eq 'DESTROY');
    if (defined $fields->{$method}) {
	if ($_[0]) {
	    return $self->{$method}=$_[0];
	}
	return $self->{$method};
    }
    else {
	croak "unknown methods $method in AUTOLOAD";
    }
}

sub new {
    my $class  = shift;
    
    my $self = {};
    bless $self, $class;
    return $self;
}


# main parser table...contains line tags (e.g. "ID") and 
# references to processing sub parser
my $parser_table = { 'ID' => \&parse_id_line,
		     'XX' => sub {},
		     'AC' => \&parse_ac_line,
		     'SV' => sub { $_[0]->{sequence_version} = $_[2];},
		     'DT' => \&parse_dt_line,
		     'DE' => sub { if ($_[0]->{description}) {
			 
			 $_[0]->{description} .= " ".$_[2];
		     }
				   else {
				       $_[0]->{description} = $_[2];
				   }  
			       },
		     'KW' => \&parse_keyword_line,
		     'OS' => sub { $_[0]->{organism_species} = $_[2];},
		     'OC' => \&parse_organism_classification,
		     'OG' => sub { $_[0]->{organella} = $_[2];},
		     'RN' => \&parse_citation,
		     'DR' => \&parse_database_reference,
		     'FH' => \&parse_feature_table,
		     'SQ' => \&parse_sequence,
		     'CC' => sub { push @{$_[0]->{comments}}, $_[2];}};
				   

# main parser loop    
sub parse ($$) {

    my ($self, $reader) = @_;

    while (1) {
	my ($tag, $content) = $reader->next_line =~ /^([A-Z\/][A-Z\/])\s*(.*)$/;
	croak "no blank lines allowed inside entries" if (!$tag);
	if ($parser_table->{$tag}) {
	    &{$parser_table->{$tag}} ($self, $reader, $content);
	}
	elsif ($tag eq "//") {
	    last;
	}
	else {
	    croak "unknown tag '$tag' with content '$content'";
	}
    }
}
	

# parse id line 
# entryname  dataclass; molecule; division; sequencelength BP.
sub parse_id_line ($$) {

    my ($self, $reader, $content) = @_;

    chomp $content;
    ($self->{entryname}, $self->{dataclass}, $self->{molecule},$self->{division}, $self->{sequencelength}) =
	$content=~ /^(\S+)\s+(\w+); (.+); (\w+); (\d+) BP\.$/;
}

# parse ac line
# X56734; S46826;
sub parse_ac_line ($$) {
    my ($self, $reader, $content) = @_;
    
    # split the string at "; " and take care for
    # the last ";" at the end of string
    chop $content;
    push @{$self->{accnumbers}}, split ("; ", $content);
}

# parse dt line
# DT   DD-MON-YYYY (Rel. #, Created)
# DT   DD-MON-YYYY (Rel. #, Last updated, Version #)
# just store the content of the lines
# later version of this subparser may extract each single piece
# of information
sub parse_dt_line ($$) {
    push @{$_[0]->{date_lines}}, $_[2];
}

# parse keywords
# each entry contains an arbitary number of keyword
# these are stored in a hash for faster access
# KW   keyword[; keyword ...].
# only the last line is terminated with "." instead of ";"
sub parse_keyword_line ($$) {
    my ($self, $reader, $content) = @_;
    
    # to simplify this parser,
    # we ignore the difference between "." amd ";"

    chop $content;
    foreach (split ("; ", $content)) {
	$self->{keywords}->{$_} = 1;
    }
}

# parse organism classification
# the organism classification is a path through
# a taxonomic tree
# we store the single nodes of this path in a list
# OC   Node[; Node...].
# only the last line is terminated with "." instead of ";"
sub parse_organism_classification ($$) {
    my ($self, $reader, $content) = @_;

    chop $content;
    push @{$self->{organism_classifications}},split ("; ", $content);
} 

# parse citations
# every embl entry contains one or several links
# to publications
# RN   [n]
# RC   comment                           (optional)
# RP   i-j[, k-l...]                     (optional)
# RX  database_identifier; identifier.   (optional)
# RA  Author[,Author].
# RT  "text"                             (may be multiline..)
# RL   journal vol:pp-pp(year).
sub parse_citation ($$) {
    my ($self, $reader, $firstline) = @_;

    my ($refnum) = ($firstline =~ /\[(\d+)\]/);
    my $reference = {};
    while (1) {
	my ($tag, $content) = $reader->next_line () =~ /^(\w\w)\s*(.*)$/;
	if ($tag eq 'RC') {
	    # put all comments into a list
	    push @{$reference->{comments}}, $content;
	}
	elsif ($tag eq 'RP') {
	    # we don't further parse the
	    # reference position
	    $reference->{position} = $content;
	}
	elsif ($tag eq 'RA') {
	    # create a list of authors
	    chop $content;
	    push @{$reference->{authors}}, 
	    split (", ", $content);	   
	}
	elsif ($tag eq 'RX') {
	    chop $content;
	    my ($dbid, $id) = split ("; ", $content);
	    push @{$reference->{cross_refs}->{$dbid}}, $id;
	}
	elsif ($tag eq 'RL') {
	    # we don't further investige the
	    # reference location (e.g. book, paper, journal etc.)
	    chop $content;
	    push @{$reference->{location}}, $content;
	}
	elsif ($tag eq 'RT') {
	    # RT lines may spread several input lines
	    
	    my $texttag;
	    my $reftext;
	    $reference->{text} = $content;
	    do {
		($texttag, $reftext) = $reader->next_line () =~ /^(\w\w)\s*(.*)$/;
		if ($texttag eq 'RT') {
		    $reference->{text} .= $reftext;
		}
	    } while ($texttag eq 'RT');
	    
	    # strip off the semicolon
	    chop $reference->{text};
	    
	    # put back the parsed line for further processing
	    $reader->playback_line("$texttag   $reftext");
	}
	else {
	    # this tag doesn't belong to a reference
	    # put it back and stop 
	    $reader->playback_line("$tag   $content");
	    last;
	}
    }
    $self->{references}->[$refnum] = $reference;
}

# parses lines defining database IDs
# all database references are stored in an array of hashes
# DR  database_identifier; primary_identifier; secondary_identifier.
sub parse_database_reference ($$) {
    my ($self, $reader, $content) = @_;

    my $database_ref = {};
    chop $content;
    ($database_ref->{database_id}, $database_ref->{primary_id}, 
     $database_ref->{secondary_id}) = split ("; ", $content);
    push @{$self->{database_references}}, $database_ref;
}
    
# propagate the parsing of the feature
# table to a sub module
sub parse_feature_table {

    my ($self, $reader, $dummy) = @_;
    
    # this parser is called after reading the first 
    # 'FH'-line...$dummy doesnt
    # contain any useful information

    $self->{featuretable}=SeqDB::EMBL::FeatureTable->new;
    $self->{featuretable}->parse($reader);
}

# read the sequence itself...
sub parse_sequence {
    my ($self, $reader, $content) = @_;

    # we don't check the content of the first line
    # (sequence length, as, gs, cs, gs, etc. )

     while(1) {
	my $line = $reader->next_line();
	if ($line =~ /^\/\/\s*/) {
	    $reader->playback_line ($line);
	    last;
	}
	$line =~ s/\s|\d//g;
	$self->{sequence} .= $line;
    }
}


# little helper for get_sub_sequence
# returns the reverse complement of a DNA string
sub _reverse_complement ($) {
    my ($string) = @_;
    $string =~ tr/agctnAGCTN/tcganTCGAN/;
    return reverse($string);
}


# extracts the subsequence described by the feature object
# !! no error checking !!
# !! only simple location formats !! ( from..to, complement(from..to) )
sub get_sub_sequence ($$) {
    my ($self, $feature) = @_;

    my $location = $feature->location;
    $location =~ s/[^\d.]//g;
    if ($location =~ /^(\d+)\.\.(\d+)$/) {
	# string indices start with 0, locations with 1
	# translate the values...
	return substr ($self->{sequence}, $1 - 1, ($2 - $1) + 1);
    }
    elsif ($location =~ /^complement\((\d+)\.\.(\d+)\)$/) {
	return _reverse_complement (substr ($self->{sequence}, $1 - 1, ($2 - $1) + 1));
    }
    if ($^W) {
	warn "unsupported cds location: ",$location,"\n";
    }
    return;
}


sub write_to_string ($) {
    my ($self) = @_;
    
    my $result;
    
    my $seq_length = $self->{sequencelength};
    my $sequence = $self->{sequence};
    
    # write ID line
    $result = sprintf "ID   %s %s; %s; %s; %d BP.\n",
    $self->{entryname}, $self->{dataclass}, $self->{molecule}, $self->{division}, $seq_length;
    
    $result .= "XX\n";
    
    # write AC line

    $result .= "AC   ".join (";",@{$self->{accnumbers}}).";\n";
    $result .= "XX\n";

    # write SV line

    $result .= "SV   ".$self->{sequence_version}."\n";
    $result .= "XX\n";

    # write DT lines
    foreach (@{$self->{date_lines}}) {
	$result .= "DT   ".$_."\n";
    }
    $result .= "XX\n";
    
    # write DE line(s)
    
    if ($self->description) {
	my @descr_words =split / /,$self->description;
	$result .= splitted_lines("DE", " ", "", \@descr_words);
	$result .= "XX\n";
    }
    
    # write KW line(s)
    if (scalar @{$self->keywords}) {
	$result .= splitted_lines("KW", "; ", ".", $self->keywords);
	$result .= "XX\n";
    }

    # organism description
    if ($self->organism_species) {
	$result .= "OS   ".$self->organism_species."\n";
	if (scalar @{$self->organism_classifications}) {
	    $result .= splitted_lines("OC", "; ",".",$self->organism_classifications);
	}
	if ($self->organella) {
	    $result .= "OG   ".$self->organella."\n";
	}
	$result .= "XX\n";
    }

    # reference to literature

    if ($self->references) {
	for (my $i = 1; $i < scalar @{$self->{references}}; $i++) {
	    my $ref_record = $self->{references}->[$i];
	    $result .= "RN   [$i]\n";
	    foreach (@{$ref_record->{comments}}) {
		$result .= "RC   $_\n";
	    }
	    $result .= "RP   ".$ref_record->{position}."\n" if ($ref_record->{position});
	    foreach (keys %{$ref_record->{cross_refs}}) {
		$result .= "RX   $_; ".$ref_record->{cross_refs}->{$_}."\n";
	    }
	    $result .= splitted_lines("RA",", ",";",$ref_record->{authors});
	    my @dummy = split (/ /, $ref_record->{text});
	    $result .= splitted_lines("RT"," ",";",\@dummy);
	    foreach (@{$ref_record->{location}}) {
		$result .= "RL   $_\n";
	    }
	    $result .= "XX\n";
        }
    }
    # database references
    if ($self->database_references) {
	foreach (@{$self->database_references}) {
	    $result .= "DR   ".$_->{database_id}."; ".$_->{primary_id}."; ".$_->{secondary_id}.".\n";
	}
	$result .= "XX\n";
    }
    # comments
    if ($self->comments) {
        foreach (@{$self->{comments}}) {
            $result .= "CC   ".$_."\n";
        }
        $result .= "XX\n";
    }

    if ($self->{featuretable}) {
	$result .= $self->{featuretable}->write_to_string;
    }
    # write SQ line and sequence
    my $as = $sequence =~ tr/aA/aA/;
    my $cs = $sequence =~ tr/cC/cC/;
    my $gs = $sequence =~ tr/gG/gG/;
    my $ts = $sequence =~ tr/tT/tT/;

    $result .= sprintf "SQ   Sequence %d BP; %d A; %d C; %d G; %d T; %d other;\n",
    $seq_length, $as, $cs, $gs, $ts, $seq_length - $as - $cs - $gs - $ts;
    
    for (my $i = 0; $i < $seq_length; ) {
	my $seq_line = lc(substr ($sequence, $i, 60));
	$i+= length $seq_line;
	$seq_line =~ s/(\w{1,10})/$1 /g;
	$seq_line .= " " x (66 - length $seq_line);
	$seq_line = "     ".$seq_line." ".sprintf "%8d", $i;
	$result .= $seq_line;
	$result .= "\n";
    }
    # end of record tag
    $result .= "//\n";
}


sub splitted_lines {
    my ($tag, $delimiter, $end_delimiter, $content) = @_;

    return if (scalar (@$content)==0);
    my $result;
    my $line = $tag."   ".$content->[0];
    for(my $i = 1; $i < scalar @$content; $i++) {
	if ((length ($line) + length($content->[$i])+length($delimiter)) < 80) {
	    # add to this line
	    $line .= $delimiter.$content->[$i];;
	}
	else {
	    # line is full 
	    # create a new line 
	    $result .= $line."\n";
	    $line = $tag."   ".$content->[$i];
	}
    }
    $result .= $line.$end_delimiter."\n";
    return $result;
}


