###############################################
# Package for codon usage calculations        #
#                                             #
###############################################


package GENDB::Tools::All_Aminoacid;
use GENDB::Tools::Aminoacid;
use GENDB::Tools::Gen_Codes;
use strict;
use vars qw($VERSION);
($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

1;

# Create an empty object for all aminoacids
sub new {
    my ($type, $GENDB_CODON) = @_;
    my $class = ref($type)|| $type;
    my $self = {'aminoacids' => {},
		'number_of' =>undef,
		'gen_code' => $GENDB_CODON};
    bless $self, $class;
    return $self;
}

# Create output file
sub show {
    my ($allaa_obj, $file) = @_;
    my $sucess = 1;
    open(OUT, ">$file") || ($sucess = 0);
    print OUT "Genetic code used: ".
	($allaa_obj ->gen_code() ?$allaa_obj ->gen_code():"Standard")."\n\n";
    print OUT "Aminoacid\tCodon\tFraction\tNumber\n\n";
    while(my($aa, $aa_obj) = each(%{$allaa_obj ->aminoacids()})) {
	while (my($codon, $codon_obj) = each(%{$aa_obj ->codons()})) {
	    my $fraction = $codon_obj ->fraction();
	    my $number = $codon_obj -> number();
	    printf OUT "\t$aa\t\t$codon\t%10.3f\t%10d\n", $fraction, $number;
	}
	print OUT "\n";
    }
    close OUT || ($sucess = 0);
    return $sucess;
}
	
# Calculate codons and codon usage from sequence 			   
sub fill_all_aminoacids {
    my($allaa_obj, $sequence) = @_;
    my $codons = int(length($sequence)/3);
    my %codon_table;
    my @codon_array = unpack("a3" x $codons, $sequence);
    foreach my $codon (@codon_array) {
	$codon =~ tr/atgc/ATGC/;
	++$codon_table{$codon};
    }
    my $gen_code = "code_".$allaa_obj ->gen_code(); 
    my $complete_aminoacids = GENDB::Tools::Gen_Codes ->can($gen_code)|| $GENDB::Tools::Gen_Codes::complete_aminoacids;
    while (my($aa, $syn_codons) = each %$complete_aminoacids) {
	my $aa_obj = GENDB::Tools::Aminoacid ->new($aa);
	foreach my $codon (@$syn_codons) {
	    $codon_table{$codon} = 0 unless $codon_table{$codon};
	    $aa_obj -> add_codon($aa, $codon, $codon_table{$codon} );
	}
	my $codons = $aa_obj ->add_number_of();
	while(my($codon, $codon_obj)= each %{$aa_obj ->codons()}){
	    $codon_obj ->add_fraction($codons);
	}   
	$allaa_obj -> add_aminoacid($aa_obj);
    }
    $allaa_obj ->add_number_of();    
}

# Add an amino acid object to the all aminoacid object
sub add_aminoacid {
    my ($self, $aa_Obj) = @_;
    my $aminoacid = $aa_Obj -> aminoacid();
    $aa_Obj ->add_number_of();
    $self ->{'aminoacids'}{$aminoacid} = $aa_Obj;
    return $aminoacid;
}

    
# calculate length in codons of an All_aminoacids-Object
sub add_number_of {
    my $self = $_[0];
    my $number;
    my ($aminoacid, $aa_Obj);
    while (($aminoacid, $aa_Obj)= each(%{$self->{'aminoacids'}})) {
	$number += ($aa_Obj ->number_of());
    }
    $self->{'number_of'} = $number;
    if ($number) {return $number}
    else {return -1}
}


sub aminoacid {
    my ($self, $aminoacid) = @_;
    if (defined ($self->{'aminoacids'}{$aminoacid})){
	return $self->{'aminoacids'}{$aminoacid};
    }
    else {return -1}
}

sub number_of {
    return $_[0]{'number_of'};
}


sub aminoacids {
    return $_[0]{'aminoacids'};
}

sub gen_code {
    return $_[0] ->{'gen_code'};
}
