########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::enzyme_add.pm.
#
########################################################################

package pathwayDB::enzyme;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for enzyme
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $enzyme_number) = @_;
    # fetch a fresh id
    my $id = newid('enzyme');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO enzyme (id, enzyme_number)
            VALUES ($id, '$enzyme_number')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $enzyme = {
		'id' => $id, 
		'enzyme_number' => $enzyme_number
	};
    bless($enzyme, $class);
    return($enzyme);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number, id FROM enzyme
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($enzyme_number, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $enzyme = {
		'enzyme_number' => $enzyme_number, 
		'id' => $id
		};
	bless($enzyme, $class);
	return($enzyme);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %enzyme = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number, id FROM enzyme
	});
    $sth->execute;
    while (($enzyme_number, $id) = $sth->fetchrow_array) {
	my $enzyme = {
		'enzyme_number' => $enzyme_number, 
		'id' => $id
		};
	bless($enzyme, $class);
	$enzyme{$id} = $enzyme;
    }
    $sth->finish;
    return(\%enzyme);
}

# create an object for already existing data
sub init_enzyme_number {
    my ($class, $req_enzyme_number) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number, id FROM enzyme
		WHERE enzyme_number='$req_enzyme_number'
	});
    $sth->execute;
    my ($enzyme_number, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $enzyme = {
		'enzyme_number' => $enzyme_number, 
		'id' => $id
		};
	bless($enzyme, $class);
	return($enzyme);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_enzyme_number {
    my ($class) = @_;
    local %enzyme = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number, id FROM enzyme
	});
    $sth->execute;
    while (($enzyme_number, $id) = $sth->fetchrow_array) {
	my $enzyme = {
		'enzyme_number' => $enzyme_number, 
		'id' => $id
		};
	bless($enzyme, $class);
	$enzyme{$enzyme_number} = $enzyme;
    }
    $sth->finish;
    return(\%enzyme);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @enzyme = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT enzyme_number, id FROM enzyme
	});
    $sth->execute;
    while (($enzyme_number, $id) = $sth->fetchrow_array) {
	my $enzyme = {
		'enzyme_number' => $enzyme_number, 
		'id' => $id
		};
	bless($enzyme, $class);
	push(@enzyme, $enzyme);
    }
    $sth->finish;
    return(\@enzyme);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM enzyme WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'enzyme_number'
sub enzyme_number {
    my ($self, $enzyme_number) = @_;
    return($self->getset('enzyme_number', $enzyme_number));
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
    my $sql = "UPDATE enzyme SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::enzyme_add;

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
		UPDATE enzyme SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

