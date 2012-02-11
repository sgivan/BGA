########################################################################
#
# This module defines extensions to the automagically created file
# pathway_chunks.pm. Add your own code below.
#
########################################################################

use pathwayDB::label;
1;

########################################################################
#
# method to access all chunks with same number in a single pathway (used in Chunk&PathToDB)
#
########################################################################

sub get_all_chunk_ids {
    my ($class,$p_id,$c_num)=@_;
    local @ids = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_chunks.id FROM pathway_chunks,pathway_edges,pathway_nodes WHERE path_id=$p_id AND number=$c_num AND pathway_edges_id=pathway_edges.id AND source_id=pathway_nodes.id
	});
    $sth->execute;
    while (($chunk_id) = $sth->fetchrow_array) {
	push(@ids, $chunk_id);
    }
    $sth->finish;
    return(@ids);
};

########################################################################
#
# method to fetch all chunks of a single pathway where Edges are collaborated (used in createChunkHtml.pl)
#
########################################################################

sub fetchall_Chunk_Nums {
    my ($class,$p_id)=@_;
    local @allChunks=();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT number FROM pathway_chunks,pathway_edges,pathway_nodes WHERE path_id=$p_id AND pathway_edges_id=pathway_edges.id AND source_id=pathway_nodes.id ORDER BY number
	});
    $sth->execute;
    $int=0;
    @chk_nums=();
    while ($number = $sth->fetchrow_array) {
	if ($number > $int) {
	    push(@chk_nums,$number);
	    $int=$number;
	};
    }; 
    $sth->finish;
    return(@chk_nums);
};
    
########################################################################
#
# method to fetch source and sink  of a single chunk  (used in makeChunkHtml.pl)
#
########################################################################

sub fetch_src_tar {
    my ($class,$p_id,$c_num)=@_;
    local $src="";
    local $tar="";
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT src_pathway_nodes_id,tar_pathway_nodes_id FROM pathway_chunks,pathway_edges,pathway_nodes WHERE path_id=$p_id AND number=$c_num AND pathway_edges_id=pathway_edges.id AND source_id=pathway_nodes.id
	});
    $sth->execute;
    
    if (($src,$tar) = $sth->fetchrow_array) {
	$sth->finish;
	return($src,$tar);
    }
    else {
	$sth->finish;
	return(-1);
    };
};


########################################################################
#
# method to fetch all colaborated edges of a single chunk  (used in makeChunkHtml.pl)
#
########################################################################

sub fetch_chk_edges {
    my ($class,$p_id,$c_num)=@_;
        
    local $src="";
    local $tar="";
    my @chk_edges=();
    my @non_ec_chk_edges=();
    my @ec_chk_edges=();
    
#    SELECT pathway_edges.source_id,
#        pathway_edges.target_id,
#        enzyme.enzyme_number
#FROM pathway_edges, pathway_nodes, pathway_chunks, enzyme
#         WHERE
#                pathway_edges.source_id = pathway_nodes.id
#                AND pathway_edges.id = pathway_chunks.pathway_edges_id
#                AND enzyme.id = pathway_edges.ec_id
#                AND pathway_chunks.number = 12
 #               AND pathway_nodes.path_id = 7



    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT source_id,target_id,enzyme_number
	    FROM pathway_edges,pathway_nodes,pathway_chunks,enzyme 
		WHERE path_id=$p_id AND number=$c_num AND source_id=pathway_nodes.id 
		    AND pathway_edges.id=pathway_edges_id AND enzyme.id=ec_id 
			ORDER BY source_id,target_id
	});
    $sth->execute;
    
    $ec_str="";
    while (($src,$tar,$ec_num) = $sth->fetchrow_array) {
	my $chunk_edg=Chunk_Edges->new($src,$tar,$ec_num);
	push(@ec_chk_edges,$chunk_edg);
    };
    $sth->finish;  

    ######################################################
    #### collaborate ec_chk_edges with several ec_numbers
    ######################################################
    my $e_label="";
    $prev_src=0;
    $prev_tar=0;
    foreach $edg (@ec_chk_edges) {
	$src=$edg->first_node;
	$tar=$edg->last_node;
	$ec=$edg->chk_edge_label;

	if ($src==$prev_src && $tar==$prev_tar) {
	    $e_label.=$ec.',';
	    next;
	}
	else {
	    if ($prev_src ne 0) {
		chop($e_label);
		$e_obj=Chunk_Edges->new($prev_src,$prev_tar,$e_label);
		push(@chk_edges,$e_obj);
	    };
	    $e_label=$ec.',';
	    $prev_src=$src;
	    $prev_tar=$tar;
	};	
    };
    chop($e_label);
    $e_obj=Chunk_Edges->new($prev_src,$prev_tar,$e_label);
    push(@chk_edges,$e_obj);
    
    ##################################################
    ### get the edges of the chunk without EC_number
    ##################################################
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT source_id,target_id,label
	    FROM pathway_edges,pathway_nodes,pathway_chunks,label
		WHERE path_id=$p_id AND number=$c_num AND source_id=pathway_nodes.id 
		    AND pathway_edges.id=pathway_edges_id AND label.id=label_id 
			ORDER BY source_id,target_id
	});
    $sth->execute;
    
    while (($src,$tar,$label) = $sth->fetchrow_array) {
	my $chunk_edg=Chunk_Edges->new($src,$tar,$label);
	push(@chk_edges,$chunk_edg);
    };
    $sth->finish;  
    
    return(\@chk_edges);
};


