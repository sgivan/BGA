########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file pathwayDB::reaction_add.pm.
#
########################################################################

package pathwayDB::reaction;

use pathwayDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for reaction
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $compound_id, $compound_id) = @_;
    # fetch a fresh id
    my $id = newid('reaction');
        if ($id < 0) {
	return(-1);
    }
    # insert the data into the database
    $pathwayDB_DBH->do(qq {
            INSERT INTO reaction (id, compound_id, compound_id)
            VALUES ($id, '$compound_id', '$compound_id')
           });
    if ($pathwayDB_DBH->err) {
	return(-1);
    }
    # create a perl object
    my $reaction = {
		'id' => $id, 
		'compound_id' => $compound_id, 
		'compound_id' => $compound_id
	};
    bless($reaction, $class);
    return($reaction);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_id, id FROM reaction
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($compound_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $reaction = {
		'compound_id' => $compound_id, 
		'id' => $id
		};
	bless($reaction, $class);
	return($reaction);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %reaction = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_id, id FROM reaction
	});
    $sth->execute;
    while (($compound_id, $id) = $sth->fetchrow_array) {
	my $reaction = {
		'compound_id' => $compound_id, 
		'id' => $id
		};
	bless($reaction, $class);
	$reaction{$id} = $reaction;
    }
    $sth->finish;
    return(\%reaction);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @reaction = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT compound_id, id FROM reaction
	});
    $sth->execute;
    while (($compound_id, $id) = $sth->fetchrow_array) {
	my $reaction = {
		'compound_id' => $compound_id, 
		'id' => $id
		};
	bless($reaction, $class);
	push(@reaction, $reaction);
    }
    $sth->finish;
    return(\@reaction);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $pathwayDB_DBH->do(qq {
	DELETE FROM reaction WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'compound_id'
sub compound_id {
    my ($self, $compound_id) = @_;
    return($self->getset('compound_id', $compound_id));
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
    my $sql = "UPDATE reaction SET ".join(', ', @sql)." WHERE id=$id";
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

require pathwayDB::reaction_add;

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
		UPDATE reaction SET $var='$val' WHERE id=$id
	}) || return(-1);
	$self->{$var} = $val;
    }
    return($self->{$var});
}

