########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::compound_add.pm.
#
########################################################################

package pathwayDB::compound;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for compound
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $compound_name) = @_;
    # fetch a fresh id
    my $id = newid('compound');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO compound (id, compound_name)
            VALUES ($id, '$compound_name')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $compound = {
		'id' => $id, 
		'compound_name' => $compound_name
	};
    bless($compound, $class);
    return($compound);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name, id FROM compound
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($compound_name, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $compound = {
		'compound_name' => $compound_name, 
		'id' => $id
		};
	bless($compound, $class);
	return($compound);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %compound = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name, id FROM compound
	});
    $sth->execute;
    while (($compound_name, $id) = $sth->fetchrow_array) {
	my $compound = {
		'compound_name' => $compound_name, 
		'id' => $id
		};
	bless($compound, $class);
	$compound{$id} = $compound;
    }
    $sth->finish;
    return(\%compound);
}

# create an object for already existing data
sub init_compound_name {
    my ($class, $req_compound_name) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name, id FROM compound
		WHERE compound_name='$req_compound_name'
	});
    $sth->execute;
    my ($compound_name, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $compound = {
		'compound_name' => $compound_name, 
		'id' => $id
		};
	bless($compound, $class);
	return($compound);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_compound_name {
    my ($class) = @_;
    local %compound = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name, id FROM compound
	});
    $sth->execute;
    while (($compound_name, $id) = $sth->fetchrow_array) {
	my $compound = {
		'compound_name' => $compound_name, 
		'id' => $id
		};
	bless($compound, $class);
	$compound{$compound_name} = $compound;
    }
    $sth->finish;
    return(\%compound);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @compound = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_name, id FROM compound
	});
    $sth->execute;
    while (($compound_name, $id) = $sth->fetchrow_array) {
	my $compound = {
		'compound_name' => $compound_name, 
		'id' => $id
		};
	bless($compound, $class);
	push(@compound, $compound);
    }
    $sth->finish;
    return(\@compound);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM compound WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'compound_name'
sub compound_name {
    my ($self, $compound_name) = @_;
    return($self->getset('compound_name', $compound_name));
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
    my $sql = "UPDATE compound SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::compound_add;

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
		UPDATE compound SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

