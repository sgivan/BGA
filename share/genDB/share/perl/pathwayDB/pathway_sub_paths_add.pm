########################################################################
#
# This module defines extensions to the automagically created file
# pathway_sub_paths.pm. Add your own code below.
#
########################################################################


1;

########################################################################
# get all objects from the database efficiently and return an array reference
########################################################################
sub get_selected_sub_paths {
    my ($class,$path_id,$src,$tar)=@_;

    local @sel_paths = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_sub_paths.number,pathway_chunks.number,src_pathway_nodes_id,tar_pathway_nodes_id
	    FROM pathway_sub_paths,pathway_chunks,pathway_nodes, pathway_edges 
		WHERE path_id=$path_id AND pathway_edges.id=pathway_edges_id AND pathway_chunks_id=pathway_chunks.id 
		    AND ext_src_pathway_nodes_id=$src AND ext_tar_pathway_nodes_id=$tar AND pathway_nodes.id=source_id
			ORDER BY pathway_sub_paths.number,pathway_chunks.number
	});
    $sth->execute;
    $int=0;
    $new_path=0;
    $act_path=0;
    @chk_nums=();
    @path_chunks=();

    while (($path_num,$chunk_num,$chunk_src_id,$chunk_tar_id) = $sth->fetchrow_array) {
	if ($new_path eq 0) {
	    $new_path=$path_num;
	    $path=Path->new($path_num,$src,$tar);
	};

      	if ($path_num eq $new_path) {
	    if ($chunk_num > $int) {
		$chk_str.=$chunk_num.',';
		$int=$chunk_num;		
		$chunk=Chunk->new($chunk_num,$chunk_src_id,$chunk_tar_id);
		push(@path_chunks,$chunk);
	    };   
	} 
	else {	    
	    $new_path=$path_num;
	    chop($chk_str);
	    $path->chunk_string($chk_str);
	    $s_path=sort_chunks_in_path($path,\@path_chunks);
	    push(@sel_paths, $s_path);
	    @path_chunks=();
	    
	    $chk_str="";
	    $chk_str.=$chunk_num.',';
	    $int=$chunk_num;
	    $chunk=Chunk->new($chunk_num,$chunk_src_id,$chunk_tar_id);
	    push(@path_chunks,$chunk);
	    
	    $path=Path->new($path_num,$src,$tar);
	};
    };
    chop($chk_str);
    $path->chunk_string($chk_str);
    $s_path=sort_chunks_in_path($path,\@path_chunks);
    push(@sel_paths, $s_path);

    $sth->finish;
    return(\@sel_paths);
};

########################################################################

sub sort_chunks_in_path {
    my ($spth,$p_chunks_ref)=@_;
    @p_chunks=@$p_chunks_ref;

    $p_num=$spth->p_number;
    $p_src=$spth->p_source;
    $p_tar=$spth->p_target;
    $p_chks=$spth->chunk_string;
        
    foreach $chk (@p_chunks) {
	$chk_num=$chk->c_number;
	$chk_src=$chk->c_source;
	$chk_tar=$chk->c_target;
    };
    
    $ck_str="";
    $prev_node=0;
    $act_node=$p_src;
    
    while ($act_node ne $p_tar) {
	my ($chk_key,$act_n)=get_next_chunk_number($act_node,$prev_node,\@p_chunks);
		
	$ck_str.=$chk_key.',';
	$prev_node=$act_node;
	$act_node=$act_n;
    };

    chop($ck_str);
    $spath=Path->new($p_num,$p_src,$p_tar);
    $spath->chunk_string($ck_str);
        
    return($spath);
};

########################################################################

sub get_next_chunk_number {
    my ($act_node,$prev_node,$p_chks_ref)=@_;
    @p_chks=@$p_chks_ref;
    $nxt_chk_nr="";
    
    foreach $chk (@p_chunks) {
	$chk_num=$chk->c_number;
	$chk_src=$chk->c_source;
	$chk_tar=$chk->c_target;
	
	if ($chk_src eq $act_node && $chk_tar ne $prev_node) {
	    return($chk_num,$chk_tar);
	}
	elsif ($chk_tar eq $act_node && $chk_src ne $prev_node) {
	    return($chk_num,$chk_src);
	}
	else {
	    next;
	};
    };	
    #print "get_next_chunk_number:: FAILED!!!\n";
};


########################################################################
# Package Declarations
########################################################################
package Path;

sub new {
    my ($class, $p_num,$src,$tar) = @_;
    my $path = {'p_number' => $p_num, 
		'p_src' => $src,
		'p_tar' => $tar,
		'p_chunks' => ''
		};
    bless($path, $class);
    return($path);
};

#get or set PathNumber
sub p_number {
    my ($self, $p_number) = @_;
    if ($p_number) {
	$self->{'p_number'} = $p_number; 
    } 
    else {
	return($self->{'p_number'});
    };
};


#get or set Path source
sub p_source {
    my ($self, $p_src) = @_;
    if ($p_src) {
	$self->{'p_src'} = $p_src; 
    } 
    else {
	return($self->{'p_src'});
    };
};

#get or set Path target
sub p_target {
    my ($self, $p_tar) = @_;
    if ($p_tar) {
	$self->{'p_tar'} = $p_tar;
    } 
    else {
	return($self->{'p_tar'});
    };
};

#get or set Chunkstring
sub chunk_string {
    my ($self, $c_str) = @_;
    if ($c_str) {
	$self->{'p_chunks'} = $c_str;
    } 
    else {
	return($self->{'p_chunks'});
    };
};

##############################################
package Chunk;

sub new {
    my ($class, $c_num,$c_src,$c_tar) = @_;
    my $chunk = {'c_number' => $c_num, 
		'c_src' => $c_src,
		'c_tar' => $c_tar
		};
    bless($chunk, $class);
    return($chunk);
};

#get or set Chunk-Number
sub c_number {
    my ($self, $c_number) = @_;
    if ($c_number) {
	$self->{'c_number'} = $c_number; 
    } 
    else {
	return($self->{'c_number'});
    };
};


#get or set Path source
sub c_source {
    my ($self, $c_src) = @_;
    if ($c_src) {
	$self->{'c_src'} = $c_src; 
    } 
    else {
	return($self->{'c_src'});
    };
};

#get or set Chunk target
sub c_target {
    my ($self, $c_tar) = @_;
    if ($c_tar) {
	$self->{'c_tar'} = $c_tar;
    } 
    else {
	return($self->{'c_tar'});
    };
};
