########################################################################
#
# This module defines extensions to the automagically created file
# pathway_edges.pm. Add your own code below.
#
########################################################################

use pathwayDB::enzyme;
use pathwayDB::label;

# get all objects from the database efficiently and return a hash reference
# return ref on all edge-objects where ecs are collaborated to single label 
# evtl. neuprogrammieren als iteration ueber die verschiedenen source-target kombinationen

sub fetchallwith_path_id {
    my ($class, $req_path_id) = @_;
    local @path_edges = ();
    local $label="";

    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT source_id, target_id, ec_id, label_id, status FROM pathway_edges, pathway_nodes 
	    WHERE path_id=$req_path_id AND source_id = pathway_nodes.id ORDER BY source_id, target_id
	});
    $sth->execute;
    $tmp_path_edge=Pathway_Edges->new(0, 0, 0, 0);

    while (($source_id, $target_id, $ec_id, $label_id, $status) = $sth->fetchrow_array) {
	$source_id=N.$source_id;
	$target_id=N.$target_id;
 
	$tmp_source=$tmp_path_edge->source;
	if ($tmp_source ne 0) { 
	    if ($source_id eq $tmp_path_edge->source && $target_id eq $tmp_path_edge->target) {
		$label=$tmp_path_edge->label;
	    }
	    else {
		$label=$tmp_path_edge->label;
		chop($label);
		$tmp_path_edge->label($label);
		push(@path_edges, $tmp_path_edge);
		$label="";
	    };
	};

	if ($ec_id == 0) {
	    $label_obj=pathwayDB::label->init_id($label_id);
	    $lbl=$label_obj->label;
	    $path_edge=Pathway_Edges->new($source_id, $target_id, $lbl, $status);
	    push(@path_edges, $path_edge);
	    $tmp_path_edge=Pathway_Edges->new(0, 0, 0, 0);
	}
	else {
	    $enzyme_obj=pathwayDB::enzyme->init_id($ec_id);
	    $ec_num=$enzyme_obj->enzyme_number;
	    $label.=$ec_num.',';
	    $tmp_path_edge=Pathway_Edges->new($source_id,$target_id,$label,$status);
	};
    };	
    $label=$tmp_path_edge->label;
    if ($label ne 0) {
	chop($label);
	$tmp_path_edge->label($label);
	push(@path_edges, $tmp_path_edge);
    };
    $sth->finish;
    return(\@path_edges);
};

########################################################################
#
# method to access all pathway_edges with same source and target (used in Chunk&PathToDB
#
########################################################################

sub get_pathway_edges_ids {
    my ($class,$p_id,$e_source,$e_target)=@_;
    local @ids = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_edges.id FROM pathway_edges,pathway_nodes 
	    WHERE path_id=$p_id AND source_id=$e_source AND target_id=$e_target AND source_id=pathway_nodes.id
	});
    $sth->execute;
    while (($pathway_edges_id) = $sth->fetchrow_array) {
	push(@ids, $pathway_edges_id);
    }
    $sth->finish;
    return(@ids);
};


########################################################################
#
# method to fetch all outgoing edges of a node in a chunk (used in makeChunkHtml.pl)
#
########################################################################

sub fetch_outgoing_edges_in_s {
    my ($class,$p_id,$c_num,$src)=@_;
    local @src_edges=();
    local $s_label="";
    local $s_e_id="";
    local $s_so_id="";
    local $s_ta_id="";
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_edges.id,source_id,target_id,enzyme_number
	    FROM pathway_chunks,pathway_edges,pathway_nodes,enzyme 
		WHERE path_id=$p_id AND number=$c_num AND pathway_edges_id=pathway_edges.id AND source_id=pathway_nodes.id AND ec_id=enzyme.id AND source_id=$src
	});
    $sth->execute;
    
    while (($s_edge_id,$s_s_id,$s_t_id,$s_ec_num) = $sth->fetchrow_array) {
	$s_label.='EC:'.$s_ec_num.',';
	$s_e_id=$s_edge_id;
	$s_so_id=$s_s_id;
	$s_ta_id=$s_t_id;
    };
    #print "pathway_edges::in s: $s_label, $s_e_id,$s_so_id,$s_ta_id \n";
    my $edge = {
		's_edge_id' => $s_e_id, 
		's_s_id' => $s_so_id, 
		's_t_id' => $s_ta_id, 
		's_label' => $s_label
		};
    $sth->finish;
    #print "fetched edge_id in s $s_e_id \n";
    return($edge);
};

