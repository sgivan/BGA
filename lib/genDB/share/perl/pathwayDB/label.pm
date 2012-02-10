########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::label_add.pm.
#
########################################################################

package pathwayDB::label;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for label
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $label) = @_;
    # fetch a fresh id
    my $id = newid('label');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO label (id, label)
            VALUES ($id, '$label')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $label = {
		'id' => $id, 
		'label' => $label
	};
    bless($label, $class);
    return($label);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT label, id FROM label
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($label, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $label = {
		'label' => $label, 
		'id' => $id
		};
	bless($label, $class);
	return($label);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %label = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT label, id FROM label
	});
    $sth->execute;
    while (($label, $id) = $sth->fetchrow_array) {
	my $label = {
		'label' => $label, 
		'id' => $id
		};
	bless($label, $class);
	$label{$id} = $label;
    }
    $sth->finish;
    return(\%label);
}

# create an object for already existing data
sub init_label {
    my ($class, $req_label) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT label, id FROM label
		WHERE label='$req_label'
	});
    $sth->execute;
    my ($label, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $label = {
		'label' => $label, 
		'id' => $id
		};
	bless($label, $class);
	return($label);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_label {
    my ($class) = @_;
    local %label = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT label, id FROM label
	});
    $sth->execute;
    while (($label, $id) = $sth->fetchrow_array) {
	my $label = {
		'label' => $label, 
		'id' => $id
		};
	bless($label, $class);
	$label{$label} = $label;
    }
    $sth->finish;
    return(\%label);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @label = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT label, id FROM label
	});
    $sth->execute;
    while (($label, $id) = $sth->fetchrow_array) {
	my $label = {
		'label' => $label, 
		'id' => $id
		};
	bless($label, $class);
	push(@label, $label);
    }
    $sth->finish;
    return(\@label);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM label WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'label'
sub label {
    my ($self, $label) = @_;
    return($self->getset('label', $label));
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
    my $sql = "UPDATE label SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::label_add;

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
		UPDATE label SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

