package SeqDB::EMBL::Features::terminator;

# little module to parse and store EMBL feature 'terminator'
# (coding sequence)

# $Id: terminator.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: terminator.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:44:19  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $terminator_qualifiers= { citation      => "int",
			   db_xref       => "dbref",
			   evidence      => "text",
			   gene          => "text",
			   label         => "feature_label",
			   map           => "text",
			   note          => "text",
			   standard_name => "text",
			   usedin        => "featurelabel"
			   };

1;	
	
sub feature_key {
    return "promoter";
}

sub valid_qualifiers {
    return $terminator_qualifiers;
}

sub valid_qualifier ($$) {
    return $terminator_qualifiers->{$_[1]};
}
