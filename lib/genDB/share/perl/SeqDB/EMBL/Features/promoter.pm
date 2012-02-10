package SeqDB::EMBL::Features::promoter;

# little module to parse and store EMBL feature 'promoter'
# (coding sequence)

# $Id: promoter.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: promoter.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:42:34  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $promoter_qualifiers= { citation      => "int",
			   db_xref       => "dbref",
			   evidence      => "text",
			   gene          => "text",
			   function      => "text",  
			   label         => "feature_label",
			   map           => "text",
			   note          => "text",
			   phenotype     => "text",
			   pseudo        => "bool",
			   standard_name => "text",
			   usedin        => "featurelabel"
			   };

1;	
	
sub feature_key {
    return "promoter";
}

sub valid_qualifiers {
    return $promoter_qualifiers;
}

sub valid_qualifier ($$) {
    return $promoter_qualifiers->{$_[1]};
}
