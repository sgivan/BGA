########################################################################
#
# This module was created automagically by O2DBI (1.24)
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::funcat_add.pm.
#
########################################################################

package GENDB::funcat;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for funcat
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $name, $parent_funcat) = @_;
    # fetch a fresh id
    my $id = newid('funcat');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO funcat (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $funcat = { 'id' => $id,
		    '_buffer' => 1 };
    bless($funcat, $class);
    # fill in the remaining data
    $funcat->name($name);
    $funcat->parent_funcat($parent_funcat);
    if ($funcat->unbuffer < 0) {
	$funcat->delete;
	return(-1);
    } else {
	return($funcat);
    }
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, parent_funcat, id FROM funcat
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($icon, $definition, $name, $parent_funcat, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $funcat = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'parent_funcat' => $parent_funcat, 
		'id' => $id
		};
        bless($funcat, $class);
        return($funcat);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %funcat = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, parent_funcat, id FROM funcat
	});
    $sth->execute;
    while (($icon, $definition, $name, $parent_funcat, $id) = $sth->fetchrow_array) {
	my $funcat = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'parent_funcat' => $parent_funcat, 
		'id' => $id
		};
	bless($funcat, $class);
	$funcat{$id} = $funcat;
    }
    $sth->finish;
    return(\%funcat);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @funcat = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, parent_funcat, id FROM funcat WHERE $statement
	});
    $sth->execute;
    while (($icon, $definition, $name, $parent_funcat, $id) = $sth->fetchrow_array) {
	my $funcat = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'parent_funcat' => $parent_funcat, 
		'id' => $id
		};
	bless($funcat, $class);
	push(@funcat, $funcat);
    }
    $sth->finish;
    return(\@funcat);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @funcat = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, parent_funcat, id FROM funcat
	});
    $sth->execute;
    while (($icon, $definition, $name, $parent_funcat, $id) = $sth->fetchrow_array) {
	my $funcat = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'parent_funcat' => $parent_funcat, 
		'id' => $id
		};
	bless($funcat, $class);
	push(@funcat, $funcat);
    }
    $sth->finish;
    return(\@funcat);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM funcat WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'icon'
sub icon {
    my ($self, $icon) = @_;
    return($self->getset('icon', $icon));
}

# get or set the member variable 'definition'
sub definition {
    my ($self, $definition) = @_;
    return($self->getset('definition', $definition));
}

# get or set the member variable 'name'
sub name {
    my ($self, $name) = @_;
    return($self->getset('name', $name));
}

# get or set the member variable 'parent_funcat'
sub parent_funcat {
    my ($self, $parent_funcat) = @_;
    return($self->getset('parent_funcat', $parent_funcat));
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
	&$key($self, $val);
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

require GENDB::funcat_add;

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
	foreach $key (qw{icon definition name parent_funcat id}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE funcat SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE funcat SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

