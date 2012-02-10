########################################################################
#
# This module was created automagically by O2DBI (1.24)
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::feature_type_add.pm.
#
########################################################################

package GENDB::feature_type;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for feature_type
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $name, $parent_feature_type) = @_;
    # fetch a fresh id
    my $id = newid('feature_type');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO feature_type (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $feature_type = { 'id' => $id,
		    '_buffer' => 1 };
    bless($feature_type, $class);
    # fill in the remaining data
    $feature_type->name($name);
    $feature_type->parent_feature_type($parent_feature_type);
    if ($feature_type->unbuffer < 0) {
	$feature_type->delete;
	return(-1);
    } else {
	return($feature_type);
    }
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, xml_dtd, id, parent_feature_type FROM feature_type
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($icon, $definition, $name, $xml_dtd, $id, $parent_feature_type) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $feature_type = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'xml_dtd' => $xml_dtd, 
		'id' => $id, 
		'parent_feature_type' => $parent_feature_type
		};
        bless($feature_type, $class);
        return($feature_type);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %feature_type = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, xml_dtd, id, parent_feature_type FROM feature_type
	});
    $sth->execute;
    while (($icon, $definition, $name, $xml_dtd, $id, $parent_feature_type) = $sth->fetchrow_array) {
	my $feature_type = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'xml_dtd' => $xml_dtd, 
		'id' => $id, 
		'parent_feature_type' => $parent_feature_type
		};
	bless($feature_type, $class);
	$feature_type{$id} = $feature_type;
    }
    $sth->finish;
    return(\%feature_type);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @feature_type = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, xml_dtd, id, parent_feature_type FROM feature_type WHERE $statement
	});
    $sth->execute;
    while (($icon, $definition, $name, $xml_dtd, $id, $parent_feature_type) = $sth->fetchrow_array) {
	my $feature_type = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'xml_dtd' => $xml_dtd, 
		'id' => $id, 
		'parent_feature_type' => $parent_feature_type
		};
	bless($feature_type, $class);
	push(@feature_type, $feature_type);
    }
    $sth->finish;
    return(\@feature_type);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @feature_type = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT icon, definition, name, xml_dtd, id, parent_feature_type FROM feature_type
	});
    $sth->execute;
    while (($icon, $definition, $name, $xml_dtd, $id, $parent_feature_type) = $sth->fetchrow_array) {
	my $feature_type = {
		'icon' => $icon, 
		'definition' => $definition, 
		'name' => $name, 
		'xml_dtd' => $xml_dtd, 
		'id' => $id, 
		'parent_feature_type' => $parent_feature_type
		};
	bless($feature_type, $class);
	push(@feature_type, $feature_type);
    }
    $sth->finish;
    return(\@feature_type);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM feature_type WHERE id=$id
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

# get or set the member variable 'xml_dtd'
sub xml_dtd {
    my ($self, $xml_dtd) = @_;
    return($self->getset('xml_dtd', $xml_dtd));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'parent_feature_type'
sub parent_feature_type {
    my ($self, $parent_feature_type) = @_;
    return($self->getset('parent_feature_type', $parent_feature_type));
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

require GENDB::feature_type_add;

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
	foreach $key (qw{icon definition name xml_dtd id parent_feature_type}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE feature_type SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE feature_type SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

