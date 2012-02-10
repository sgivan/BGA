package SeqDB::EMBL::Features::RBS;

# little module to parse and store EMBL feature 'RBS'
# (coding sequence)

# $Id: RBS.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: RBS.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:42:44  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $RBS_qualifiers= { citation      => "int",
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
    return "RBS";
}

sub valid_qualifiers {
    return $RBS_qualifiers;
}

sub valid_qualifier ($$) {
    return $RBS_qualifiers->{$_[1]};
}
