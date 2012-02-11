#
# a helper module to read and store user defined configuration information
#
package GENDB::Tools::UserConfig;

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

use Config::IniFiles;
require Exporter;
@ISA = qw (Exporter);


# we store the data in a user-dependent file...
my $configfilename = $ENV{'HOME'}."/.gendbconfig.rc";


# predefined hash with complete default configuration
####################################################
######  !!! ADD an entry for EACH OPTION !!!  ######
####################################################
my %confighash = ( 'browser' => "netscape",
		   'show complete orflist' => "1",
		   'orf information' => "1",
		   'orf colors' => "state",
		   'signalp graphics mode' => "-G",
		   'signalp type' => "gram+",
		   'signalp format' => "summary",
		   'signalp trunc' => "80",
		   'orf_list' => '1,1,1,1,1,1,1,1,1,1,1,1,1',
		   'level_colors' => "green,blue,yellow,orange,white",
		   'orf_status_colors' => "green,blue,white,black,red,pink,lightyellow",
		   'selected_orf_status_colors' => 'darkgreen,darkblue,gray,black,darkred,purple,yellow'
    );

my %bufferhash;


###################################################
### get value of given parameter,               ###
###################################################
sub get_parameter {
    my ($self, $param) = @_;

    # buffer is set?
    if(defined $bufferhash{$param}) {
	return $bufferhash{$param};
    }

    my $retvalue="";
    if (-r $configfilename) {
	my $cfg = new Config::IniFiles( -file => "$configfilename", -default => "defaults" );
	### if userdefined parameter is empty default values are used automatically
	$retvalue = $cfg->val( 'userdefined', $param );    
    } 
    else {
	my $newcfg = &create_default_config();
	$retvalue = $newcfg->val( 'defaults', $param );
    };

    if ($retvalue eq '') {
	$retvalue = $confighash{$param};
	&set_parameter($self, $param, $retvalue);
    };

    # param 'level_colors' is a list
    if($param eq 'orf_status_colors' || $param eq 'selected_orf_status_colors' || $param eq 'level_colors') {
	$retvalue = [split(/,/, $retvalue)];
    }
    
    # set buffer
    $bufferhash{$param} = $retvalue;

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
	if ($cfg->setval( 'userdefined', $param, $value )) {
	}
	else {
	    my $r = $cfg->newval( 'userdefined', $param, $value );
	};
	$cfg->RewriteConfig;
    }
    else {
	my $newcfg = &create_default_config();
	$newcfg->setval( 'userdefined', $param, $value );
	$newcfg->RewriteConfig;
    };

    # param 'level_colors' is a list
    if($param eq 'orf_status_colors' || $param eq 'selected_orf_status_colors' || $param eq 'level_colors') {
	$retvalue = [split(/,/, $retvalue)];
    }
    $bufferhash{$param} = $value;
};


###################################################
### reset all values to default configuration   ###
###################################################
sub reset_parameters {
    %bufferhash = ();
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
