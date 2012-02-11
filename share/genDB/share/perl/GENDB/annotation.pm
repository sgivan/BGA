########################################################################
#
# This module was created automagically by O2DBI (1.24)
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::annotation_add.pm.
#
########################################################################

package GENDB::annotation;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for annotation
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $name, $orf_id) = @_;
    # fetch a fresh id
    my $id = newid('annotation');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO annotation (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $annotation = { 'id' => $id,
		    '_buffer' => 1 };
    bless($annotation, $class);
    # fill in the remaining data
    $annotation->name($name);
    $annotation->orf_id($orf_id);
    if ($annotation->unbuffer < 0) {
	$annotation->delete;
	return(-1);
    } else {
	return($annotation);
    }
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, offset, ec, feature_type, id, category, date, tool_id FROM annotation
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($product, $name, $annotator_id, $comment, $orf_id, $description, $offset, $ec, $feature_type, $id, $category, $date, $tool_id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $annotation = {
		'product' => $product, 
		'name' => $name, 
		'annotator_id' => $annotator_id, 
		'comment' => $comment, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'offset' => $offset, 
		'ec' => $ec, 
		'feature_type' => $feature_type, 
		'id' => $id, 
		'category' => $category, 
		'date' => $date,
		'tool_id' => $tool_id,
		};
        bless($annotation, $class);
        return($annotation);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %annotation = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, offset, ec, feature_type, id, category, date, tool_id FROM annotation
	});
    $sth->execute;
    while (($product, $name, $annotator_id, $comment, $orf_id, $description, $offset, $ec, $feature_type, $id, $category, $date, $tool_id) = $sth->fetchrow_array) {
	my $annotation = {
		'product' => $product, 
		'name' => $name, 
		'annotator_id' => $annotator_id, 
		'comment' => $comment, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'offset' => $offset, 
		'ec' => $ec, 
		'feature_type' => $feature_type, 
		'id' => $id, 
		'category' => $category, 
		'date' => $date,
		'tool_id' => $tool_id,
		};
	bless($annotation, $class);
	$annotation{$id} = $annotation;
    }
    $sth->finish;
    return(\%annotation);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @annotation = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, offset, ec, feature_type, id, category, date, tool_id FROM annotation WHERE $statement
	});
    $sth->execute;
    while (($product, $name, $annotator_id, $comment, $orf_id, $description, $offset, $ec, $feature_type, $id, $category, $date, $tool_id) = $sth->fetchrow_array) {
	my $annotation = {
		'product' => $product, 
		'name' => $name, 
		'annotator_id' => $annotator_id, 
		'comment' => $comment, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'offset' => $offset, 
		'ec' => $ec, 
		'feature_type' => $feature_type, 
		'id' => $id, 
		'category' => $category, 
		'date' => $date,
		'tool_id' => $tool_id,
		};
	bless($annotation, $class);
	push(@annotation, $annotation);
    }
    $sth->finish;
    return(\@annotation);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @annotation = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT product, name, annotator_id, comment, orf_id, description, offset, ec, feature_type, id, category, date, tool_id FROM annotation
	});
    $sth->execute;
    while (($product, $name, $annotator_id, $comment, $orf_id, $description, $offset, $ec, $feature_type, $id, $category, $date, $tool_id) = $sth->fetchrow_array) {
	my $annotation = {
		'product' => $product, 
		'name' => $name, 
		'annotator_id' => $annotator_id, 
		'comment' => $comment, 
		'orf_id' => $orf_id, 
		'description' => $description, 
		'offset' => $offset, 
		'ec' => $ec, 
		'feature_type' => $feature_type, 
		'id' => $id, 
		'category' => $category, 
		'date' => $date,
		'tool_id' => $tool_id,
		};
	bless($annotation, $class);
	push(@annotation, $annotation);
    }
    $sth->finish;
    return(\@annotation);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM annotation WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'product'
sub product {
    my ($self, $product) = @_;
    return($self->getset('product', $product));
}

# get or set the member variable 'name'
sub name {
    my ($self, $name) = @_;
    return($self->getset('name', $name));
}

# get or set the member variable 'annotator_id'
sub annotator_id {
    my ($self, $annotator_id) = @_;
    return($self->getset('annotator_id', $annotator_id));
}

# get or set the member variable 'comment'
sub comment {
    my ($self, $comment) = @_;
    return($self->getset('comment', $comment));
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

# get or set the member variable 'offset'
sub offset {
    my ($self, $offset) = @_;
    return($self->getset('offset', $offset));
}

# get or set the member variable 'ec'
sub ec {
    my ($self, $ec) = @_;
    return($self->getset('ec', $ec));
}

# get or set the member variable 'feature_type'
sub feature_type {
    my ($self, $feature_type) = @_;
    return($self->getset('feature_type', $feature_type));
}

# get the member variable 'id'
sub id {
    my ($self) = @_;
    return($self->{'id'});
}

# get or set the member variable 'category'
sub category {
    my ($self, $category) = @_;
    return($self->getset('category', $category));
}

# get or set the member variable 'date'
sub date {
    my ($self, $date) = @_;
    return($self->getset('date', $date));
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

require GENDB::annotation_add;

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
	foreach $key (qw{product name annotator_id comment orf_id description offset ec feature_type id category date}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE annotation SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE annotation SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