########################################################################
#
# methods to access the member variables
#
########################################################################

package Chunks;

sub new {
    my ($class, $cid) = @_;
    my $chunk = {'number' => $cid, 
		 'cnodes' => '',
		 'firstnode' => '',
		 'lastnode' => '',
		 'chunkedges' => '',
		 'score' => '',
		};
    bless($chunk, $class);
    return($chunk);
}

#get or set Chunknumber
sub number {
    my ($self, $number) = @_;
    if ($number) {
	$self->{'number'} = $number; 
    } 
    else {
	return($self->{'number'});
    }
};


#get or set Chunknodes as String in topological order
sub cnodes {
    my ($self, $cnodes) = @_;
    if ($cnodes) {
	$self->{'cnodes'} = $cnodes; 
    } 
    else {
	return($self->{'cnodes'});
    }
};

#get or set first Chunknode
sub firstnode {
    my ($self, $firstn) = @_;
    if ($firstn) {
	$self->{'firstnode'} = $firstn;
    } 
    else {
	return($self->{'firstnode'});
    }
};

#get or set last Chunknode
sub lastnode {
    my ($self, $lastn) = @_;
    if ($lastn) {
	$self->{'lastnode'} = $lastn;
    } 
    else {
	return($self->{'lastnode'});
    }
};

#get or set the Edges of a Chunk (NxNy, etc)
sub chunkedges {
    my ($self, $cedg) = @_;
    if ($cedg) {
	$self->{'chunkedges'} = $cedg;
    } 
    else {
	return($self->{'chunkedges'});
    }
};

#get Chunk-Score
sub score {
    my ($self, $score) = @_;
    return($self->{'score'});
};

#set Chunk-Score
sub setscore {
    my ($self, $score) = @_;
    $self->{'score'} = $score;
};

########################################################################
#
# methods to access the member variables of PACKAGE CHUNK_EDGES
#
########################################################################

package Chunk_Edges;

sub new {
    my ($class,$src,$tar,$lab) = @_;
    my $chk_edge = {'firstnode' => $src,
		    'lastnode' => $tar,
		    'chk_edge_label' => $lab
		    };
    bless($chk_edge, $class);
    return($chk_edge);
}

#get or set firstnode
sub first_node {
    my ($self, $src) = @_;
    if ($src) {
	$self->{'firstnode'} = $src; 
    } 
    else {
	return($self->{'firstnode'});
    }
};


#get or set lastnode
sub last_node {
    my ($self, $tar) = @_;
    if ($tar) {
	$self->{'lastnode'} = $tar; 
    } 
    else {
	return($self->{'lastnode'});
    }
};

#get or set label of an edge
sub chk_edge_label {
    my ($self, $lab) = @_;
    if ($lab) {
	$self->{'chk_edge_label'} = $lab;
    } 
    else {
	return($self->{'chk_edge_label'});
    }
};

