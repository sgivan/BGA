package SeqDB::EMBL::Features::gene;

# little module to parse and store EMBL feature 'Gene'
# (fescribing a single gene)

# $Id: gene.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: gene.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/13 13:23:17  blinke
# Initial revision
#
# Revision 1.2  2001/04/19 13:18:57  blinke
# moved to new hierarchie
#
# Revision 1.1  2001/04/17 11:07:40  blinke
# Initial revision
#
# Revision 1.1  2001/04/05 14:54:18  blinke
# Initial revision
#
# Revision 1.1  2001/04/05 14:53:28  blinke
# Initial revision
#


use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $gene_qualifiers = { allele        => "text",
			citation      => "int",
			db_xref       => "dbref",
                        evidence      => "unquoted",
                        function      => "text",
                        label         => "featurelabel",
                        map           => "text",
                        note          => "text",
			partial       => "bool",
                        product       => "text",
                        pseudo        => "bool",
                        phenotype     => "text",
                        standard_name => "text",
                        usedin        => "featurelabel"
 		       };
 

sub feature_key {
    return "gene";
}

sub valid_qualifiers {
    return $gene_qualifiers;
}

sub valid_qualifier ($$) {
    my ($self, $qual) = @_;
    return $gene_qualifiers->{$qual};
}
    
1;
