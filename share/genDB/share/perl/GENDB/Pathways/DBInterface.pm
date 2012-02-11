package GENDB::Pathways::DBInterface;

$VERSION = 1.0;

use pathwayDB::pathway;
use pathwayDB::pathway_nodes;
use pathwayDB::pathway_edges;
use pathwayDB::compound;
use pathwayDB::enzyme;

require 5.003;
require Exporter;

@ISA=Exporter;
@EXPORT=qw(getAllNodes getAllEdges getAllPathECs getPathId);


###########################################
# get pathway id for a given pathway name #
###########################################
sub getPathId {
    my $path=shift;
    $pathway=pathwayDB::pathway->init_pathway_name($path);
    if ($pathway == -1) {
	print "pathwayDB::pathway: No Object $pathway_name in DB!\n";
    }
    else {
	$p_id=$pathway->id;
	
    };
    return $p_id;
};


####################################
# get all node for a given pathway #
####################################
sub getAllNodes {
    my $path=shift;

    $path_id=&getPathId($path);
    @allnodes = ();
    $allDBnodes_ref=pathwayDB::pathway_nodes->fetchallwith_path_id($path_id);
    @allDBnodes=@$allDBnodes_ref;
    foreach $DBnode (@allDBnodes) {
	$DBnod_id=$DBnode->id;
	$nid=N.$DBnod_id;

	$DBcomp_id=$DBnode->compound_id;
	$DBcompound=pathwayDB::compound->init_id($DBcomp_id);
	$name=$DBcompound->compound_name;
	
	$comp_st=$DBnode->compound_status;
	$comp_tp=$DBnode->compound_type;

	$node=Nodes->new($nid, $comp_st, $name, $comp_tp);
	push(@allnodes, $node);
    }; 

    return @allnodes;
};


#####################################
# get all edges for a given pathway #
#####################################
sub getAllEdges {
    my $path=shift;

    $path_id=&getPathId($path);
    @allEdges = ();
    $allDBedges_ref=pathwayDB::pathway_edges->fetchallwith_path_id($path_id);
    # new edge objects have methods for source, target, label and estatus
    @allEdges=@$allDBedges_ref;
   
    return @allEdges;
};


##########################################
# get all ec numbers for a given pathway #
##########################################
sub getAllPathECs {
    my $path=shift;

    $path_id=&getPathId($path);
    @allPathECs = (); 
    $allPathECs_ref=pathwayDB::enzyme->fetchallwith_path_id($path_id);
    @allPathECs=@$allPathECs_ref;
    
    return @allPathECs;
};


#########################################################
### Object-Definitions for new pathway graph node class #
#########################################################

package Nodes;

sub new {
    my ($class, $nid, $status, $name, $type) = @_;

    my $knoten = {'title' => $nid, 
		  'status' => $status,
		  'name' => $name,
		  'type' => $type
		};

    bless($knoten, $class);
    return($knoten);
};

#get or set title
sub title {
    my ($self, $title) = @_;
    if ($title) {
	$self->{'title'} = $title;
    }
    else {
	return($self->{'title'});
    };
};

#get or set status
sub status {
    my ($self, $status) = @_;
    if ($status) {
	$self->{'status'} = $status;
    }
    else {
	return($self->{'status'});
    };
};

#get or set name
sub name {
    my ($self, $name) = @_;
    if ($name) {
	$self->{'name'} = $name;
    }
    else {
	return($self->{'name'});
    };
};

#get or set type
sub type {
    my ($self, $type) = @_;
    if ($type) {
	$self->{'type'} = $type;
    }
    else {
	return($self->{'type'});
    };
};


1;
