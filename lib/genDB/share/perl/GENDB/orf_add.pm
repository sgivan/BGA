########################################################################
#
# This module defines extensions to the automagically created file
# orf.pm. Add your own code below.
#
########################################################################
# $Id: orf_add.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

$VERSION = 1.6;

use GENDB::orf_names;
use GENDB::annotation;
use GENDB::orfstate;
use GENDB::tool;
use GENDB::Common;
use GENDB::Config;

require Exporter;

@ISA = qw (Exporter);
@EXPORT = ('$ORF_STATE_PUTATIVE', '$ORF_STATE_ANNOTATED', '$ORF_STATE_IGNORED', '$ORF_STATE_FINISHED', '$ORF_STATE_ATTENTION_NEEDED', '$ORF_STATE_USER_1', '$ORF_STATE_USER_2', '@ORF_STATES');

1;


####################################################
# export global variables for different ORF states #
####################################################
$ORF_STATE_PUTATIVE         = 0;
$ORF_STATE_ANNOTATED        = 1;
$ORF_STATE_IGNORED          = 2;
$ORF_STATE_FINISHED         = 3;
$ORF_STATE_ATTENTION_NEEDED = 4;
$ORF_STATE_USER_1           = 5;
$ORF_STATE_USER_2           = 6;

# symbolic names for orf states
@ORF_STATES=('putative','annotated','ignored','finished','needs attention','user state 1','user state 2');


#################################################################################
#           !!!!!!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!!!!                    #
#                                                                               #
# The start position is the position of the _first_ base in the start codon!    #
# The stop position is the position of the _last_ base _before_ the stop codon! #
#                                                                               #
# Counting of positions starts with 1, e.g. the first base is at offset 1!      # 
# This is essential for calculating the length of the orf and retrieving the    #
# orf sequence!                                                                 #
#################################################################################


##############################
# return the sequence length #
##############################
sub length{
    my ($self)=@_;

    # remember to add 1 to length (see comment above)!
    return abs($self->stop-$self->start) + 1;
};


##################################################
# return the aminoacid length for a specific ORF #
##################################################
sub aalength{
    my ($self)=@_;

    return int($self->length/3)-1;            
};


##############################################
# return the dna sequence for a specific ORF #
##############################################
sub sequence{
    my ($self)=@_;
    
    $contig_id=$self->{'contig_id'};
    $contig=GENDB::contig->init_id($contig_id);
    if ($contig < 0) {
	print STDERR "Can't find contig".$self->{'contig'} if $DEBUG;
	die "No contig object for ".$contig->name." in orf_add::sequence!";

	return;
    };
 
    $start=$self->{'start'};
    $stop=$self->length;

    # start and stop are normalized, so start is
    # always less than stop
    # substr starts counting with 0, we start counting with 1
    $seq=substr($contig->sequence,$start-1,$stop);
    $seq = lc($seq); 
    if ($self->{'frame'} <0 ) { 
	# convert to reverse complement
	return reverse_complement($seq);
    }
    else {
	return $seq;
    };
};


###########################################
# return the stopcodon for a specific ORF #
###########################################
sub stopcodon {
    my ($self)=@_;
    
    $contig_id=$self->{'contig_id'};
    $contig=GENDB::contig->init_id($contig_id);
    if ($contig < 0) {
	print STDERR "can't find contig".$self->{'contig'} if $DEBUG;
	die "No contig object for ".$contig->name." in orf_add::stopcodon!";

	return;
    };

    $start=$self->{'start'} - 4;
    $stop=$self->{'stop'};
    
    if($self->frame < 0) {
	$start += 3;
    }
    else {
	$stop -= 3;
    };

    if ($self->{'frame'} < 0 ) {
	my $len = 3;
	if($start < 0 ) {
	    $len += $start;
	    $start = 0;
	};
	$seq=substr($contig->sequence,$start,$len);

	# convert to reverse complement
	return reverse_complement($seq);
    }
    else {
	$seq=substr($contig->sequence,$stop,3);
	return $seq;
    };
};


####################################
# return the alias names of an ORF #
####################################
sub alias_names {
    my( $self ) = @_;

    my $orf_id = $self->id;

    my $aliases = GENDB::orf_names->fetchbySQL( "orf_id = $orf_id" );
    my @ret;
    foreach (@$aliases) {
	push( @ret, $_->name );
    };

    return \@ret;
};


#############################################
# return the aa sequence for a specific ORF #
############################################# 
sub aasequence{
    my ($self)=@_;
    
    $dna=$self->sequence;
    $dna = substr($dna, 0, CORE::length($dna)-3);
    
    $aa=translate($dna);

    return $aa;
};