########################################################################
#
# method to fetch all outgoing edges of a node in a chunk (used in makeChunkHtml.pl)
#
########################################################################

sub fetch_outgoing_edges_in_t {
    my ($class,$p_id,$c_num,$src)=@_;
    local @src_edges=();
    local $t_label="";
    local $t_e_id="";
    local $t_so_id="";
    local $t_ta_id="";
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_edges.id,source_id,target_id,enzyme_number
	    FROM pathway_chunks,pathway_edges,pathway_nodes,enzyme 
		WHERE path_id=$p_id AND number=$c_num AND pathway_edges_id=pathway_edges.id AND source_id=pathway_nodes.id AND ec_id=enzyme.id AND target_id=$src
	});
    $sth->execute;
    
    while (($t_edge_id,$t_s_id,$t_t_id,$t_ec_num) = $sth->fetchrow_array) {
	$t_label.='EC:'.$t_ec_num.',';
	$t_e_id=$t_edge_id;
	$t_so_id=$t_s_id;
	$t_ta_id=$t_t_id;
    };
    print "pathway_edges::in t: $t_label, $t_e_id,$t_so_id,$t_ta_id \n";
    my $edge = {
		't_edge_id' => $t_e_id, 
		't_s_id' => $t_so_id, 
		't_t_id' => $t_ta_id, 
		't_label' => $t_label
		};
    $sth->finish;
    print "fetched edge_id in t  $t_e_id \n";
    return($edge);
};

########################################################################
#
# method to access all pathway_edges of a SUBWAY (used in DBsubway_viewer)
#
########################################################################

sub getSubwayEdges {
    my ($class,$p_id,$sub_path_nr,$sub_path_chunks)=@_;

    $sub_path_chunks=~s/,/,C/g;
    $sub_path_chunks='C'.$sub_path_chunks.',';

    local $e_str="";
    my $sth = $pathwayDB_DBH->prepare(qq {
	 SELECT source_id,target_id,pathway_chunks.number
	     FROM pathway_sub_paths,pathway_chunks,pathway_edges,pathway_nodes 
		 WHERE pathway_chunks.id=pathway_chunks_id AND pathway_edges.id=pathway_edges_id 
		     AND source_id=pathway_nodes.id AND path_id=$p_id AND pathway_sub_paths.number=$sub_path_nr
    });
    $sth->execute;
    while (($source_id,$target_id,$c_number) = $sth->fetchrow_array) {
	if ($sub_path_chunks=~/C$c_number,/) {
	    $e_str.='N'.$source_id.'-'.'N'.$target_id.':';
	};
    };
    $sth->finish;
    chop($e_str);
    return($e_str);
};



########################################################################
#
# methods to access the member variables
#
########################################################################

package Pathway_Edges;

sub new {
    my ($class, $sn_id, $tn_id, $lab, $est) = @_;
    my $edge = {'source' => $sn_id,
                'target' => $tn_id,
		'label'  => $lab,
		'estatus' => $est,
		};
    bless($edge, $class);
    return($edge);
};

sub source {
    my ($self,$source) = @_;
        if ($source) {
            $self->{'source'} = $source;
        } else {
            return($self->{'source'});
        }
};


sub target {
    my ($self,$target) = @_;
        if ($target) {
            $self->{'target'} = $target;
        } else {
            return($self->{'target'});
        }
};

sub label {
    my ($self,$label) = @_;
        if ($label) {
            $self->{'label'} = $label;
        } else {
            return($self->{'label'});
        }
};

sub estatus {
    my ($self,$estatus) = @_;
        if ($estatus) {
            $self->{'estatus'} = $estatus;
        } else {
            return($self->{'estatus'});
        };
};


1;

