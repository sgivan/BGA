########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::contig_add.pm.
#
########################################################################

package GENDB::contig;

use GENDB::DBMS;

1;

my %id_cache;

########################################################################
#
# constructor and destructor methods for contig
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $name, $sequence) = @_;
    # fetch a fresh id
    my $id = newid('contig');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO contig (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $contig = { 'id' => $id,
		    '_buffer' => 1 };
    bless($contig, $class);
    # fill in the remaining data
    $contig->name($name);
    $contig->sequence($sequence);
    $contig->unbuffer;
    return($contig);
}

sub delete_from_cache {
    my($self) = @_;
    my $req_id = $self->id;
    if (defined ($id_cache->{$req_id})) {
	delete $id_cache->{$req_id}
    }
}

sub init_id {
    my ($class, $req_id) = @_;
    if (defined ($id_cache->{$req_id})) {
	return $id_cache->{$req_id};
    }

    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
        bless($contig, $class);
	$id_cache->{$req_id} = $contig;
        return($contig);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %contig = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig
	});
    $sth->execute;
    while (($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array) {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
	bless($contig, $class);
	$contig{$id} = $contig;
    }
    $sth->finish;
    return(\%contig);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @contig = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig WHERE $statement
	});
    $sth->execute;
    while (($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array) {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
	bless($contig, $class);
	push(@contig, $contig);
    }
    $sth->finish;
    return(\@contig);
}

# create an object for already existing data
sub init_name {
    my ($class, $req_name) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig
		WHERE name='$req_name'
	});
    $sth->execute;
    my ($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
        bless($contig, $class);
        return($contig);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_name {
    my ($class) = @_;
    local %contig = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig
	});
    $sth->execute;
    while (($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array) {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
	bless($contig, $class);
	$contig{$name} = $contig;
    }
    $sth->finish;
    return(\%contig);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @contig = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, length, loverlap, lneighbor_id, sequence, roverlap, rneighbor_id, id FROM contig
	});
    $sth->execute;
    while (($name, $length, $loverlap, $lneighbor_id, $sequence, $roverlap, $rneighbor_id, $id) = $sth->fetchrow_array) {
	my $contig = {
		'name' => $name, 
		'length' => $length, 
		'loverlap' => $loverlap, 
		'lneighbor_id' => $lneighbor_id, 
		'sequence' => $sequence, 
		'roverlap' => $roverlap, 
		'rneighbor_id' => $rneighbor_id, 
		'id' => $id
		};
	bless($contig, $class);
	push(@contig, $contig);
    }
    $sth->finish;
    return(\@contig);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    #print "DELETE from contig WHERE id=$id\n";
    $GENDB_DBH->do(qq {
	DELETE FROM contig WHERE id=$id
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

# get or set the member variable 'length'
sub length {
    my ($self, $length) = @_;
    return($self->getset('length', $length));
}

# get or set the member variable 'loverlap'
sub loverlap {
    my ($self, $loverlap) = @_;
    return($self->getset('loverlap', $loverlap));
}

# get or set the member variable 'lneighbor_id'
sub lneighbor_id {
    my ($self, $lneighbor_id) = @_;
    return($self->getset('lneighbor_id', $lneighbor_id));
}

# get or set the member variable 'sequence'
sub sequence {
    my ($self, $sequence) = @_;
    return($self->getset('sequence', $sequence));
}

# get or set the member variable 'roverlap'
sub roverlap {
    my ($self, $roverlap) = @_;
    return($self->getset('roverlap', $roverlap));
}

# get or set the member variable 'rneighbor_id'
sub rneighbor_id {
    my ($self, $rneighbor_id) = @_;
    return($self->getset('rneighbor_id', $rneighbor_id));
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

require GENDB::contig_add;

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
	foreach $key (qw{name length loverlap lneighbor_id sequence roverlap rneighbor_id id}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE contig SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE contig SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

