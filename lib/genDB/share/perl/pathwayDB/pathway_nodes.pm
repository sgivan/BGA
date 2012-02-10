########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_nodes_add.pm.
#
########################################################################

package pathwayDB::pathway_nodes;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway_nodes
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $path_id, $node_id, $compound_id, $compound_status, $compound_type) = @_;
    # fetch a fresh id
    my $id = newid('pathway_nodes');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway_nodes (id, path_id, node_id, compound_id, compound_status, compound_type)
            VALUES ($id, '$path_id', '$node_id', '$compound_id', '$compound_status', '$compound_type')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway_nodes = {
		'id' => $id, 
		'path_id' => $path_id, 
		'node_id' => $node_id, 
		'compound_id' => $compound_id, 
		'compound_status' => $compound_status, 
		'compound_type' => $compound_type
	};
    bless($pathway_nodes, $class);
    return($pathway_nodes);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($compound_status, $compound_id, $path_id, $node_id, $id, $compound_type) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_nodes = {
		'compound_status' => $compound_status, 
		'compound_id' => $compound_id, 
		'path_id' => $path_id, 
		'node_id' => $node_id, 
		'id' => $id, 
		'compound_type' => $compound_type
		};
	bless($pathway_nodes, $class);
	return($pathway_nodes);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
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
	$pathway_nodes{$id} = $pathway_nodes;
    }
    $sth->finish;
    return(\%pathway_nodes);
}

# create an object for already existing data
sub init_path_id_node_id {
    my ($class, $req_path_id, $req_node_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
		WHERE path_id='$req_path_id' AND node_id='$req_node_id'
	});
    $sth->execute;
    my ($compound_status, $compound_id, $path_id, $node_id, $id, $compound_type) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_nodes = {
		'compound_status' => $compound_status, 
		'compound_id' => $compound_id, 
		'path_id' => $path_id, 
		'node_id' => $node_id, 
		'id' => $id, 
		'compound_type' => $compound_type
		};
	bless($pathway_nodes, $class);
	return($pathway_nodes);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_path_id_node_id {
    my ($class) = @_;
    local %pathway_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
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
	my $key = join(',', $path_id, $node_id);
	$pathway_nodes{$key} = $pathway_nodes;
    }
    $sth->finish;
    return(\%pathway_nodes);
}

# create an object for already existing data
sub init_path_id_compound_id {
    my ($class, $req_path_id, $req_compound_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
		WHERE path_id='$req_path_id' AND compound_id='$req_compound_id'
	});
    $sth->execute;
    my ($compound_status, $compound_id, $path_id, $node_id, $id, $compound_type) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_nodes = {
		'compound_status' => $compound_status, 
		'compound_id' => $compound_id, 
		'path_id' => $path_id, 
		'node_id' => $node_id, 
		'id' => $id, 
		'compound_type' => $compound_type
		};
	bless($pathway_nodes, $class);
	return($pathway_nodes);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_path_id_compound_id {
    my ($class) = @_;
    local %pathway_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
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
	my $key = join(',', $path_id, $compound_id);
	$pathway_nodes{$key} = $pathway_nodes;
    }
    $sth->finish;
    return(\%pathway_nodes);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway_nodes = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_status, compound_id, path_id, node_id, id, compound_type FROM pathway_nodes
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
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway_nodes WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'compound_status'
sub compound_status {
    my ($self, $compound_status) = @_;
    return($self->getset('compound_status', $compound_status));
}

# get or set the member variable 'compound_id'
sub compound_id {
    my ($self, $compound_id) = @_;
    return($self->getset('compound_id', $compound_id));
}

# get or set the member variable 'path_id'
sub path_id {
    my ($self, $path_id) = @_;
    return($self->getset('path_id', $path_id));
}

# get or set the member variable 'node_id'
sub node_id {
    my ($self, $node_id) = @_;
    return($self->getset('node_id', $node_id));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'compound_type'
sub compound_type {
    my ($self, $compound_type) = @_;
    return($self->getset('compound_type', $compound_type));
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
    my $sql = "UPDATE pathway_nodes SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::pathway_nodes_add;

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
		UPDATE pathway_nodes SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

