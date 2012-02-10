package SeqDB::EMBL::Features::source;

# little module to parse and store EMBL feature 'Source'
# (describing the source of the sequence )

# $Id: source.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: source.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/02/13 13:23:33  blinke
# Initial revision
#
# Revision 1.3  2001/04/19 13:18:47  blinke
# moved to new hierarchie
#
# Revision 1.2  2001/04/17 11:08:05  blinke
# added qualifier "insertion_seq"
#
# Revision 1.1  2001/04/05 14:54:18  blinke
# Initial revision
#
# Revision 1.1  2001/04/05 14:53:28  blinke
# Initial revision
#


use SeqDB::EMBL::Features::Template;

@ISA = qw (SeqDB::EMBL::Features::Template);

my $source_qualifiers= { organism         => "text",
			 cell_line        => "text",
			 cell_type        => "text",                     
			 chromosome       => "text",
			 citation         => "int",
			 clone            => "text",
			 clone_lib        => "text",
			 country          => "text",
			 cultivar         => "text",              
			 db_xref          => "dbref",
			 dev_stage        => "text", 
			 evidence         => "unquoted",
			 focus            => "text",
			 frequency        => "text",
			 germline         => "bool",
			 haplotype        => "text",
			 lab_host         => "text",
			 insertion_seq    => "text",
			 isolate          => "text",
			 label            => "featurelabel",
			 macronuclear     => "bool",
			 map              => "text",
			 note             => "text",
			 organelle        => "text",
			 plasmid          => "text",
			 pop_variant      => "text",
			 proviral         => "bool",
			 rearranged       => "bool",
			 sequenced_mol    => "text",
			 serotype         => "text",
			 sex              => "text",
			 specimen_voucher => "text",
			 specific_host    => "text",
			 strain           => "text",
			 sub_clone        => "text",
			 sub_species      => "text",
			 sub_strain       => "text",
			 tissue_lib       => "text",
			 tissue_type      => "text",
			 transposon       => "text",
			 usedin           => "featurelabel",
			 variety          => "text",
			 virion           => "bool"
			 };

sub feature_key {
    return "source";
}

sub valid_qualifiers {
    return $source_qualifiers;
}

sub valid_qualifier ($$) {
    my ($self, $qual) = @_;
    return $source_qualifiers->{$qual};
}
    
1;
		    
