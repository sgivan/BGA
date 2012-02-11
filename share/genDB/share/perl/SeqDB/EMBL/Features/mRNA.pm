package SeqDB::EMBL::Features::mRNA;

# little module to parse and store EMBL feature 'mRNA'
# (coding sequence)

# $Id: mRNA.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: mRNA.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/12 12:44:24  blinke
# Initial revision
#

use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $mRNA_qualifiers= {allele        => "text",
		      citation      => "int",
		      db_xref       => "dbref",
		      evidence      => "text",
		      gene          => "text",
		      function      => "text",  
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
    return "mRNA";
}

sub valid_qualifiers {
    return $mRNA_qualifiers;
}

sub valid_qualifier ($$) {
    return $mRNA_qualifiers->{$_[1]};
}
