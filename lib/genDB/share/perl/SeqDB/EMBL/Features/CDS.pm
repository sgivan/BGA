package SeqDB::EMBL::Features::CDS;

# little module to parse and store EMBL feature 'CDS'
# (coding sequence)

# $Id: CDS.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: CDS.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.3  2002/02/12 12:45:04  blinke
# moved to SeqDB hierarchie
#
# Revision 1.2  2001/04/19 13:19:05  blinke
# moved to new hierarchie
#
# Revision 1.1  2001/04/05 14:54:13  blinke
# Initial revision
#
# Revision 1.1  2001/04/05 14:53:21  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $CDS_qualifiers= { citation      => "int",
                      codon         => "text",
                      codon_start   => "int",
                      db_xref       => "dbref",
                      EC_number     => "text",
                      evidence      => "text",
                      exception     => "unquoted",
                      function      => "text",
                      gene          => "text",
                      label         => "feature_label",
                      map           => "text",
                      note          => "text",
                      number        => "unquoted",
                      partial       => "bool",
                      product       => "text",
                      protein_id    => "text",
                      pseudo        => "bool",
                      standard_name => "text",
                      translation   => "text",
		      transl_except => "text",
                      transl_table  => "int",
                      usedin        => "featurelabel"
		      };

1;	
	
sub feature_key {
    return "CDS";
}

sub valid_qualifiers {
    return $CDS_qualifiers;
}

sub valid_qualifier ($$) {
    return $CDS_qualifiers->{$_[1]};
}
