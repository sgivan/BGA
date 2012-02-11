package SeqDB::EMBL::FeatureTable;

# this package is part of the EMBL parser

# it contains acts as a collectors for features
# parsed by sub modules...

# $Id: FeatureTable.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: FeatureTable.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.5  2002/02/19 14:50:56  blinke
# corrected regexp to parse over unknown features
#
# Revision 1.4  2002/02/12 12:43:25  blinke
# moved to SeqDB hierarchie
# added code to write EMBL files
# change the way feature parsers are invoked
#
# Revision 1.3  2001/04/19 13:04:34  blinke
# moved to new hierarchie
#
# Revision 1.2  2001/04/17 11:06:43  blinke
# added switch to disable warnings
#
# Revision 1.1  2001/04/05 14:52:59  blinke
# Initial revision
#

use vars qw($AUTOLOAD);
#use strict;

1;

sub AUTOLOAD {
    return if $AUTOLOAD =~ /::DESTROY$/;

    # this method does a lot of magic
    # features parsers are called as method in this class
    # the following codes automatically load the perl
    # modules and creates the method for invoking the
    # feature parser

    my ($feature) = ($AUTOLOAD =~ /::(\w+)$/);
    
    # try to load module
    eval "require SeqDB::EMBL::Features::$feature";
    if ($@) {
	# this feature is unknown or the parser module
	# has not been written yet
	warn "unknown feature $feature: $@" ;#if ($self->{warn_if_unknown});
	*SeqDB::EMBL::FeatureTable::->{$feature} = sub {
	    return -1;
	};
	return -1;
    }
    else {
	# create a method for this
	# (warning ! dragons around...
	#  we manipulate the symbol table of this module
	#  on the fly to generate new methods.... )
	*SeqDB::EMBL::FeatureTable::->{$feature} = sub {
	    return "SeqDB::EMBL::Features::$feature"->new(@_);
	};
	# invoke sub module...
	return &$feature(@_);
    }
}

sub new {
    my $class = shift;

    my $self= {warn_if_unknown => 0};
    bless $self, $class;
    return $self;
}

# returns the list of features known
#sub available_features {
#    return keys %$feature_keys;
#}


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
    my ($self, $parser) = @_;
    
    while (1) {
	my $line = $parser->next_line;
	
	# skip the feature header (lines starting with 'FH')
	next if ($line =~ /^FH/);

	# check whether the line is not partof the 
	# feature table anymore...
	if ($line !~ /^FT/) {
	    $parser->playback_line ($line);
	    last;
	}

	# check whether this is a new feature key...
	if (my ($key, $location) = $line =~ /^FT\s+(\S+)\s+(\S+)/) {

	    # some feature key names starts with a "-"-sign
	    # convert this to the literal "minus" to prevent
	    # perl from failing to load the feature module
	    $key =~ s/^-/minus/;

	    # propagate parsing of feature to sub pars
	    my $feature = &$key($location);
	    if ($feature != -1) {
		$feature->parse($parser);
		
		# store new feature object
		push @{$self->{features}}, $feature;
	    }
	    else {
		while (1) {
		    my $dummy = $parser->next_line;
		    if ($dummy =~ /^FT\s{2,5}\w+/) {
			$parser->playback_line($dummy);
			last;
		    }
		}
	    }
	}
    }
}

sub add_feature {
    my ($self, $new_feature) = @_;

    push @{$self->{features}}, $new_feature;
}

sub get_features {
    return $_[0]->{features};
}

sub write_to_string {
    my ($self) = @_;

    return "" if (scalar @{$self->{features}} == 0);
    my $result;

    $result = "FH   Key             Location/Qualifiers\nFH\n";
    foreach (@{$self->{features}}) {
	$result .= $_->write_to_string;
    }
    $result .= "XX\n";
    return $result;
}
