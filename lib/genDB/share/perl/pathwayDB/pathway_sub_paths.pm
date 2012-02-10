########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_sub_paths_add.pm.
#
########################################################################

package pathwayDB::pathway_sub_paths;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway_sub_paths
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $number, $pathway_chunks_id, $ext_src_pathway_nodes_id, $ext_tar_pathway_nodes_id) = @_;
    # fetch a fresh id
    my $id = newid('pathway_sub_paths');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway_sub_paths (id, number, pathway_chunks_id, ext_src_pathway_nodes_id, ext_tar_pathway_nodes_id)
            VALUES ($id, '$number', '$pathway_chunks_id', '$ext_src_pathway_nodes_id', '$ext_tar_pathway_nodes_id')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway_sub_paths = {
		'id' => $id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id
	};
    bless($pathway_sub_paths, $class);
    return($pathway_sub_paths);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT ext_tar_pathway_nodes_id, ext_src_pathway_nodes_id, number, pathway_chunks_id, id FROM pathway_sub_paths
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($ext_tar_pathway_nodes_id, $ext_src_pathway_nodes_id, $number, $pathway_chunks_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_sub_paths = {
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'id' => $id
		};
	bless($pathway_sub_paths, $class);
	return($pathway_sub_paths);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway_sub_paths = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT ext_tar_pathway_nodes_id, ext_src_pathway_nodes_id, number, pathway_chunks_id, id FROM pathway_sub_paths
	});
    $sth->execute;
    while (($ext_tar_pathway_nodes_id, $ext_src_pathway_nodes_id, $number, $pathway_chunks_id, $id) = $sth->fetchrow_array) {
	my $pathway_sub_paths = {
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'id' => $id
		};
	bless($pathway_sub_paths, $class);
	$pathway_sub_paths{$id} = $pathway_sub_paths;
    }
    $sth->finish;
    return(\%pathway_sub_paths);
}

# create an object for already existing data
sub init_number_pathway_chunks_id_ext_src_pathway_nodes_id_ext_tar_pathway_nodes_id {
    my ($class, $req_number, $req_pathway_chunks_id, $req_ext_src_pathway_nodes_id, $req_ext_tar_pathway_nodes_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT ext_tar_pathway_nodes_id, ext_src_pathway_nodes_id, number, pathway_chunks_id, id FROM pathway_sub_paths
		WHERE number='$req_number' AND pathway_chunks_id='$req_pathway_chunks_id' AND ext_src_pathway_nodes_id='$req_ext_src_pathway_nodes_id' AND ext_tar_pathway_nodes_id='$req_ext_tar_pathway_nodes_id'
	});
    $sth->execute;
    my ($ext_tar_pathway_nodes_id, $ext_src_pathway_nodes_id, $number, $pathway_chunks_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_sub_paths = {
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'id' => $id
		};
	bless($pathway_sub_paths, $class);
	return($pathway_sub_paths);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_number_pathway_chunks_id_ext_src_pathway_nodes_id_ext_tar_pathway_nodes_id {
    my ($class) = @_;
    local %pathway_sub_paths = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT ext_tar_pathway_nodes_id, ext_src_pathway_nodes_id, number, pathway_chunks_id, id FROM pathway_sub_paths
	});
    $sth->execute;
    while (($ext_tar_pathway_nodes_id, $ext_src_pathway_nodes_id, $number, $pathway_chunks_id, $id) = $sth->fetchrow_array) {
	my $pathway_sub_paths = {
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'id' => $id
		};
	bless($pathway_sub_paths, $class);
	my $key = join(',', $number, $pathway_chunks_id, $ext_src_pathway_nodes_id, $ext_tar_pathway_nodes_id);
	$pathway_sub_paths{$key} = $pathway_sub_paths;
    }
    $sth->finish;
    return(\%pathway_sub_paths);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway_sub_paths = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT ext_tar_pathway_nodes_id, ext_src_pathway_nodes_id, number, pathway_chunks_id, id FROM pathway_sub_paths
	});
    $sth->execute;
    while (($ext_tar_pathway_nodes_id, $ext_src_pathway_nodes_id, $number, $pathway_chunks_id, $id) = $sth->fetchrow_array) {
	my $pathway_sub_paths = {
		'ext_tar_pathway_nodes_id' => $ext_tar_pathway_nodes_id, 
		'ext_src_pathway_nodes_id' => $ext_src_pathway_nodes_id, 
		'number' => $number, 
		'pathway_chunks_id' => $pathway_chunks_id, 
		'id' => $id
		};
	bless($pathway_sub_paths, $class);
	push(@pathway_sub_paths, $pathway_sub_paths);
    }
    $sth->finish;
    return(\@pathway_sub_paths);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway_sub_paths WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'ext_tar_pathway_nodes_id'
sub ext_tar_pathway_nodes_id {
    my ($self, $ext_tar_pathway_nodes_id) = @_;
    return($self->getset('ext_tar_pathway_nodes_id', $ext_tar_pathway_nodes_id));
}

# get or set the member variable 'ext_src_pathway_nodes_id'
sub ext_src_pathway_nodes_id {
    my ($self, $ext_src_pathway_nodes_id) = @_;
    return($self->getset('ext_src_pathway_nodes_id', $ext_src_pathway_nodes_id));
}

# get or set the member variable 'number'
sub number {
    my ($self, $number) = @_;
    return($self->getset('number', $number));
}

# get or set the member variable 'pathway_chunks_id'
sub pathway_chunks_id {
    my ($self, $pathway_chunks_id) = @_;
    return($self->getset('pathway_chunks_id', $pathway_chunks_id));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# set several member variables at the same time
sub mset {
    my ($self, $hashref) = @_;
    # first update the database
    my @sql = ();
    foreach $key (keys(%$hashref)) {
	# prevent really stupid tricks
	if ($key eq 'id') {
	    return(-1);
	}
	my $val = $hashref->{$key};
	push(@sql, "$key='$val'");
    }
    my $id = $self->id;
    my $sql = "UPDATE pathway_sub_paths SET ".join(', ', @sql)." WHERE id=$id";
    $pathwayDB_DBH->do($sql) || return(-1);
    # if all went well, update the object itself
    foreach $key (keys(%$hashref)) {
	my $val = $hashref->{$key};
	$self->{$key} = $val;
    }
}

########################################################################
#
# load additional methods from self made module
#
########################################################################

require pathwayDB::pathway_sub_paths_add;

########################################################################
#
# private functions used inside this module
#
########################################################################

# get or set one of the member variables
sub getset {
    my ($self, $var, $val) = @_;
    my $id = $self->id;
    if (defined($val)) {
	$pathwayDB_DBH->do(qq {
		UPDATE pathway_sub_paths SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

