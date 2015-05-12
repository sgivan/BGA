########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::orf_add.pm.
#
########################################################################

package GENDB::orf;
# $Id: orf.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $
use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for orf
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $contig_id, $start, $stop, $name) = @_;
#    print "hello: class='$class', name='$name'\n";
    # fetch a fresh id
    my $id = newid('orf');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO orf (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
    	return(-1);
    }
    # create the perl object
    my $orf = { 'id' => $id,
		    '_buffer' => 1 };
    bless($orf, $class);
    # fill in the remaining data
    $orf->contig_id($contig_id);
    $orf->start($start);
    $orf->stop($stop);
    $orf->name($name);
    $orf->unbuffer;
    return($orf);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
        bless($orf, $class);
        return($orf);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %orf = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
	});
    $sth->execute;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, $class);
	$orf{$id} = $orf;
    }
    $sth->finish;
    return(\%orf);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @orf = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf WHERE $statement
	});
    $sth->execute;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, $class);
	push(@orf, $orf);
    }
    $sth->finish;
    return(\@orf);
}

# create an object for already existing data
sub init_name {
    my ($class, $req_name) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
		WHERE name='$req_name'
	});
    $sth->execute;
    my ($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
        bless($orf, $class);
        return($orf);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_name {
    my ($class) = @_;
    local %orf = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
	});
    $sth->execute;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, $class);
	$orf{$name} = $orf;
    }
    $sth->finish;
    return(\%orf);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @orf = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
	});
    $sth->execute;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, $class);
	push(@orf, $orf);
    }
    $sth->finish;
    return(\@orf);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM orf WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'molweight'
sub molweight {
    my ($self, $molweight) = @_;
    return($self->getset('molweight', $molweight));
}

# get or set the member variable 'contig_id'
sub contig_id {
    my ($self, $contig_id) = @_;
    return($self->getset('contig_id', $contig_id));
}

# get or set the member variable 'startcodon'
sub startcodon {
    my ($self, $startcodon) = @_;
    return($self->getset('startcodon', $startcodon));
}

# get or set the member variable 'name'
sub name {
    my ($self, $name) = @_;
    return($self->getset('name', $name));
}

# get or set the member variable 'status'
sub status {
    my ($self, $status) = @_;
    return($self->getset('status', $status));
}

# get or set the member variable 'stop'
sub stop {
    my ($self, $stop) = @_;
    return($self->getset('stop', $stop));
}

# get or set the member variable 'ag'
sub ag {
    my ($self, $ag) = @_;
    return($self->getset('ag', $ag));
}

# get or set the member variable 'gc'
sub gc {
    my ($self, $gc) = @_;
    return($self->getset('gc', $gc));
}

# get or set the member variable 'frame'
sub frame {
    my ($self, $frame) = @_;
    return($self->getset('frame', $frame));
}

# get or set the member variable 'isoelp'
sub isoelp {
    my ($self, $isoelp) = @_;
    return($self->getset('isoelp', $isoelp));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'start'
sub start {
    my ($self, $start) = @_;
    return($self->getset('start', $start));
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

require GENDB::orf_add;

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
	foreach $key (qw{molweight contig_id startcodon name status stop ag gc frame isoelp id start}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE orf SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE orf SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

