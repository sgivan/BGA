########################################################################
#
# This module defines extensions to the automagically created file
# fact.pm. Add your own code below.
#
########################################################################

use strict;
use QuerySRS;
use SeqDB;
use SeqDB::PlaybackReader;
require GENDB::tool;

1;

# use internal SRS 6.1 server
#QuerySRS->set_server("intern-6.1");

###################################
# create record URL for SRS entry #
###################################
sub SRSrecordURL {
    my ($self) = @_;

    my $used_tool = GENDB::tool->init_id ($self->tool_id());
    
    # delete the database delimiter (e.g. "gb|"). SRS cannot handle this
    my $dbid = $self->dbref();
    $dbid =~ s/^\w*\|//;
    
    my $dbnames = $used_tool->dburl;
    
    return QuerySRS::get_entry_URL($dbnames, $dbid);
};


#################
# get SRS entry #
#################
sub SRSrecord {
    my ($self) = @_;

    my $used_tool = GENDB::tool->init_id ($self->tool_id());
    
    # delete the database delimiter (e.g. "gb|"). SRS cannot handle this
    my $dbid = $self->dbref();
    $dbid =~ s/^\w*\|//;
    
    my $dbnames = $used_tool->dburl;
    my $entry = QuerySRS::get_html_entry($dbnames, $dbid);

    return $entry;
};


######################
# get database entry #
######################
sub dbentry {
    my ($self) = @_;

    my $used_tool = GENDB::tool->init_id ($self->tool_id());
    my $helper = $used_tool->helper_package;
    my $tool_dbentry=$helper->can ('dbentry');
    if ($tool_dbentry) {
        my $entry = &$tool_dbentry($self);
        return $entry if ($entry != -1);
    }

    # SRS fallback

    # delete the database delimiter (e.g. "gb|"). SRS cannot handle this
    my $dbid = $self->dbref();
    $dbid =~ s/^\w*\|//;
    
    my $dbnames = $used_tool->dburl;
    my $entry = QuerySRS::get_plain_entry($dbnames, $dbid);
    
    return $entry;
};


#########################
# get database sequence #
#########################
sub dbsequence  {
    my ($self) = @_;

    my $used_tool = GENDB::tool->init_id ($self->tool_id());
    my $helper = $used_tool->helper_package;
    my $tool_dbsequence=$helper->can ('dbsequence');
    if ($tool_dbsequence) {
        my $seq = &$tool_dbsequence($self);
        return $seq if ($seq ne "-1");
    }
    # SRS fallback
    my $dbnames = $used_tool->dburl;
    my $dbid = $self->dbref();
    $dbid =~ s/^\w*\|//;

    my $sequence=QuerySRS::get_fasta_entry($dbnames, $dbid);

    # remove fasta header
    $sequence =~ s/>[^\n]*\n//m;
    
    return $sequence;
};


##############################################################
# A number of additional attributes are derived from data    #
# stored inside a fact object. These attribute are evaluated #
# in a lazy fashion to increase overall speed.               #
##############################################################

###########################################
# extract EC number from fact description #
###########################################
sub EC_number {
    my( $self ) = @_;

    if( $self->description =~ /.*\(EC\s*(.*?)\).*/ ) {
        return $1;
    };

    return "";
};


#########################################
# get information out of database entry #
#########################################
sub _get_db_entry_information {
    my $self = shift;

    my $reader=SeqDB::PlaybackReader->new;
    $reader->load_string($self->dbentry);
    my $parser=SeqDB->new;
    my $data=$parser->parse($reader);
    
    my $dbid = $self->dbref();
    $dbid =~ s/^\w*\|//;
    if (ref $data) {
	$self->{gene_name} = $data->{entries}->{$dbid}->{gene_names};
	if (!defined ($self->{gene_name})) {
	    $self->{gene_name} = "";
	}
	# remove leading white spaces
	$self->{gene_name} =~ s/^\s*//;
    }
    else {
	$self->{gene_name} = "";
    }
};


##############################################
# extract gene product from fact description #
##############################################
sub gene_product {
    my( $self ) = @_;

    return $self->description;
};


###########################################
# extract gene name from fact description #
###########################################
sub gene_name {
    my( $self ) = @_;
    
    if (!exists $self->{gene_name}) {
        $self->_get_db_entry_information;
    };
    
    return $self->{gene_name};
};


######################################################
# get information derived from fact and tool objects #
######################################################
sub _get_fact_and_tool_information {
    my ($self) = @_;

    my $tool= GENDB::tool->init_id($self->tool_id);

    $self->{level} = $tool->level($self);
    $self->{score} = $tool->score($self);
    $self->{bits} = $tool->bits($self);
};


################################################
# extract score from fact and tool information #
################################################
sub score {
    my( $self ) = @_;

    if (!exists $self->{score}) {
        $self->_get_fact_and_tool_information;
    };

    return $self->{score};
};


###################################################
# get bits information from fact and tool objects #
###################################################
sub bits {
    my( $self ) = @_;

    if (!exists $self->{bits}) {
        $self->_get_fact_and_tool_information;
    };

    return $self->{bits};
};


#########################################################
# get tool level information from fact and tool objects #
#########################################################
sub level {
    my ($self) = @_;

    if(!exists $self->{level}) {
        $self->_get_fact_and_tool_information;
    };

    return $self->{level};
};


#########################
# fetchby_tool
#
# returns an arrayref of all fact generated 
# by a given tool
#
#########################
sub fetchby_tool {
    my ($class, $tool) = @_;

    return undef if (!ref $tool);
    return $class->fetchbySQL("tool_id=".$tool->id);
}

#########################
# delete by orf
#
# deletes all fact associated to a given orf
#
#########################
sub delete_by_orf {
    my ($class, $orf) = @_;
    
    if (ref $orf) {
	$GENDB_DBH->do("delete from fact where orf_id=".$orf->id);
    }
}

#########################
# delete by tool
#
# deletes all fact associated to a given tool
#
#########################
sub delete_by_tool {
    my ($class, $tool) = @_;
    
    if (ref $tool) {
	$GENDB_DBH->do("delete from fact where tool_id=".$tool->id);
    }
}

