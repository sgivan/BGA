########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_chunks_add.pm.
#
########################################################################

package pathwayDB::pathway_chunks;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway_chunks
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $number, $pathway_edges_id, $src_pathway_nodes_id, $tar_pathway_nodes_id) = @_;
    # fetch a fresh id
    my $id = newid('pathway_chunks');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway_chunks (id, number, pathway_edges_id, src_pathway_nodes_id, tar_pathway_nodes_id)
            VALUES ($id, '$number', '$pathway_edges_id', '$src_pathway_nodes_id', '$tar_pathway_nodes_id')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway_chunks = {
		'id' => $id, 
		'number' => $number, 
		'pathway_edges_id' => $pathway_edges_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id
	};
    bless($pathway_chunks, $class);
    return($pathway_chunks);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT tar_pathway_nodes_id, src_pathway_nodes_id, pathway_edges_id, number, id FROM pathway_chunks
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($tar_pathway_nodes_id, $src_pathway_nodes_id, $pathway_edges_id, $number, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_chunks = {
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'pathway_edges_id' => $pathway_edges_id, 
		'number' => $number, 
		'id' => $id
		};
	bless($pathway_chunks, $class);
	return($pathway_chunks);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway_chunks = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT tar_pathway_nodes_id, src_pathway_nodes_id, pathway_edges_id, number, id FROM pathway_chunks
	});
    $sth->execute;
    while (($tar_pathway_nodes_id, $src_pathway_nodes_id, $pathway_edges_id, $number, $id) = $sth->fetchrow_array) {
	my $pathway_chunks = {
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'pathway_edges_id' => $pathway_edges_id, 
		'number' => $number, 
		'id' => $id
		};
	bless($pathway_chunks, $class);
	$pathway_chunks{$id} = $pathway_chunks;
    }
    $sth->finish;
    return(\%pathway_chunks);
}

# create an object for already existing data
sub init_number_pathway_edges_id_src_pathway_nodes_id_tar_pathway_nodes_id {
    my ($class, $req_number, $req_pathway_edges_id, $req_src_pathway_nodes_id, $req_tar_pathway_nodes_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT tar_pathway_nodes_id, src_pathway_nodes_id, pathway_edges_id, number, id FROM pathway_chunks
		WHERE number='$req_number' AND pathway_edges_id='$req_pathway_edges_id' AND src_pathway_nodes_id='$req_src_pathway_nodes_id' AND tar_pathway_nodes_id='$req_tar_pathway_nodes_id'
	});
    $sth->execute;
    my ($tar_pathway_nodes_id, $src_pathway_nodes_id, $pathway_edges_id, $number, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_chunks = {
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'pathway_edges_id' => $pathway_edges_id, 
		'number' => $number, 
		'id' => $id
		};
	bless($pathway_chunks, $class);
	return($pathway_chunks);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_number_pathway_edges_id_src_pathway_nodes_id_tar_pathway_nodes_id {
    my ($class) = @_;
    local %pathway_chunks = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT tar_pathway_nodes_id, src_pathway_nodes_id, pathway_edges_id, number, id FROM pathway_chunks
	});
    $sth->execute;
    while (($tar_pathway_nodes_id, $src_pathway_nodes_id, $pathway_edges_id, $number, $id) = $sth->fetchrow_array) {
	my $pathway_chunks = {
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'pathway_edges_id' => $pathway_edges_id, 
		'number' => $number, 
		'id' => $id
		};
	bless($pathway_chunks, $class);
	my $key = join(',', $number, $pathway_edges_id, $src_pathway_nodes_id, $tar_pathway_nodes_id);
	$pathway_chunks{$key} = $pathway_chunks;
    }
    $sth->finish;
    return(\%pathway_chunks);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway_chunks = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT tar_pathway_nodes_id, src_pathway_nodes_id, pathway_edges_id, number, id FROM pathway_chunks
	});
    $sth->execute;
    while (($tar_pathway_nodes_id, $src_pathway_nodes_id, $pathway_edges_id, $number, $id) = $sth->fetchrow_array) {
	my $pathway_chunks = {
		'tar_pathway_nodes_id' => $tar_pathway_nodes_id, 
		'src_pathway_nodes_id' => $src_pathway_nodes_id, 
		'pathway_edges_id' => $pathway_edges_id, 
		'number' => $number, 
		'id' => $id
		};
	bless($pathway_chunks, $class);
	push(@pathway_chunks, $pathway_chunks);
    }
    $sth->finish;
    return(\@pathway_chunks);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway_chunks WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'tar_pathway_nodes_id'
sub tar_pathway_nodes_id {
    my ($self, $tar_pathway_nodes_id) = @_;
    return($self->getset('tar_pathway_nodes_id', $tar_pathway_nodes_id));
}

# get or set the member variable 'src_pathway_nodes_id'
sub src_pathway_nodes_id {
    my ($self, $src_pathway_nodes_id) = @_;
    return($self->getset('src_pathway_nodes_id', $src_pathway_nodes_id));
}

# get or set the member variable 'pathway_edges_id'
sub pathway_edges_id {
    my ($self, $pathway_edges_id) = @_;
    return($self->getset('pathway_edges_id', $pathway_edges_id));
}

# get or set the member variable 'number'
sub number {
    my ($self, $number) = @_;
    return($self->getset('number', $number));
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
    my $sql = "UPDATE pathway_chunks SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::pathway_chunks_add;

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
		UPDATE pathway_chunks SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

