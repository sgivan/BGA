########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::fact_add.pm.
#
########################################################################

package GENDB::fact;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for fact
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $orf_id) = @_;
    # fetch a fresh id
    my $id = newid('fact');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO fact (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $fact = { 'id' => $id,
		    '_buffer' => 1 };
    bless($fact, $class);
    # fill in the remaining data
    $fact->orf_id($orf_id);
    $fact->unbuffer;
    return($fact);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id, information FROM fact
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id, $information) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $fact = {
		'dbto' => $dbto, 
		'tool_id' => $tool_id, 
		'orfto' => $orfto, 
		'dbfrom' => $dbfrom, 
		'orffrom' => $orffrom, 
		'dbref' => $dbref, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'toolresult' => $toolresult, 
		'id' => $id, 
		'information' => $information
		};
        bless($fact, $class);
        return($fact);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %fact = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id, information FROM fact
	});
    $sth->execute;
    while (($dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id, $information) = $sth->fetchrow_array) {
	my $fact = {
		'dbto' => $dbto, 
		'tool_id' => $tool_id, 
		'orfto' => $orfto, 
		'dbfrom' => $dbfrom, 
		'orffrom' => $orffrom, 
		'dbref' => $dbref, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'toolresult' => $toolresult, 
		'id' => $id, 
		'information' => $information
		};
	bless($fact, $class);
	$fact{$id} = $fact;
    }
    $sth->finish;
    return(\%fact);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @fact = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id, information FROM fact WHERE $statement
	});
    $sth->execute;
    while (($dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id, $information) = $sth->fetchrow_array) {
	my $fact = {
		'dbto' => $dbto, 
		'tool_id' => $tool_id, 
		'orfto' => $orfto, 
		'dbfrom' => $dbfrom, 
		'orffrom' => $orffrom, 
		'dbref' => $dbref, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'toolresult' => $toolresult, 
		'id' => $id, 
		'information' => $information
		};
	bless($fact, $class);
	push(@fact, $fact);
    }
    $sth->finish;
    return(\@fact);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @fact = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT dbto, tool_id, orfto, dbfrom, orffrom, dbref, orf_id, description, toolresult, id, information FROM fact
	});
    $sth->execute;
    while (($dbto, $tool_id, $orfto, $dbfrom, $orffrom, $dbref, $orf_id, $description, $toolresult, $id, $information) = $sth->fetchrow_array) {
	my $fact = {
		'dbto' => $dbto, 
		'tool_id' => $tool_id, 
		'orfto' => $orfto, 
		'dbfrom' => $dbfrom, 
		'orffrom' => $orffrom, 
		'dbref' => $dbref, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'toolresult' => $toolresult, 
		'id' => $id, 
		'information' => $information
		};
	bless($fact, $class);
	push(@fact, $fact);
    }
    $sth->finish;
    return(\@fact);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM fact WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'dbto'
sub dbto {
    my ($self, $dbto) = @_;
    return($self->getset('dbto', $dbto));
}

# get or set the member variable 'tool_id'
sub tool_id {
    my ($self, $tool_id) = @_;
    return($self->getset('tool_id', $tool_id));
}

# get or set the member variable 'orfto'
sub orfto {
    my ($self, $orfto) = @_;
    return($self->getset('orfto', $orfto));
}

# get or set the member variable 'dbfrom'
sub dbfrom {
    my ($self, $dbfrom) = @_;
    return($self->getset('dbfrom', $dbfrom));
}

# get or set the member variable 'orffrom'
sub orffrom {
    my ($self, $orffrom) = @_;
    return($self->getset('orffrom', $orffrom));
}

# get or set the member variable 'dbref'
sub dbref {
    my ($self, $dbref) = @_;
    return($self->getset('dbref', $dbref));
}

# get or set the member variable 'orf_id'
sub orf_id {
    my ($self, $orf_id) = @_;
    return($self->getset('orf_id', $orf_id));
}

# get or set the member variable 'description'
sub description {
    my ($self, $description) = @_;
    return($self->getset('description', $description));
}

# get or set the member variable 'toolresult'
sub toolresult {
    my ($self, $toolresult) = @_;
    return($self->getset('toolresult', $toolresult));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'information'
sub information {
    my ($self, $information) = @_;
    return($self->getset('information', $information));
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

require GENDB::fact_add;

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
	foreach $key (qw{dbto tool_id orfto dbfrom orffrom dbref orf_id description toolresult id information}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE fact SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE fact SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

