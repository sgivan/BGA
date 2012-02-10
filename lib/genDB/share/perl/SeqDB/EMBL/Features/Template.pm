package SeqDB::EMBL::Features::Template;

# little module to parse and store EMBL feature 'Source'
# (describing the source of the sequence )

# $Id: Template.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: Template.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.7  2002/05/17 12:18:45  blinke
# fixed a fault at reading unknown qualifiers
#
# Revision 1.6  2002/04/16 09:46:23  blinke
# fixed parsing of unknown qualifiers
#
# Revision 1.5  2002/02/12 12:44:13  blinke
# moved to SeqDB hierarchie
# added code to write EMBL files
#
# Revision 1.4  2001/04/27 12:15:52  blinke
# added "location" to exported methods
#
# Revision 1.3  2001/04/19 13:19:15  blinke
# moved to new hierarchie
#
# Revision 1.2  2001/04/17 11:08:30  blinke
# added switch to disable warnings
#
# Revision 1.1  2001/04/05 14:54:23  blinke
# Initial revision
#
# Revision 1.1  2001/04/05 14:53:35  blinke
# Initial revision
#

use Carp;

1;

# access feature fields by AUTOLOAD

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if ($method eq 'DESTROY');
    if ($self->valid_qualifier($method)||($method eq "location")) {
	if (defined $_[0]) {
	    return $self->{$method}=$_[0];
	}
	return $self->{$method};
    }
    else {
	croak "unknown methods $method in AUTOLOAD";
    }
}

sub new ($$) {
    my ($class, $location) = @_;

    my $self = { location => $location,
		 warn_if_unknown => 0 };
    bless $self, $class;
    return $self;

}

sub warn_if_unknown ($$) {
    my ($self, $warn) = @_;
    if (defined ($warn)) {
	$self->{warn_if_unknown}=$warn;
    }
    else {
	return $self->{warn_if_unknown};
    }
}

sub parse ($$) {
    my ($self, $reader) = @_;
    
    $self->_check_location($reader);
    while (1) {
	my $line = $reader->next_line;
	my $qualifier;
	my $content;
	if (!(($qualifier, $content) = $line =~/^FT\s+\/([A-Za-z0-9_]+)=(.+)/)) {
	    $reader->playback_line($line);
	    last;
	}
	if ($self->valid_qualifier($qualifier)) {
	    # qualifier content may run across several lines
	    # so check whether all quotes '"' are closed..
	    my $text = $content;
	    while ($text =~ s/\"/\"/g % 2) {
		$line = $reader->next_line;
		$line =~ s/^FT\s+//;
		chomp $line;
		$text .= "\n".$line;
	    }
	    if ((substr($text,0,1) eq '"') &&
		(substr($text,-1,1) eq '"')) {
		$text = substr ($text, 1, length ($text) - 2);
	    }
	    $self->{$qualifier} = $text;
	}
	else {
	    warn "skipping unknown qualifier $qualifier" if ($self->warn_if_unknown);
	    while (1) {
		$line = $reader->next_line;
		# skip all lines belonging to this qualifier
		last if (($line =~ /^FT\s+\//) ||   # line of another qualifier
			 ($line =~ /^FT\s{2,5}\S+/)||# line of next feature
			 ($line =~ /^FH/));         # end of feature table
	    }
	    $reader->playback_line($line);
	}
    }
}

# check whether we read the complete location info
# it may be spread across several lines
sub _check_location {
    my ($self, $reader) = @_;

    # simple check for location: all parenthesis are closed
    while (1) {
	my $open_paren = ($self->{location} =~ tr/\(/\(/);
	my $closed_paren = ($self->{location} =~ tr/\)/\)/);
	last if ($open_paren == $closed_paren);
	my $next_line = $reader->next_line;
	my ($loc_add) = $next_line =~ /^FT\s+(.+)$/;
	$self->{location}.= $loc_add;
    }
}

sub write_to_string ($) {
    my ($self) = @_;

    my $result = sprintf "FT   %-16s%s",$self->feature_key, $self->location."\n";
    foreach (keys %{$self->valid_qualifiers}) {
	if (defined ($self->{$_})) {
	    $result .= qualifier_string ($_,$self->valid_qualifiers->{$_},
					 $self->{$_});
	}
    }
    return $result;
}


sub qualifier_string {
    my ($key, $key_format, $data) = @_;
    
    if ($key_format eq "bool") {
	return "FT                   /$key\n";
    }
    if ($key_format eq "unquoted") {
	return "FT                   /$key=$data\n";
    }
    else {
	if (substr ($data,0,1) eq '"') {
	    $not_chopped = "/$key=$data"; 
	}
	else {
	    $not_chopped = "/$key=\"$data\"";
	}
	my @words = split (" ",$not_chopped);
	my $result = splitted_lines ("FT                ",
				     " ",
				     "",
				     \@words);
	return $result;
    }
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


