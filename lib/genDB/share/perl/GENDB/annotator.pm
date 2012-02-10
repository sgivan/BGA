########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::annotator_add.pm.
#
########################################################################

package GENDB::annotator;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for annotator
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, ) = @_;
    # fetch a fresh id
    my $id = newid('annotator');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO annotator (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $annotator = { 'id' => $id,
		    '_buffer' => 1 };
    bless($annotator, $class);
    # fill in the remaining data
    $annotator->unbuffer;
    return($annotator);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($name, $description, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
        bless($annotator, $class);
        return($annotator);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %annotator = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator
	});
    $sth->execute;
    while (($name, $description, $id) = $sth->fetchrow_array) {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
	bless($annotator, $class);
	$annotator{$id} = $annotator;
    }
    $sth->finish;
    return(\%annotator);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @annotator = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator WHERE $statement
	});
    $sth->execute;
    while (($name, $description, $id) = $sth->fetchrow_array) {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
	bless($annotator, $class);
	push(@annotator, $annotator);
    }
    $sth->finish;
    return(\@annotator);
}

# create an object for already existing data
sub init_name {
    my ($class, $req_name) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator
		WHERE name='$req_name'
	});
    $sth->execute;
    my ($name, $description, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
        bless($annotator, $class);
        return($annotator);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_name {
    my ($class) = @_;
    local %annotator = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator
	});
    $sth->execute;
    while (($name, $description, $id) = $sth->fetchrow_array) {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
	bless($annotator, $class);
	$annotator{$name} = $annotator;
    }
    $sth->finish;
    return(\%annotator);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @annotator = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator WHERE $statement
	});
    $sth->execute;
    while (($name, $description, $id) = $sth->fetchrow_array) {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
	bless($annotator, $class);
	push(@annotator, $annotator);
    }
    $sth->finish;
    return(\@annotator);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @annotator = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, description, id FROM annotator
	});
    $sth->execute;
    while (($name, $description, $id) = $sth->fetchrow_array) {
	my $annotator = {
		'name' => $name, 
		'description' => $description, 
		'id' => $id
		};
	bless($annotator, $class);
	push(@annotator, $annotator);
    }
    $sth->finish;
    return(\@annotator);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM annotator WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'name'
sub name {
    my ($self, $name) = @_;
    return($self->getset('name', $name));
}

# get or set the member variable 'description'
sub description {
    my ($self, $description) = @_;
    return($self->getset('description', $description));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# set several member variables at the same time
sub mset {
    my ($self, $hashref) = @_;
    my $curbuffer = $self->buffered;
    $self->buffer;
    foreach $key (keys(%$hashref)) {
	# prevent really stupid tricks
	if ($key eq 'id') {
	    return(-1);
	}
	my $val = $hashref->{$key};
	eval $self->$key($val);
    }
    if (!$curbuffer) {
	$self->unbuffer;
    }
}

########################################################################
#
# load additional methods from self made module
#
########################################################################

require GENDB::annotator_add;

########################################################################
#
# private functions used inside this module
#
########################################################################

# test if the data is buffered or passed to the DBMS immediately
sub buffered {
    my ($self) = @_;
    return($self->{'_buffer'});
}

# make the data buffered, i.e. don't write to the database
sub buffer {
    my ($self) = @_;
    $self->{'_buffer'} = 1;
}

# write the current contents to the database and declare the object unbuffered
sub unbuffer {
    my ($self) = @_;
    if ($self->buffered) {
	my @sql = ();
	foreach $key (qw{name description id}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE annotator SET ".join(', ', @sql)." WHERE id=$id";
	$GENDB_DBH->do($sql) || return(-1);
    }
    $self->{'_buffer'} = 0;
}

# get or set one of the member variables
sub getset {
    my ($self, $var, $val) = @_;
    my $id = $self->id;
    if (defined($val)) {
	if (!$self->buffered) {
	    my $qval = $GENDB_DBH->quote($val);
	    $GENDB_DBH->do(qq {
		UPDATE annotator SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

