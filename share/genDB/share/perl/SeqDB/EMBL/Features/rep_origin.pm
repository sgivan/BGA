package SeqDB::EMBL::Features::rep_origin;

# little module to parse and store EMBL feature 'rep_origin'
# (coding sequence)

# $Id: rep_origin.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: rep_origin.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:42:28  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $rep_origin_qualifiers= { citation      => "int",
			     db_xref       => "dbref",
			     direction     => 'text',
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
    return "rep_origin";
}

sub valid_qualifiers {
    return $rep_origin_qualifiers;
}

sub valid_qualifier ($$) {
    return $rep_origin_qualifiers->{$_[1]};
}
