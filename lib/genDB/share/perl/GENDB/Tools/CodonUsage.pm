###############################################
# Package for codon usage calculations        #
#                                             #
###############################################

package GENDB::Tools::CodonUsage;

use GENDB::Config;
use GENDB::Tools::All_Aminoacid;
use vars qw($VERSION);

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

# Calculate codon usage for a coding sequence
sub calc_usage {
    my ($self, $sequence, $file) = @_;
    
    my $success=0;
    my $allaa_obj = GENDB::Tools::All_Aminoacid->new($GENDB_CODON);
    $allaa_obj -> fill_all_aminoacids($sequence);
    $success = $allaa_obj -> show($file);
    
    return $success;
};

1;
