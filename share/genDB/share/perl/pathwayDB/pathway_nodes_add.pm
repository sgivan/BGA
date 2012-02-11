########################################################################
#
# This module defines extensions to the automagically created file
# pathway_nodes.pm. Add your own code below.
#
########################################################################

1;

# get all objects from the database efficiently and return a hash reference
sub fetchallwith_path_id {
    my ($class, $req_path_id) = @_;
    local @pathway_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type 
	    FROM pathway_nodes 
		WHERE path_id=$req_path_id
	});
    $sth->execute;
    while (($compound_status, $compound_id, $path_id, $node_id, $id, $compound_type) = $sth->fetchrow_array) {
	my $pathway_nodes = {
		'compound_status' => $compound_status, 
		'compound_id' => $compound_id, 
		'path_id' => $path_id, 
		'node_id' => $node_id, 
		'id' => $id, 
		'compound_type' => $compound_type
		};
	bless($pathway_nodes, $class);
	push(@pathway_nodes, $pathway_nodes);
    }
    $sth->finish;
    return(\@pathway_nodes);
};


########################################################################
# get an @ containing all names of the external nodes
########################################################################
sub fetchall_ext_nodes {
    my ($class, $req_path_id) = @_;
    local %ext_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_nodes.id,compound_name FROM compound,pathway_nodes 
	    WHERE path_id=$req_path_id AND compound_type=0 AND compound_id=compound.id
	});
    $sth->execute;
    while (($p_n_id,$compound_name) = $sth->fetchrow_array) {
	$ext_nodes{$p_n_id}=$compound_name;
    }
    $sth->finish;
    return(%ext_nodes);
};




