package SeqDB::EMBL::Features::protein_bind;

# little module to parse and store EMBL feature 'protein_bind'
# (coding sequence)

# $Id: protein_bind.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: protein_bind.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:42:39  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $protein_bind_qualifiers= { bound_moiety  => "text",
			       citation      => "int",
			       db_xref       => "dbref",
			       evidence      => "text",
			       function      => 'text',
			       gene          => "text",
			       label         => "feature_label",
			       map           => "text",
			       note          => "text",
			       standard_name => "text",
			       usedin        => "featurelabel"
		      };

1;	
	
sub feature_key {
    return "protein_bind";
}

sub valid_qualifiers {
    return $protein_bind_qualifiers;
}

sub valid_qualifier ($$) {
    return $protein_bind_qualifiers->{$_[1]};
}
