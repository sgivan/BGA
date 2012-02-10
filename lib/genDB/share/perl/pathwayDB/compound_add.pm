########################################################################
#
# This module defines extensions to the automagically created file
# compound.pm. Add your own code below.
#
########################################################################

1;

########################################################################
#
# method to fetch source and sink  of a single chunk  (used in makeChunkHtml.pl)
#
########################################################################

sub get_cmp_name {
    my ($class,$source)=@_;
    local $src="";
    
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name FROM compound,pathway_nodes WHERE compound_id=compound.id and pathway_nodes.id=$source
	});
    $sth->execute;
    
    if ($src = $sth->fetchrow_array) {
	$sth->finish;
	return($src);
    }
    else {
	$sth->finish;
	return(-1);
    };
};

