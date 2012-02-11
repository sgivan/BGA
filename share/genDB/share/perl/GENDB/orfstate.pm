########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::orfstate_add.pm.
#
########################################################################

package GENDB::orfstate;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for orfstate
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $orf_id, $tool_id) = @_;
    # fetch a fresh id
    my $id = newid('orfstate');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO orfstate (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $orfstate = { 'id' => $id,
		    '_buffer' => 1 };
    bless($orfstate, $class);
    # fill in the remaining data
    $orfstate->orf_id($orf_id);
    $orfstate->tool_id($tool_id);
    $orfstate->unbuffer;
    return($orfstate);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT tool_id, date_ordered, date_done, orf_id, id FROM orfstate
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($tool_id, $date_ordered, $date_done, $orf_id, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $orfstate = {
		'tool_id' => $tool_id, 
		'date_ordered' => $date_ordered, 
		'date_done' => $date_done, 
		'orf_id' => $orf_id, 
		'id' => $id
		};
        bless($orfstate, $class);
        return($orfstate);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %orfstate = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT tool_id, date_ordered, date_done, orf_id, id FROM orfstate
	});
    $sth->execute;
    while (($tool_id, $date_ordered, $date_done, $orf_id, $id) = $sth->fetchrow_array) {
	my $orfstate = {
		'tool_id' => $tool_id, 
		'date_ordered' => $date_ordered, 
		'date_done' => $date_done, 
		'orf_id' => $orf_id, 
		'id' => $id
		};
	bless($orfstate, $class);
	$orfstate{$id} = $orfstate;
    }
    $sth->finish;
    return(\%orfstate);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @orfstate = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT tool_id, date_ordered, date_done, orf_id, id FROM orfstate WHERE $statement
	});
    $sth->execute;
    while (($tool_id, $date_ordered, $date_done, $orf_id, $id) = $sth->fetchrow_array) {
	my $orfstate = {
		'tool_id' => $tool_id, 
		'date_ordered' => $date_ordered, 
		'date_done' => $date_done, 
		'orf_id' => $orf_id, 
		'id' => $id
		};
	bless($orfstate, $class);
	push(@orfstate, $orfstate);
    }
    $sth->finish;
    return(\@orfstate);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @orfstate = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT tool_id, date_ordered, date_done, orf_id, id FROM orfstate
	});
    $sth->execute;
    while (($tool_id, $date_ordered, $date_done, $orf_id, $id) = $sth->fetchrow_array) {
	my $orfstate = {
		'tool_id' => $tool_id, 
		'date_ordered' => $date_ordered, 
		'date_done' => $date_done, 
		'orf_id' => $orf_id, 
		'id' => $id
		};
	bless($orfstate, $class);
	push(@orfstate, $orfstate);
    }
    $sth->finish;
    return(\@orfstate);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM orfstate WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'tool_id'
sub tool_id {
    my ($self, $tool_id) = @_;
    return($self->getset('tool_id', $tool_id));
}

# get or set the member variable 'date_ordered'
sub date_ordered {
    my ($self, $date_ordered) = @_;
    return($self->getset('date_ordered', $date_ordered));
}

# get or set the member variable 'date_done'
sub date_done {
    my ($self, $date_done) = @_;
    return($self->getset('date_done', $date_done));
}

# get or set the member variable 'orf_id'
sub orf_id {
    my ($self, $orf_id) = @_;
    return($self->getset('orf_id', $orf_id));
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

require GENDB::orfstate_add;

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
	foreach $key (qw{tool_id date_ordered date_done orf_id id}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE orfstate SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE orfstate SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

