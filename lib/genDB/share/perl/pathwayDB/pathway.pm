########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::pathway_add.pm.
#
########################################################################

package pathwayDB::pathway;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for pathway
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $pathway_name) = @_;
    # fetch a fresh id
    my $id = newid('pathway');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO pathway (id, pathway_name)
            VALUES ($id, '$pathway_name')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
	};
    bless($pathway, $class);
    return($pathway);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT id, pathway_name FROM pathway
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($id, $pathway_name) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
		};
	bless($pathway, $class);
	return($pathway);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %pathway = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT id, pathway_name FROM pathway
	});
    $sth->execute;
    while (($id, $pathway_name) = $sth->fetchrow_array) {
	my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
		};
	bless($pathway, $class);
	$pathway{$id} = $pathway;
    }
    $sth->finish;
    return(\%pathway);
}

# create an object for already existing data
sub init_pathway_name {
    my ($class, $req_pathway_name) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT id, pathway_name FROM pathway
		WHERE pathway_name='$req_pathway_name'
	});
    $sth->execute;
    my ($id, $pathway_name) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
		};
	bless($pathway, $class);
	return($pathway);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_pathway_name {
    my ($class) = @_;
    local %pathway = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT id, pathway_name FROM pathway
	});
    $sth->execute;
    while (($id, $pathway_name) = $sth->fetchrow_array) {
	my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
		};
	bless($pathway, $class);
	$pathway{$pathway_name} = $pathway;
    }
    $sth->finish;
    return(\%pathway);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @pathway = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT id, pathway_name FROM pathway
	});
    $sth->execute;
    while (($id, $pathway_name) = $sth->fetchrow_array) {
	my $pathway = {
		'id' => $id, 
		'pathway_name' => $pathway_name
		};
	bless($pathway, $class);
	push(@pathway, $pathway);
    }
    $sth->finish;
    return(\@pathway);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM pathway WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'pathway_name'
sub pathway_name {
    my ($self, $pathway_name) = @_;
    return($self->getset('pathway_name', $pathway_name));
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
    my $sql = "UPDATE pathway SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::pathway_add;

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
		UPDATE pathway SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

