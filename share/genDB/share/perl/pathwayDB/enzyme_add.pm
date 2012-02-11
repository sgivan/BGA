########################################################################
#
# This module defines extensions to the automagically created file
# enzyme.pm. Add your own code below.
#
########################################################################

1;

# get all objects from the database efficiently and return a hash reference
# get all EC-Numbers for a single pathway (ordered by EC-Number), remove duplicates and return ref on @pathway_enzymes
sub fetchallwith_path_id {
    my ($class, $req_path_id) = @_;
    local @pathway_enzymes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number FROM pathway_edges, pathway_nodes, enzyme 
	    WHERE path_id=$req_path_id AND source_id=pathway_nodes.id AND ec_id=enzyme.id ORDER BY enzyme_number
	});
    $sth->execute;
    while (($enzyme_number) = $sth->fetchrow_array) {
	push(@all_pathway_enzymes, $enzyme_number);
    }
    $sth->finish;
    $ec=shift(@all_pathway_enzymes);
    while ($ec) {
	push(@pathway_enzymes, $ec);
	$pec=shift(@all_pathway_enzymes);
	if ($ec ne $pec) {
	    
	    $ec=$pec;
	}
	else {
	    while ($ec eq $pec) {
		$ec=shift(@all_pathway_enzymes);
	    };
	};
    };
	
    return(\@pathway_enzymes);
};

sub getEC_occurence { #calculate the occurence of an enzyme number in different pathways
    my ($class,$ec)=@_;
    local $num=0;
    local $act=0;
    my $sth = $pathwayDB_DBH->prepare(qq {
	 SELECT path_id FROM pathway_nodes,pathway_edges,enzyme
	     WHERE source_id=pathway_nodes.id AND ec_id=enzyme.id AND enzyme_number='$ec'
	});
    $sth->execute;
    
    while (($pathway_id) = $sth->fetchrow_array) {
	if ($pathway_id > $act) {
	    $num++;
	    $act=$pathway_id;
	};
    };
    $sth->finish;
        
    return($num);
};
