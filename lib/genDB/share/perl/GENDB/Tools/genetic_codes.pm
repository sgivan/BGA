package GENDB::Tools::genetic_codes;

$VERSION = 1.1;

############################################################
# describe all genetic codes in a hash                     #
# provide functions to access start and stop codons for a  #
# specified genetic code ($GENDB::Config::GENDB_CODON)     #
############################################################

use GENDB::Tools::ProjectConfig;
use GENDB::Config;

#####################################################################
# predefined hash with complete default configuration               #
#####################################################################
######  !!! ADD an entry for EACH PROJECT SPECIFIC OPTION !!!  ######
#####################################################################

my %genetic_codes = ( '0' => { ### GENDB/Glimmer default
                          'starts' => "ATG|GTG|TTG",
		          'stops' => "TAG|TAA|TGA"
			  },
		      '1' => { ### Standard
			  'starts' => "ATG|CTG|TTG",
			  'stops' => "TAG|TAA|TGA"
			  },
		      '4' => { ### Mold, Protozoan, Coelenterate Mitochondrial and Mycoplasma/Spiroplasma
			  'starts' => "ATG|CTG|TTG|TTA|ATT|ATC|ATA|GTG",
			  'stops' => "TAG|TAA"
			  }
		      );

###############################################
### get start codons for given genetic code ###
###############################################
sub get_start_codons {
    
    my $starts = "";
    
    my $code = $GENDB_CODON;
    $starts = $genetic_codes{$code}->{"starts"};
    
    return $starts;
};

##############################################
### get stop codons for given genetic code ###
##############################################
sub get_stop_codons {
    
    my $stops = "";
    
    my $code = $GENDB_CODON;
    $stops = $genetic_codes{$code}->{"stops"};

    return $stops;
};
