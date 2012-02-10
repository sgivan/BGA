package GENDB::Pathways::getChunks;

$VERSION = 1.1;


require 5.003;
require Exporter;

use pathwayDB::pathway_chunks;
use pathwayDB::compound;
use pathwayDB::pathway_edges;

@ISA=Exporter;
@EXPORT=qw(get_chunks);


######################################
# get the chunks for a given pathway #
######################################
sub get_chunks {
    my ($path_id,$p_name, $ecs_ref, $progress_ref)=@_;

    my $pb=$$progress_ref;
    @allChunkNums=pathwayDB::pathway_chunks->fetchall_Chunk_Nums($path_id);
    %chunkScoreTab=();
    
    my $chunk_num=@allChunkNums;
    my $step=50/$chunk_num;
    my $act_pb_val=0;
    foreach $chk_num (@allChunkNums) {
	my ($src,$tar)=pathwayDB::pathway_chunks->fetch_src_tar($path_id,$chk_num); #get src and tar for chunk
	my $c_score=0;
	
	$chk_edge_ref=pathwayDB::pathway_chunks->fetch_chk_edges($path_id,$chk_num);
	@chunk_edges=@$chk_edge_ref;
	
	$s_str="";
	$prev=0;
	$ctr=0;
	while ($src ne $tar) {
	    $ctr++;	    
	    my ($f_label,$f_src)=fetch_next_source(\@chunk_edges,$prev,$src);
	    my ($count)=&check_edge_for_ECs($f_label,$ecs_ref);
	    $c_score+=$count;
	    $prev=$src;
	    $src=$f_src;
	};

	$perc = ($c_score/$ctr)*100+0.5;
	$percent = int $perc;
	
	$chunkScoreTab{$chk_num}=$percent;
	$act_pb_val+=$step;
	$pb->set_value(int $act_pb_val);
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	};	
    };
            
    return(\%chunkScoreTab);
};


##################################################
# get the next source node for chunk calculation #
##################################################
sub fetch_next_source {
    my ($edge_ref,$prev,$act)=@_;
    @chk_edgs=@$edge_ref;

    $nxt_chk_nr="";    
    foreach $e (@chk_edgs) {
	$e_src=$e->first_node;
	$e_tar=$e->last_node;
	$e_label=$e->chk_edge_label;
		
	if ($e_src eq $act && $e_tar ne $prev) {
	    return($e_label,$e_tar);
	}
	elsif ($e_tar eq $act && $e_src ne $prev) {
	    return($e_label,$e_src);
	}
	else {
	    next;
	};
    };	
};


###################################################################
# increment chunkscore if edge contains at least one annotated EC #
###################################################################
sub check_edge_for_ECs {
    my ($lab,$ecs_ref)=@_;

    my %path_ecs=%$ecs_ref;

    $count=0;
    if ($lab=~/.*\d.*/) {
	@ecs=split(',',$lab);
	foreach $ec (@ecs) {
	    if (exists $path_ecs{$ec}) {
		$count=1;
		last;
	    };
	};
    };
    
    return($count);
};



1;
