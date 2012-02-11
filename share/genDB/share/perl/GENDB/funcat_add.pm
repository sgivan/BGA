########################################################################
#
# This module defines extensions to the automagically created file
# funcat.pm. Add your own code below.
#
########################################################################


##################################################
###  fetch all subfuncats for a single funcat  ###
##################################################
sub get_all_children {
    my( $self ) = @_;

    my @ret = ($self);

    foreach( @{$self->get_children} ) {
	push( @ret, @{ $_->get_all_children } );
    };

    return \@ret;
};


################################################
###  fetch the children for a single funcat  ###
################################################
sub get_children {
    my( $self ) = @_;

    my $my_id = $self->id;

    return GENDB::funcat->fetchbySQL( "parent_funcat = $my_id" );
};


####################################
###  fetch the toplevel funcats  ###
####################################
sub get_toplevel_funcats {
    my( $class ) = @_;

    return GENDB::funcat->fetchbySQL( "parent_funcat = 0" );
};


###########################################
###  fetch the toplevel parent funcat   ###
###########################################
sub get_toplevel_parent {
    my( $self ) = @_;

    my $id = $self->parent_funcat;
    my $parent = $self;

    while( $id != 0 ) {
	$parent = GENDB::funcat->init_id( $id );
	$id = $parent->parent_funcat;
    };

    return $parent;
};


1;
