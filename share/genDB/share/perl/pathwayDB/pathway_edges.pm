########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_edges_add.pm.
#
########################################################################

package pathwayDB::pathway_edges;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway_edges
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $source_id, $target_id, $ec_id, $label_id, $status) = @_;
    # fetch a fresh id
    my $id = newid('pathway_edges');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway_edges (id, source_id, target_id, ec_id, label_id, status)
            VALUES ($id, '$source_id', '$target_id', '$ec_id', '$label_id', '$status')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway_edges = {
		'id' => $id, 
		'source_id' => $source_id, 
		'target_id' => $target_id, 
		'ec_id' => $ec_id, 
		'label_id' => $label_id, 
		'status' => $status
	};
    bless($pathway_edges, $class);
    return($pathway_edges);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT target_id, status, label_id, ec_id, source_id, id FROM pathway_edges
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($target_id, $status, $label_id, $ec_id, $source_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_edges = {
		'target_id' => $target_id, 
		'status' => $status, 
		'label_id' => $label_id, 
		'ec_id' => $ec_id, 
		'source_id' => $source_id, 
		'id' => $id
		};
	bless($pathway_edges, $class);
	return($pathway_edges);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway_edges = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT target_id, status, label_id, ec_id, source_id, id FROM pathway_edges
	});
    $sth->execute;
    while (($target_id, $status, $label_id, $ec_id, $source_id, $id) = $sth->fetchrow_array) {
	my $pathway_edges = {
		'target_id' => $target_id, 
		'status' => $status, 
		'label_id' => $label_id, 
		'ec_id' => $ec_id, 
		'source_id' => $source_id, 
		'id' => $id
		};
	bless($pathway_edges, $class);
	$pathway_edges{$id} = $pathway_edges;
    }
    $sth->finish;
    return(\%pathway_edges);
}

# create an object for already existing data
sub init_source_id_target_id_ec_id_label_id {
    my ($class, $req_source_id, $req_target_id, $req_ec_id, $req_label_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT target_id, status, label_id, ec_id, source_id, id FROM pathway_edges
		WHERE source_id='$req_source_id' AND target_id='$req_target_id' AND ec_id='$req_ec_id' AND label_id='$req_label_id'
	});
    $sth->execute;
    my ($target_id, $status, $label_id, $ec_id, $source_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_edges = {
		'target_id' => $target_id, 
		'status' => $status, 
		'label_id' => $label_id, 
		'ec_id' => $ec_id, 
		'source_id' => $source_id, 
		'id' => $id
		};
	bless($pathway_edges, $class);
	return($pathway_edges);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_source_id_target_id_ec_id_label_id {
    my ($class) = @_;
    local %pathway_edges = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT target_id, status, label_id, ec_id, source_id, id FROM pathway_edges
	});
    $sth->execute;
    while (($target_id, $status, $label_id, $ec_id, $source_id, $id) = $sth->fetchrow_array) {
	my $pathway_edges = {
		'target_id' => $target_id, 
		'status' => $status, 
		'label_id' => $label_id, 
		'ec_id' => $ec_id, 
		'source_id' => $source_id, 
		'id' => $id
		};
	bless($pathway_edges, $class);
	my $key = join(',', $source_id, $target_id, $ec_id, $label_id);
	$pathway_edges{$key} = $pathway_edges;
    }
    $sth->finish;
    return(\%pathway_edges);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway_edges = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT target_id, status, label_id, ec_id, source_id, id FROM pathway_edges
	});
    $sth->execute;
    while (($target_id, $status, $label_id, $ec_id, $source_id, $id) = $sth->fetchrow_array) {
	my $pathway_edges = {
		'target_id' => $target_id, 
		'status' => $status, 
		'label_id' => $label_id, 
		'ec_id' => $ec_id, 
		'source_id' => $source_id, 
		'id' => $id
		};
	bless($pathway_edges, $class);
	push(@pathway_edges, $pathway_edges);
    }
    $sth->finish;
    return(\@pathway_edges);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway_edges WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'target_id'
sub target_id {
    my ($self, $target_id) = @_;
    return($self->getset('target_id', $target_id));
}

# get or set the member variable 'status'
sub status {
    my ($self, $status) = @_;
    return($self->getset('status', $status));
}

# get or set the member variable 'label_id'
sub label_id {
    my ($self, $label_id) = @_;
    return($self->getset('label_id', $label_id));
}

# get or set the member variable 'ec_id'
sub ec_id {
    my ($self, $ec_id) = @_;
    return($self->getset('ec_id', $ec_id));
}

# get or set the member variable 'source_id'
sub source_id {
    my ($self, $source_id) = @_;
    return($self->getset('source_id', $source_id));
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
    my $sql = "UPDATE pathway_edges SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::pathway_edges_add;

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
		UPDATE pathway_edges SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

