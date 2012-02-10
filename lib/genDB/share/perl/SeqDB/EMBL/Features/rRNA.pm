package SeqDB::EMBL::Features::rRNA;

# little module to parse and store EMBL feature 'rRNA'
# (coding sequence)

# $Id: rRNA.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: rRNA.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:44:29  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $rRNA_qualifiers= { citation      => "int",
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
    return "rRNA";
}

sub valid_qualifiers {
    return $rRNA_qualifiers;
}

sub valid_qualifier ($$) {
    return $rRNA_qualifiers->{$_[1]};
}
