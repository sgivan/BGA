package SeqDB::SpTrEMBL::Entry;

# this package is a generic parser for SwissProt/TrEMBL formatted
# sequences files
# it parses one single sequence of a multiple SwissProt/TrEMBL file

# $Id: Entry.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: Entry.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.6  2001/09/05 14:05:06  blinke
# moved to SeqDB hierarchie
#
# Revision 1.5  2001/06/05 15:19:16  blinke
# fixed missing dot at end of regexp for id line
#
# Revision 1.4  2001/04/19 14:54:23  blinke
# corrected regexp for parsing ID line
#
# Revision 1.3  2001/04/19 14:36:16  blinke
# corrected regexp for end of sequence
#
# Revision 1.2  2001/04/19 13:02:05  blinke
# move to new hierarchie
#
# Revision 1.1  2001/04/18 16:49:58  blinke
# Initial revision
#

use IO::File;
use Carp qw (croak);

# access entry fields by AUTOLOAD

sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if ($method eq 'DESTROY');
    if (defined $self->{$method}) {
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
		     'DT' => \&parse_dt_line,
		     'DE' => sub { $_[0]->{description} .= " ".$_[2];},
		     'GN' => \&parse_gene_names,
		     'OS' => sub { $_[0]->{organism_species} .= " ".$_[2];},
		     'OC' => \&parse_organism_classification,
		     'OG' => sub { $_[0]->{organella} .= " ".$_[2];},
		     'OX' => sub {},
		     'RN' => \&parse_citation,
		     'DR' => \&parse_database_reference,
		     'KW' => \&parse_keywords,
		     'FT' => \&parse_feature_table,
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
    ($self->{entryname}, $self->{dataclass}, $self->{molecule}, $self->{sequencelength}) =
	$content=~ /^(\S+)\s+(\w+);\s+(\w+);\s+(\d+) AA\.$/;
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
sub parse_keywords ($$$) {
    my ($self, $reader, $content) = @_;
    
    # to simplify this parser,
    # we ignore the difference between "." amd ";"

    chop $content;
    push @{$self->{keywords}}, split ("; ",$content);
}

# parse genenames
# GN   NAME1[ AND|OR NAME2...].
sub parse_gene_names ($$$) {
    my ($self, $reader, $content) = @_;
    
    chop $content;
    $self->{gene_names} .= " ".$content;
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
     $database_ref->{secondary_id}, $database_ref->{status}) 
	= split ("; ", $content);
    push @{$self->{database_references}}, $database_ref;
}

# parsing the feature table of SwissProt/TrEMBL
# is not supported yet
sub parse_feature_table {

    my ($self, $reader, $dummy) = @_;
    
    while (1) {
	my $line =$reader->next_line;
	if ($line !~ /^FT/) {
	    $reader->playback_line ($line);
	    last;
	}
    }
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

1;
