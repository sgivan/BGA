
###############################################
# Package for codon usage calculations        #
#                                             #
# #############################################


package GENDB::Tools::Aminoacid;
use GENDB::Tools::Codon;

use strict;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

@ISA = qw(Exporter);       
($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);
1;

# Create an empty aminoacid object for all synonymous codons
sub new{
    my ($type, $aminoacid) = @_;
    my $class = ref($type) || $type;
    my $self = {'aminoacid' => $aminoacid, 
		'codons' => {},
		'number_of' => undef};
    bless $self, $class;
    return $self;
}


# add a codon to the aminoacid object
sub add_codon {
    my ($self, $aminoacid, $codon, $number) = @_;
    if ($aminoacid eq $self ->aminoacid()) {
	$self->{'codons'}->{$codon} = GENDB::Tools::Codon ->new($codon, $number);
	return $codon;
    }
    else {die "Attempt to add_codon for $aminoacid to aminoacid_obj for "
	      ,$self ->aminoacid(), "\n";} 
} 

# add total number of synonymous codons
# only to be used after all codons are added to a codon object
sub add_number_of {
    my $self = $_[0];
    my $codons = $self ->codons();
    my $number_of;
    my($codon,$CodonObj);
    while (($codon,$CodonObj)= each(%$codons)) {
	$number_of += ($CodonObj -> number());
    }
    $number_of = 0 if ! $number_of;
    $self->{'number_of'} = $number_of;
    return $number_of;
}

sub aminoacid {
    return $_[0]->{'aminoacid'};
}
sub codons {
    return $_[0] ->{'codons'};
}
sub number_syncodons {
    my $number = keys %{$_[0] ->codons()};
    return $number;
}

sub codon {  
    my($self, $codon) = @_;
    return $self->{'codons'}->{$codon} if defined($self->{'codons'}->{$codon});
    return 0;
}
			
sub number_of {
    return $_[0]{'number_of'};
}

sub evaluation {
    my $self = $_[0];
    my $cut_off = $_[1];
    if (defined ($self->{'number_of'})&&$self ->{'aminoacid'} =~/[^\WM*]/ ) {
	if ($self->{'number_of'} >= $cut_off) {
	    return 1;
	}
    }
    else {return 0}
}

sub modify { # add pseudocounts for codons of aa_obj
    my $aa_obj = $_[0]; 
    my $mod_codon_obj;
    my $syn_codons;
    while(my($codon,$codon_obj) = each %{$aa_obj ->codons()}) {
	$mod_codon_obj = $codon_obj ->modify();
	$aa_obj ->{'codons'}{$codon} = $mod_codon_obj;
	$syn_codons += $mod_codon_obj ->number();
    }
    while(my($codon,$codon_obj) = each %{$aa_obj ->codons()}) {
	$codon_obj -> add_fraction($syn_codons);
    }
    $aa_obj ->add_number_of();
    return $aa_obj;
}
