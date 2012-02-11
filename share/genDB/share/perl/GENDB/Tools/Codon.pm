#$Id: Codon.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $
#$Log: Codon.pm,v $
#Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
#Revision 1.3  2001/10/11 09:07:49  alice
#Commented
#
#Revision 1.2  2001/08/29 12:06:07  agoesman
#initial version
#
#Revision 1.1  2001/08/29 11:35:40  agoesman
#Initial revision
#
#Revision 1.1  2001/08/28 11:16:47  alice
#Initial revision
#
#Revision 1.1  2001/07/05 13:48:52  alice
#Initial revision
#

###############################################
# Package for codon usage calculations        #
#                                             #
# #############################################

package GENDB::Tools::Codon;

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

use strict;

1;

# create a codon object
sub new {
    my ($type, $codon, $number) = @_;
    my $class = ref($type) || $type;
    my $self = {'codon' => $codon,
		'fraction' => undef,
		'number' => $number,
		'log_fraction' => undef};
    bless $self, $class;
    return $self;
} 

# add fraction for codon use relative to 
# all other synonymous codons (for one amino acid)
sub add_fraction {
    my($self, $codons) = @_;
    my $fraction;
    $fraction = $self ->number() / $codons if $codons;
    $fraction = 0 if ! $codons;
    $self ->{'fraction'} = $fraction;
    $self ->{'log_fraction'} =($fraction != 0)? log $fraction : -1;
    return $self;
}
 
sub codon {
    return $_[0]->{'codon'};
}
sub fraction {
    return $_[0]->{'fraction'};
}
sub number {
    return $_[0]->{'number'};
}

sub log_fraction {
    return $_[0]->{'log_fraction'};
}


	
	
