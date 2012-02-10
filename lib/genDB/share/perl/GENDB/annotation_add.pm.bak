########################################################################
#
# This module defines extensions to the automagically created file
# annotation.pm. Add your own code below.
#
# $Id: annotation_add.pm,v 1.3 2005/06/14 18:37:18 givans Exp $
#
########################################################################

use GENDB::annotation;

1;

###############################################################
# get all annotated ec-numbers from the database efficiently  #
# input: nothing (just the method call from annotation object #
# output: list of annotated ecs and                           #
#         hash with all annotation_ids for each ec-number     #
###############################################################
sub fetchall_ecs {
    my ($class) = @_;
    my $ecs = '';
    my $ec='';
    my $name='';
    my @ec_orfs=();
    my %orf_ecs=();
    my @annotations=();

    my $sth2 = $GENDB_DBH->prepare(qq {
	SELECT ec, id
	    FROM annotation
		WHERE orf_id=?
		    ORDER BY date DESC LIMIT 1
		    });

    my $sth = $GENDB_DBH->prepare(qq {
	SELECT orf_id 
	    FROM annotation 
		WHERE ec IS NOT NULL
		});

    $sth->execute;
    while (($orfid) = $sth->fetchrow_array) {
	
	$sth2->execute($orfid);
	while (($ec, $id) = $sth2->fetchrow_array) {
	    if ($ec=~/\./) {
		$ecs.=$ec.",";
		$orf_ecs{$ec}.=$id.",";
	    };
	};
	$sth2->finish;	
    };
    $sth->finish;

    return($ecs,\%orf_ecs);
};


###########################################
# return the latest annotation for an orf #
# input: orf_id                           #
# output: annotation object               #
###########################################
sub latest_annotation_init_orf_id {
    
    my ($class, $my_id) = @_;

    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, ec, id, category, offset, date FROM annotation
	    WHERE orf_id=$my_id
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

sub latest_annotation_init_orf_id_old {
    
    my ($class, $my_id) = @_;

    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT id FROM annotation
	    WHERE orf_id=$my_id
	    ORDER BY date DESC LIMIT 1
	    });
    
    $sth->execute;

    my @id = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id[0])) {
	return(-1);
    }
    else {
 	my $annotation = GENDB::annotation->init_id_old($id[0]);
	return($annotation);
    };
};


#########################
# delete by orf
#
# deletes all annotations associated to a given orf
#
#########################
sub delete_by_orf {
    my ($class, $orf) = @_;
    
    if (ref $orf) {
	$GENDB_DBH->do("delete from annotation where orf_id=".$orf->id);
    }
}

#############################
#
# get/set tool_id
#
#############################

sub tool_id {
    my ($self, $tool_id) = @_;
#    print "adding tool_id = $tool_id\n";
    return($self->getset('tool_id', $tool_id));
}


###########################
#
# old init_id
#
# doesn't return tool_id
#
###########################

sub init_id_old {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, offset, ec, feature_type, id, category, date FROM annotation WHERE id='$req_id'
	});
    $sth->execute;
    my ($product, $name, $annotator_id, $comment, $orf_id, $description, $offset, $ec, $feature_type, $id, $category, $date, $tool_id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $annotation = {
		'product' => $product, 
		'name' => $name, 
		'annotator_id' => $annotator_id, 
		'comment' => $comment, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'offset' => $offset, 
		'ec' => $ec, 
		'feature_type' => $feature_type, 
		'id' => $id, 
		'category' => $category, 
		'date' => $date,
		'tool_id' => $tool_id,
		};
        bless($annotation, $class);
        return($annotation);
    }
}
