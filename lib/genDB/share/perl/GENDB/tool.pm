########################################################################
#
# This module was created automagically.
# Do not modify this file, changes will be lost!!!
#
# Additional methods can be defined in the file GENDB::tool_add.pm.
#
########################################################################

package GENDB::tool;

use GENDB::DBMS;

1;

########################################################################
#
# constructor and destructor methods for tool
#
########################################################################

# create a new object and insert it into the database
sub create {
    my ($class, $name) = @_;
    # fetch a fresh id
    my $id = newid('tool');
        if ($id < 0) {
	return(-1);
    }
    # insert the primary key into the database
    $GENDB_DBH->do(qq {
            INSERT INTO tool (id) VALUES ($id)
           });
    if ($GENDB_DBH->err) {
	return(-1);
    }
    # create the perl object
    my $tool = { 'id' => $id,
		    '_buffer' => 1 };
    bless($tool, $class);
    # fill in the remaining data
    $tool->name($name);
    $tool->unbuffer;
    return($tool);
}

# create an object for already existing data
sub init_id {
    my ($class, $req_id) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool
		WHERE id='$req_id'
	});
    $sth->execute;
    my ($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
        bless($tool, $class);
        return($tool);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_id {
    my ($class) = @_;
    local %tool = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool
	});
    $sth->execute;
    while (($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array) {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
	bless($tool, $class);
	$tool{$id} = $tool;
    }
    $sth->finish;
    return(\%tool);
}

# get all those objects from the database efficiently that conform to the
# given WHERE clause and return an array reference
sub fetchbySQL {
    my ($class, $statement) = @_;
    local @tool = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool WHERE $statement
	});
    $sth->execute;
    while (($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array) {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
	bless($tool, $class);
	push(@tool, $tool);
    }
    $sth->finish;
    return(\@tool);
}

# create an object for already existing data
sub init_name {
    my ($class, $req_name) = @_;
    # fetch the data from the database
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool
		WHERE name='$req_name'
	});
    $sth->execute;
    my ($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array;
    $sth->finish;
    # if successful, return an appropriate object
    if (!defined($id)) {
	return(-1);
    } else {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
        bless($tool, $class);
        return($tool);
    }
}

# get all objects from the database efficiently and return a hash reference
sub fetchallby_name {
    my ($class) = @_;
    local %tool = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool
	});
    $sth->execute;
    while (($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array) {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
	bless($tool, $class);
	$tool{$name} = $tool;
    }
    $sth->finish;
    return(\%tool);
}

# get all objects from the database efficiently and return an array reference
sub fetchall {
    my ($class) = @_;
    local @tool = ();
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT input_type, name, executable_name, description, dbname, dburl, cost, number, level1, level2, helper_package, level3, user_value, level4, level5, id FROM tool
	});
    $sth->execute;
    while (($input_type, $name, $executable_name, $description, $dbname, $dburl, $cost, $number, $level1, $level2, $helper_package, $level3, $user_value, $level4, $level5, $id) = $sth->fetchrow_array) {
	my $tool = {
		'input_type' => $input_type, 
		'name' => $name, 
		'executable_name' => $executable_name, 
		'description' => $description, 
		'dbname' => $dbname, 
		'dburl' => $dburl, 
		'cost' => $cost, 
		'number' => $number, 
		'level1' => $level1, 
		'level2' => $level2, 
		'helper_package' => $helper_package, 
		'level3' => $level3, 
		'user_value' => $user_value, 
		'level4' => $level4, 
		'level5' => $level5, 
		'id' => $id
		};
	bless($tool, $class);
	push(@tool, $tool);
    }
    $sth->finish;
    return(\@tool);
}

# delete an object completely from the database
sub delete {
    my ($self) = @_;
    my $id = $self->id;
    $GENDB_DBH->do(qq {
	DELETE FROM tool WHERE id=$id
	}) || return(-1);
    undef($self);
}

########################################################################
#
# methods to access the member variables
#
########################################################################

# get or set the member variable 'input_type'
sub input_type {
    my ($self, $input_type) = @_;
    return($self->getset('input_type', $input_type));
}

# get or set the member variable 'name'
sub name {
    my ($self, $name) = @_;
    return($self->getset('name', $name));
}

# get or set the member variable 'executable_name'
sub executable_name {
    my ($self, $executable_name) = @_;
    return($self->getset('executable_name', $executable_name));
}

# get or set the member variable 'description'
sub description {
    my ($self, $description) = @_;
    return($self->getset('description', $description));
}

# get or set the member variable 'dbname'
sub dbname {
    my ($self, $dbname) = @_;
    return($self->getset('dbname', $dbname));
}

# get or set the member variable 'dburl'
sub dburl {
    my ($self, $dburl) = @_;
    return($self->getset('dburl', $dburl));
}

# get or set the member variable 'cost'
sub cost {
    my ($self, $cost) = @_;
    return($self->getset('cost', $cost));
}

# get or set the member variable 'number'
sub number {
    my ($self, $number) = @_;
    return($self->getset('number', $number));
}

# get or set the member variable 'level1'
sub level1 {
    my ($self, $level1) = @_;
    return($self->getset('level1', $level1));
}

# get or set the member variable 'level2'
sub level2 {
    my ($self, $level2) = @_;
    return($self->getset('level2', $level2));
}

# get or set the member variable 'helper_package'
sub helper_package {
    my ($self, $helper_package) = @_;
    return($self->getset('helper_package', $helper_package));
}

# get or set the member variable 'level3'
sub level3 {
    my ($self, $level3) = @_;
    return($self->getset('level3', $level3));
}

# get or set the member variable 'user_value'
sub user_value {
    my ($self, $user_value) = @_;
    return($self->getset('user_value', $user_value));
}

# get or set the member variable 'level4'
sub level4 {
    my ($self, $level4) = @_;
    return($self->getset('level4', $level4));
}

# get or set the member variable 'level5'
sub level5 {
    my ($self, $level5) = @_;
    return($self->getset('level5', $level5));
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

require GENDB::tool_add;

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
	foreach $key (qw{input_type name executable_name description dbname dburl cost number level1 level2 helper_package level3 user_value level4 level5 id}) {
	    push(@sql, "$key=".$GENDB_DBH->quote($self->{$key}));
	}
	my $id = $self->id;
	my $sql = "UPDATE tool SET ".join(', ', @sql)." WHERE id=$id";
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
		UPDATE tool SET $var=$qval WHERE id=$id
		}) || return(-1);
	}
	$self->{$var} = $val;
    }
    return($self->{$var});
}

