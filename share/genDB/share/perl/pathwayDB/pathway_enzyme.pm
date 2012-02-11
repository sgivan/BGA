########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_enzyme_add.pm.
#
########################################################################

package pathwayDB::pathway_enzyme;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway_enzyme
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $ec_id, $path_id) = @_;
    # fetch a fresh id
    my $id = newid('pathway_enzyme');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway_enzyme (id, ec_id, path_id)
            VALUES ($id, '$ec_id', '$path_id')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway_enzyme = {
		'id' => $id, 
		'ec_id' => $ec_id, 
		'path_id' => $path_id
	};
    bless($pathway_enzyme, $class);
    return($pathway_enzyme);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT path_id, ec_id, id FROM pathway_enzyme
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($path_id, $ec_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway_enzyme = {
		'path_id' => $path_id, 
		'ec_id' => $ec_id, 
		'id' => $id
		};
	bless($pathway_enzyme, $class);
	return($pathway_enzyme);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway_enzyme = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT path_id, ec_id, id FROM pathway_enzyme
	});
    $sth->execute;
    while (($path_id, $ec_id, $id) = $sth->fetchrow_array) {
	my $pathway_enzyme = {
		'path_id' => $path_id, 
		'ec_id' => $ec_id, 
		'id' => $id
		};
	bless($pathway_enzyme, $class);
	$pathway_enzyme{$id} = $pathway_enzyme;
    }
    $sth->finish;
    return(\%pathway_enzyme);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway_enzyme = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT path_id, ec_id, id FROM pathway_enzyme
	});
    $sth->execute;
    while (($path_id, $ec_id, $id) = $sth->fetchrow_array) {
	my $pathway_enzyme = {
		'path_id' => $path_id, 
		'ec_id' => $ec_id, 
		'id' => $id
		};
	bless($pathway_enzyme, $class);
	push(@pathway_enzyme, $pathway_enzyme);
    }
    $sth->finish;
    return(\@pathway_enzyme);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway_enzyme WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'path_id'
sub path_id {
    my ($self, $path_id) = @_;
    return($self->getset('path_id', $path_id));
}

# get or set the member variable 'ec_id'
sub ec_id {
    my ($self, $ec_id) = @_;
    return($self->getset('ec_id', $ec_id));
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
    my $sql = "UPDATE pathway_enzyme SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::pathway_enzyme_add;

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
		UPDATE pathway_enzyme SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