#####################################################################################################
# get all fact objects for a specific ORF from the database efficiently and return a hash reference #
#####################################################################################################
sub fetchfacts{
    my ($self) = @_;

    local %fact = ();
    
    $orf_id=$self->id;

    my $sth = $GENDB_DBH->prepare(qq {
	SELECT dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id FROM fact
	    WHERE orf_id='$orf_id'
	    });
    
    $sth->execute;
    
    while (($dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id) = $sth->fetchrow_array) {
	my $fact = {
	    'dbto' => $dbto, 
	    'tool_id' => $tool_id, 
	    'orfto' => $orfto, 
	    'dbfrom' => $dbfrom, 
	    'orffrom' => $orffrom, 
	    'dbref' => $dbref, 
	    'orf_id' => $orf_id, 
	    'description' => $description, 
	    'toolresult' => $toolresult, 
	    'id' => $id
	    };
	bless($fact, 'GENDB::fact');
	$fact{$id} = $fact;
    }
    $sth->finish;

    return(\%fact);
};


#############################################
# return "the best fact" for a specific ORF #
#############################################
sub best_fact {
    my ($self) = @_;

    local %fact = ();
    
    $orf_id=$self->id;

    my $sth = $GENDB_DBH->prepare(qq {
	SELECT level, dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id FROM fact
	    WHERE orf_id='$orf_id'
		SORT BY level LIMIT 1
		});
    
    $sth->execute;
    
    while (($level, $dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id) = $sth->fetchrow_array) {
	my $fact = {
	    'level' => $level, 
	    'dbto' => $dbto, 
	    'tool_id' => $tool_id, 
	    'orfto' => $orfto, 
	    'dbfrom' => $dbfrom, 
	    'orffrom' => $orffrom, 
	    'dbref' => $dbref, 
	    'orf_id' => $orf_id, 
	    'description' => $description, 
	    'toolresult' => $toolresult, 
	    'id' => $id
	    };
	bless($fact, 'GENDB::fact');
    }
    $sth->finish;

    return($fact);
};


#################################################
# return the number of facts for a specific ORF #
#################################################
sub no_fact {
    my ($self) = @_;

    my $self_id = $self->id;
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT count(*) FROM fact WHERE orf_id='$self_id'});
    
    $sth->execute();
    my ($number) = $sth->fetchrow_array;
    $sth->finish();

    return $number;
};


##########################################
# return the latest annotation of an ORF #
##########################################
sub latest_annotation {   
    my ($self) = @_;

    my $my_id=$self->id;

    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, ec, id, category, offset, date FROM annotation
	    WHERE orf_id='$my_id'
	    ORDER BY date DESC LIMIT 1
	    });
    
    $sth->execute;

    my ($product, $name, $annotator_id, $comment, $orf_id, $description, $ec, $id, $category, $offset, $date) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    }
    else {
	my $annotation = GENDB::annotation->init_id($id);   
	return($annotation);
    };
};


#####################################
# return the latest annotation name #
#####################################
sub latest_annotation_name {    
    my ($self) = @_;

    my $my_id=$self->id;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name FROM annotation
	    WHERE orf_id='$my_id'
	    ORDER BY date DESC LIMIT 1
	    });
    
    $sth->execute;
    my ($name) = $sth->fetchrow_array;
    $sth->finish;
    
    # if successful, return an appropriate object
    if (!defined($name)) {
	return(-1);
    }
    else {
	return ($name);
    };
};


###################################################
# return the annotations of a specific ORF object #
###################################################
sub fetch_annotations {    
    my ($self) = @_;
    my $self = shift;
    my $annotator_id = shift;

    $my_id=$self->id;
    local %annotations= ();
    my $query = qq { SELECT product, name, annotator_id, comment, orf_id, description, ec, id, category, offset, date FROM annotation WHERE orf_id='$my_id' };

    if ($annotator_id) {
      $query .= " AND annotator_id = $annotator_id";
    }

    # fetch the data from the database
#     my $sth = $GENDB_DBH->prepare(qq {
# 	SELECT product, name, annotator_id, comment, orf_id, description, ec, id, category, offset, date FROM annotation
# 	    WHERE orf_id='$my_id'
# 	    });
    my $sth = $GENDB_DBH->prepare($query);
    
    $sth->execute;
    while (($product, $name, $annotator_id, $comment, $orf_id, $description, $ec, $id, $category, $offset, $date) = $sth->fetchrow_array) {
	
	my $annotation = {
	    'product' => $product, 
	    'name' => $name, 
	    'annotator_id' => $annotator_id, 
	    'type' => $type, 
	    'comment' => $comment, 
	    'orf_id' => $orf_id, 
	    'description' => $description, 
	    'ec' => $ec, 
	    'id' => $id, 
	    'category' => $category, 
	    'conflevel' => $conflevel, 
	    'offset' => $offset,
	    'date' => $date
	    };
	
	bless($annotation, 'GENDB::annotation');
	$annotations{$id}=$annotation;
    }
    $sth->finish;

    return(\%annotations);
};    
    

######################################################
# this is not an object methods, it's a class method #
# return all ORfs with a given status                #
######################################################
sub fetchAllOrfsWithState {
    my ($class, $state) = @_;

    return GENDB::orf->fetchbySQL ("status = $state");
};


