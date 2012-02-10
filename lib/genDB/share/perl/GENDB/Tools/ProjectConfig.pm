#
# a helper module to read and store project specific configuration information
#
package GENDB::Tools::ProjectConfig;

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

use GENDB::GENDB_CONFIG;
use GENDB::Config;
use Config::IniFiles;
require Exporter;
@ISA = qw (Exporter);


# we store the data in the $GENDB_INSTALL_DIR/lib/$GENDB_CONFIG/GENDB/gendbproject.rc file for each project
my $configfilename = "$GENDB_INSTALL_DIR/lib/$GENDB_CONFIG/GENDB/.gendbproject.rc";


# predefined hash with complete default configuration
#####################################################################
######  !!! ADD an entry for EACH PROJECT SPECIFIC OPTION !!!  ######
#####################################################################
my %confighash = ( 'signalp_tool type' => "gram+",
		   'signalp_tool format' => "summary",
		   'signalp_tool trunc' => "80",
		   'genetic code' => "0",
		   'gene products' => "hypothetical protein predicted by Glimmer/Critica,conserved hypothetical protein,putative secreted protein,putative membrane protein"
		   );


###################################################
### get value of given parameter,               ###
###################################################
sub get_parameter {
    my ($self, $param) = @_;

    my $retvalue="";
    if (-r $configfilename) {
	my $cfg = new Config::IniFiles( -file => "$configfilename", -default => "defaults" );
	### if parameter is empty default values are used automatically
	$retvalue = $cfg->val( 'projectdefined', $param );    
    }
    else {
	my $newcfg = &create_default_config();
	$retvalue = $newcfg->val( 'defaults', $param );
    };

    if ($retvalue eq '') {
	$retvalue = $confighash{$param};
	&set_parameter($self, $param, $retvalue);
    }

    return $retvalue;
};


###################################################
### set value of given parameter,               ###
###################################################
sub set_parameter {
    my ($self, $param, $value)=@_;

    if (-r $configfilename) {
	my $cfg = new Config::IniFiles( -file => "$configfilename" );

	# check if default has been set already
	if ($cfg->setval( 'defaults', $param, $value )) {
	}
	else {
	    my $r1 = $cfg->newval( 'defaults', $param, $value );
	};
	
	# check if project defined value has been set already
	if ($cfg->setval( 'projectdefined', $param, $value )) {
	}
	else {
	    my $r2 = $cfg->newval( 'projectdefined', $param, $value );
	};
	$cfg->RewriteConfig;
    }
    else {
	my $newcfg = &create_default_config();
	$newcfg->setval( 'projectdefined', $param, $value );
	$newcfg->RewriteConfig;
    };
    
};


###################################################
### reset all values to default configuration   ###
###################################################
sub reset_parameters {

    if (-r $configfilename) {
	my $cfg = new Config::IniFiles( -file => "$configfilename" );
	$cfg->Delete;
    };
    
    &create_default_config();
};


###################################################
### create a new configfile in home directory   ### 
### whenever the configfile is missing          ###
###################################################
sub create_default_config {
    my $newcfg = new Config::IniFiles();
    while (($k, $v) = each %confighash) {
	$newcfg->newval('defaults', $k, $v);
    };
    $newcfg->SetFileName($configfilename);
    $newcfg->RewriteConfig;
    
    return $newcfg;
};


1;
