package GENDB::Common;

($VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

##############################################
##############################################
## this package is a collection of several  ##
## standard functions used in GENDB         ##
## this package doesn't instantiate modules ##
## all functions should be declared static  ##
##############################################
##############################################

# $Id: Common.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: Common.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2004/08/10 21:40:28  genDB
# fixed create_fasta_file routine to conform to FASTA format
#
# Revision 1.1  2004/08/10 21:13:39  genDB
# Initial revision
#
# Revision 1.11  2002/07/26 13:13:28  oliver
# corrected molweight table
#
# Revision 1.10  2002/04/29 10:51:21  agoesman
# create_fasta_file method writes length to file now
#
# Revision 1.9  2002/04/29 10:43:45  agoesman
# *** empty log message ***
#
# Revision 1.8  2002/02/11 13:11:33  blinke
# added error catching to create_fasta_file
#
# Revision 1.7  2002/01/22 13:29:09  blinke
# removed typo in remove_dir
#
# Revision 1.6  2002/01/22 12:31:09  blinke
# added remove_dir to remove complete directories
#
# Revision 1.5  2001/10/09 12:43:22  agoesman
# checked for GENDB release V 1.0.5
#
# Revision 1.4  2001/08/27 16:08:32  agoesman
# genetic code now accesible via global variable $GENDB_CODON
#
# Revision 1.3  2001/08/27 14:02:55  agoesman
# added support for different genetic codes
#
# Revision 1.2  2001/08/24 14:02:06  agoesman
# *** empty log message ***
#
# Revision 1.1  2001/06/27 13:49:17  blinke
# Initial revision
#
# Revision 1.3  2000/08/09 10:49:33  blinke
# added complement()
#
# Revision 1.2  2000/07/06 15:53:11  blinke
# removed molweight from list of exported symbols (nameclash with GENDB::molweight)
# fixed read_fasta_file
#
# Revision 1.1  2000/03/15 14:28:22  blinke
# Initial revision
#

use File::Temp qw/ tempdir /;
use Carp qw(carp);
use GENDB::Config;
require Exporter;

@ISA = qw (Exporter);
@EXPORT = qw/ reverse_complement complement create_fasta_file read_fasta_file dna2aa translate calc_pI remove_dir aa_to_aa_name create_temp_file create_temp_dir /;

1;

#############################################################
# initialize this module (e.g. the codon translation table) #
#############################################################
BEGIN {
    # we _really_ need this module
    require Config;  

    if (defined $Config::alternate_codon_table) {
	*symboltable = *{Common::};
	$codontable = $Config::alternate_codon_table;
	#if (defined &{%symboltable->{'dna2aa_'.$codontable}}) {
	if (defined &{$symboltable->{'dna2aa_'.$codontable}}) {
	    $symboltable->{'dna2aa'}=\&{'dna2aa_'.$codontable};
	}
	else {
	    carp "unknown codontable $codontable, using default table !";
	}
    }
}


################################################
# calculate reverse complement of DNA sequence #
################################################
sub reverse_complement {
    my ($string)=@_;

    my $result='';
    my $len=length($string);

    $string=lc($string);
    $string =~ tr/agctn/tcgan/;

    $result=reverse($string);

    return $result;
};


########################################
# calculate complement of DNA sequence #
########################################
sub complement {
    my ($string)=@_;

    $string = lc ($string);
    $string =~ tr/agctn/tcgan/;

    return $string;
};


################################
# create a simple fasta file   #
# no pretty formatting, just   #
# plain sequence in single row #
################################
sub create_fasta_file {
    my ($filename, $seqname, $sequence) = @_;

    my $seqlength = length($sequence);

    open (FASTAFILE, "> $filename") or return 0;

    print FASTAFILE ">$seqname length: $seqlength\n";
    my $pos = 0;
    my $linelngth = 80;
    for ($pos = 0; $pos < length($sequence); $pos += 80) {
#    while ( (length($sequence) - $pos) > 0 ) {
#      $pos += 81;
      print FASTAFILE substr($sequence,$pos,$linelngth), "\n";
    }

    close (FASTAFILE);
    return 1;
};


####################################
# read sequences from a fasta file #
####################################
sub read_fasta_file {
    my $file = shift @_;

    my %sequences;
    my $name;
    my $sequence;
    open (FASTA, $file) or die "Cannot open $file !";
    while (<FASTA>) {
        chomp;
        #if (/^>(.+)$/) {
        if (/^>(.+?)\b/) {
            if ($name) {
                $sequences{$name}=$sequence;
            }
            $name = $1;
            $sequence = "";
        } else {
            $sequence .= $_;
        }
    }
    #if ($name) {
    if (!$sequences{$name}) {
        $sequences{$name}=$sequence;
    }
    close (FASTA);

    return \%sequences;
};


############################################
# convert a dna triplet into an amino acid #
############################################
sub dna2aa {
    my ($seq) = @_;

    $seq =~ tr/a-z/A-Z/;

    if ($GENDB_CODON == 1) { 
	# standard genetic code = 1
	# start codons: TTG, CTG: L Leu -- ATG: M Met
	# stop codons: TAA, TAG, TGA

    }
    elsif ($GENDB_CODON == 4) { 
	# genetic code for Mold, Protozoan, Coelenterate Mitochondrial Code and 
	# the Mycoplasma/Spiroplasma Code (transl_table=4)
	# start codons: 
	# TTA, TTG, CTG: L Leu -- ATG: M Met -- ATT, ATC, ATA: I Ile -- GTG: V Val
	# stop codons: TAG, TAA
	
	return "W" if $seq =~/TGA/;                    # TRP
	
    };
    
    ############################################################################
    #               default for procaryotes/Glimmer/GENDB                      #
    # !!! same usage as in code 1 but with a single different start codon: !!! #
    #                 !!! USING GTG INSTEAD OF CTG !!!                         #
    ############################################################################
    return "A" if $seq =~/GC\w/;                       # ALA, ALANIN
    return "R" if $seq =~/(AG[A|G]|CG\w)/;             # ARG, ARGININE
    return "N" if $seq =~/AA[TC]/;                     # ASN, ASPARAGINE
    return "D" if $seq =~/GA[TC]/;                     # ASP, ASPARTIC ACID
    return "C" if $seq =~/TG[TC]/;                     # CYS, CYSTEINE
    return "Q" if $seq =~/CA[AG]/;                     # GLN, GLUTAMINE
    return "E" if $seq =~/GA[AG]/;                     # GLU, GLUTAMIC ACID
    return "G" if $seq =~/GG\w/;                       # GLY, GLYCINE
    return "H" if $seq =~/CA[TC]/;                     # HIS, HISTIDIN
    return "I" if $seq =~/AT[TCA]/;                    # ILE, ISOLEUCIN
    return "L" if $seq =~/(TT[AG]|CT\w)/;              # LEU, LEUCIN
    return "K" if $seq =~/AA[AG]/;                     # LYS, LYSINE
    return "M" if $seq =~/ATG/;                        # MET, METHIONINE
    return "F" if $seq =~/TT[TC]/;                     # PHE, PHENYLALANINE
    return "P" if $seq =~/CC\w/;                       # PRO, PROLINE
    return "S" if $seq =~/(TC\w|AG[TC])/;              # SER, SERINE
    return "T" if $seq =~/AC\w/;                       # THR, THREONINE
    return "W" if $seq =~/TGG/;                        # TRP, TRYPTOPHAN
    return "Y" if $seq =~/TA[TC]/;                     # TYR, TYROSINE
    return "V" if $seq =~/GT\w/;                       # VAL, VALINE
    return "*" if $seq =~/TAG/;                        # TAG stop codon
    return "*" if $seq =~/TAA/;                        # TAA stop codon
    return "*" if $seq =~/TGA/;                        # TGA stop codon
    return ""  if $seq =~/$/;                          # whitespace or newline
    return "x" ;                                       # default
};


################################################################
# translate a given DNA sequence using into aminoacid sequence #
################################################################
sub translate{

    my ($seq)=@_;
    $aa='';

    $l=length($seq);

    for ($i=0; $i < $l-2 ; $i+=3) {
        $aa.=dna2aa(substr($seq, $i, 3));
    };

    return $aa;
};

# return the 3 letter name of an amino acid
sub aa_to_aa_name {

    my ($aa) = @_;
    $aa = lc($aa);
    return "Ala" if ($aa eq 'a');
    return "Arg" if ($aa eq 'r');
    return "Asn" if ($aa eq 'n');
    return "Asp" if ($aa eq 'd');
    return "Cys" if ($aa eq 'c');
    return "Gln" if ($aa eq 'q');
    return "Glu" if ($aa eq 'e');
    return "Gly" if ($aa eq 'g');
    return "His" if ($aa eq 'h');
    return "Ile" if ($aa eq 'i');
    return "Leu" if ($aa eq 'l');
    return "Lys" if ($aa eq 'k');
    return "Met" if ($aa eq 'm');
    return "Phe" if ($aa eq 'f');
    return "Pro" if ($aa eq 'p');
    return "Ser" if ($aa eq 's');
    return "Thr" if ($aa eq 't');
    return "Trp" if ($aa eq 'w');
    return "Tyr" if ($aa eq 'y');
    return "Val" if ($aa eq 'v');
    return "---";
}

########################################################
# calculate the molecular weight of a protein sequence #
########################################################
sub molweight {
    my ($aaseq)=@_;

    # init hash at pH = 7
    if ($#aaweight < 0) {
	$aaweight{'A'} = 89.09;
	$aaweight{'C'} = 121.16;
	$aaweight{'D'} = 133.10;
	$aaweight{'E'} = 147.13;
	$aaweight{'F'} = 165.19;
	$aaweight{'G'} = 75.07;
	$aaweight{'H'} = 155.16;
	$aaweight{'I'} = 131.17;
	$aaweight{'K'} = 146.19;
	$aaweight{'L'} = 131.17;
	$aaweight{'M'} = 149.21;
	$aaweight{'N'} = 132.12;
	$aaweight{'P'} = 115.13;
	$aaweight{'Q'} = 146.15;
	$aaweight{'R'} = 174.20;
	$aaweight{'S'} = 105.09;
	$aaweight{'T'} = 119.12;
	$aaweight{'V'} = 117.15;
	$aaweight{'W'} = 204.22;
	$aaweight{'Y'} = 181.19; 
	$aaweight{'*'} = 0;
	$aaweight{'X'} = 0; 

	$h2oweight = 18.016;
    }

    $molwt  = 0;  
    $numaa  = length ($aaseq);
    
    $i = 0; 
    while ($aa = substr($aaseq, $i, 1))     {
        $molwt += $aaweight{$aa};
        $i++;
    }

    # Subtract a water for each peptide bond.
    $molwt -= (($numaa - 1) * $h2oweight );


    return ($molwt);
};


###############################
# calculate isoelectric point #
###############################
sub calc_pI {
    ###################################################################
    #  Assume that no electrostatic interactions perturb ionization.
    #  Assume that the pI lies between pH1 and pH13.
    #
    #  Net Charge = number of positively charges residues 
    #               minus the number of negatively charged residues 
    #               plus  the number of protonated amino termini 
    #               minus the number of deprotonated termini
    #
    #  For each amino acid capable of charge, the number
    #  of protonated residues is determined by the following equation:
    #
    #     Np = Nt * [H+] / ([H+] + Kn)
    #
    #     where Np is the number of protonated residues, Nt is the number of
    #     residues of a specific amino acid, [H+] is the H+ concentration,
    #     and Kn is the dissociation constant of the amino acid.  
    #
    #  Optional Input:
    #  picalc (PIVAR,AMINOTERMINI,CARBOXYLTERMINI)
    #
    #  where PIVAR is the max. variance in the pI permitted (default=0.000001).
    #        AMINOTERMINI is the number of amino termini (default=1).
    #        CARBOXYLTERMINI is the number of carboxyl termini (default=1).
    ###################################################################

    my ($aaseq)=@_;
    
    $allowederror = 0.00001; 

    if (defined($_[1])) { $numaterm = $_[1]; }
    else { $numaterm = 1; }

    if (defined($_[2])) { $numcterm = $_[2]; }
    else { $numcterm = 1; }

    # Count lysines, arginines, histidines, 
    # glutamates, aspartates,
    # cysteines, tyrosines, amino termini, carboxyl termini, ambiguities.

    $_ = $aaseq;
    $numR = tr/R/R/;
    $numK = tr/K/K/;
    $numH = tr/H/H/;
    $numY = tr/Y/Y/;
    $numC = tr/C/C/;
    $numE = tr/E/E/;
    $numD = tr/D/D/;

    $numX = tr/X/X/;
    $numN = tr/N/N/;

    ## A  quick search method for the pI will involve a method that requires
    ## a low number of loops through the function.  Therefore, an interval
    ## search method will be used to narrow the search range (an interval where
    ## the net charge goes from negative to positive).  Then, a binary search
    ## method will be used to search for the 'netcharge=0' point within this
    ## interval.  Perhaps a Newton search method would be faster?  The desired
    ## error limit is within +/- 0.01 for the pI.

    # Set Ka values of charged amino acids: 
    
    $KaR = 10**(-12.48);
    $KaK = 10**(-10.53);
    $KaH = 10**(-6);
    $KaY = 10**(-10.07);
    $KaC = 10**(-10.28);
    $KaE = 10**(-4.25);
    $KaD = 10**(-3.65);
    $Kaaterm = 10**(-8.56);
    $Kacterm = 10**(-3.56);

    for ($i=2; $i<15; $i++) {
	if (&netcharge(10**(-$i)) <= 0) { last; }
    } 

    $high = $i;
    $low  = $i - 1;
    if (&netcharge(10**(-$high)) == 0) {
	$pI = $high;
    }
    elsif (&netcharge(10**(-$low)) == 0) {
	$pI = $low;
    }
    else {
	$lastmid = 0;   # Used in calculating error.
	$pI = &binarysearch($high, $low);
    }

    return ($pI);   
};


##################################################
# calculate the netcharge                        #
# Input:  proton concentration                   #
# Output: net charge of the amino acid sequence. #
##################################################
sub netcharge {
    my ($in)=@_;

    $numR*$in/($in+$KaR) + $numK*$in/($in+$KaK) + $numH*$in/($in+$KaH) - $numY + $numY*$in/($in+$KaY) - $numC + $numC*$in/($in+$KaC) - $numE + $numE*$in/($in+$KaE) - $numD + $numD*$in/($in+$KaD) + $numaterm*$in/($in+$Kaaterm) - $numcterm + $numcterm*$in/($in+$Kacterm);

};


########################################################################
# perform binary search                                                #  
# Input: $high and $low boundaries                                     #
# Exit:  when the net charge at $mid is 0 or within the allowed error. #
########################################################################
sub binarysearch {
    my ($a,$b)=@_;
    
    $mid = ($b + $a) / 2;
    $net = netcharge(10**(-$mid));

    if ( ($net == 0) || (($mid - $lastmid)**2 < $allowederror) ) {
	return $mid;
    }
    $lastmid = $mid;   # Used for standard error checking in next loop.

    if ($net > 0) { 
	binarysearch($a, $mid); 
    }
    else { 
	binarysearch($mid, $b); 
    }
};

# removes directories recursivly 
sub remove_dir {
    my ($dirname) = @_;
#    return 1;

    opendir (DIR, $dirname);
    for my $file (readdir (DIR)) {
	next if ($file =~ /^(\.|\.\.)$/); # skip pseudo directories . and ..
	if (-d $dirname."/".$file) {
	    remove_dir ($dirname."/".$file);
	}
	else {
	    unlink ($dirname."/".$file);
	}
    }
    closedir (DIR);
    rmdir ($dirname);

}

############################
#
# make a temp file
#
############################

sub create_temp_file {
  $infh = new File::Temp( TEMPLATE	=> 	'genDB_XXXXXXXXXX',
			  DIR	  	=>	"/tmp/",
#			  DIR	  	=>	"/local/cluster/tmp/",
#			  SUFFIX	=>	".txt",
#			  UNLINK 	=> 	0,
			);
  $localFile = $infh->filename;
  return $localFile;
}

#############################
#
# make a temp directory
#
#############################

sub create_temp_dir {
  my $template = 'genDB_XXXXXXXXXX';
  #my $dir_path = '/local/cluster/tmp/';
  my $dir_path = '/tmp/';
  
#  my $dir = tempdir( $template, DIR => $dir_path, CLEANUP => 1 );
  my $dir = tempdir( $template, DIR => $dir_path, CLEANUP => 0 );
#  return $dir->filename();
  return $dir;
}