##################################################
# return the id of the next analysis tool to run #
##################################################
sub nexttool{
    my ($self) = @_;

    my $my_id=$self->id;
    
    my $level=($self->toollevel)+1;

    my $tool_aref = GENDB::tool->fetchbySQL("number=$level");
  
    @tools=@$tool_aref;
    if (! @tools) {
	return -1;
    };

    $tool = $tools[0]->id;
    
    return $tool;    
};

###################################
# delete facts for a specific ORF #
###################################
sub drop_facts {
    my( $self ) = @_;

    # delete facts
    for $fact (values %{$self->fetchfacts}) {
	$fact->delete;
    };
    
    # delete orfstates
    for $orfstate (@{GENDB::orfstate->fetchbySQL("orf_id=".$self->id)}) {
	$orfstate->delete;
    };

    $self->toollevel( 0 );
};


################################
# return the maximal toollevel #
################################
sub toollevel{
    my ($self) = @_;

    my $my_id=$self->id;
    
    my $jobs_aref = GENDB::orfstate->fetchbySQL("orf_id=$my_id");
    my @jobs=@$jobs_aref;
    
    my $maxtoollevel=0;

    foreach $job (@jobs) {
	$level= GENDB::tool->init_id($job->tool_id)->number;
	if ($level > $maxtoollevel) {
	    $maxtoollevel=$level;
	};
    };
    
    return $maxtoollevel;
};


#######################
# order jobs by level #
#######################
sub sort_jobs_level { 
    $a->number <=> $b->number;
};


###################################################
# create the next job in line for $orf            #
# and return the job_id (from the orfstate table) #
###################################################
sub order_next_job {
    my ($self, $verbose) = @_;

    my $my_id=$self->id;
    $nexttool_id= $self->nexttool; 
    
    if ($nexttool_id < 0) {
#	print STDERR "no next tool for orf :".$self->name."\n";
	return -1;
    };
    
    print STDERR "nexttool_id: $nexttool_id\n" if $verbose;
    
    $job=GENDB::orfstate->create($self->id,$nexttool_id);
    if ( $job < 0) {
	die "can't create job\n";
    }
    $job->date_ordered(time());
    
    return $job->id;
};


######################
# set orf alias name #
######################
sub set_orf_alias {
    my ($self,$alias) = @_;

    my $my_id=$self->id;
    
    # insert the data into the database
    $GENDB_DBH->do(qq {
	INSERT INTO orf_names (orf_id, name)
            VALUES ($my_id, '$alias')
           });
    if ($GENDB_DBH->err) {
	return(-1);
    };

    return;
};

##################
# delete_complete
#
# deletes this orf and all associated object,
# e.g. orfstates, annotations and facts
#
##################

sub delete_complete {
    my ($self) = @_;

    # delete annotations
  GENDB::annotation->delete_by_orf($self);

    # delete facts
  GENDB::fact->delete_by_orf($self);

    # delete orfstate

  GENDB::orfstate->delete_by_orf($self);

    # last not least...delete myself
    $self->delete;
}
 

####################
#
# fetchby_dbref
#
# fetches all ORFs with facts about given dbrefs
#
# parameter:  dbref     a single dbref or an array ref of dbrefs
#             tool_id   optional tool_id
#
# returns: array of orf objects
#
####################
sub fetchby_dbref {
    my ($class, $dbref, $tool_id) = @_;

    my $statement = 'SELECT orf.molweight, orf.contig_id, orf.startcodon, orf.name, orf.status, orf.stop, orf.ag, orf.gc, orf.frame, orf.isoelp, orf.id, orf.start FROM orf LEFT JOIN fact ON (fact.orf_id=orf.id) WHERE ';
    if (defined ($tool_id)) {
	$statement .= "fact.tool_id=$tool_id AND ";
    }
    if (ref($dbref)) {
	$statement .= '('.join (" OR ", map {"fact.dbref='$_'"} @$dbref).')';
    }
    else {
	$statement .= "fact.dbref='$dbref'";
    }

    # we only want a single hit per orf
    $statement .= " GROUP BY orf.id";

    my $sth = $GENDB_DBH->prepare($statement);
    $sth->execute;

    my @orfs;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, $class);
	push @orfs, $orf;
    }
    $sth->finish;
    return(\@orfs);
}    



sub get_new_coords {
  my ($self,$orf_id) = @_;

  my $sth = $GENDB_DBH->prepare("use SAR112_gendb");
  if (!$sth->execute()) {
    die "can't switch database to SAR112_gendb";
  }

  $sth = $GENDB_DBH->prepare("select start, stop from orf where id = ?");
  $sth->bind_param(1,$orf_id);

  if (!$sth->execute()) {
    die "can't execute select statement";
  }

  my ($start,$stop) = $sth->fetchrow_array();

   $sth = $GENDB_DBH->prepare("use SAR11_gendb");
   if (!$sth->execute()) {
     die "can't switch database to SAR11_gendb";
   }

  return [$start, $stop];
}
