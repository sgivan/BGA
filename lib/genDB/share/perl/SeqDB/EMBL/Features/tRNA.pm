package SeqDB::EMBL::Features::tRNA;

# little module to parse and store EMBL feature 'tRNA'
# (coding sequence)

# $Id: tRNA.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: tRNA.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:45:13  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $tRNA_qualifiers= { anticodon     => 'text',
		       citation      => "int",
		       db_xref       => "dbref",
		       evidence      => "text",
		       function      => "text",
		       gene          => "text",
		       label         => "feature_label",
		       map           => "text",
		       note          => "text",
		       product       => "text",
		       pseudo        => "bool",
		       standard_name => "text",
		       usedin        => "featurelabel"
		      };

1;	
	
sub feature_key {
    return "tRNA";
}

sub valid_qualifiers {
    return $tRNA_qualifiers;
}

sub valid_qualifier ($$) {
    return $tRNA_qualifiers->{$_[1]};
}
