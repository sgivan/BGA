########################################################################
#
# This module defines extensions to the automagically created file
# feature_type.pm. Add your own code below.
#
########################################################################


###################################################
###  fetch all subfeatures of a single feature  ###
###################################################
sub get_all_children {
    my( $self ) = @_;

    my @ret = ($self);

    foreach( @{$self->get_children} ) {
	push( @ret, @{ $_->get_all_children } );
    };

    return \@ret;
};


####################################################
###  fetch the children of a single feature_type ###
####################################################
sub get_children {
    my( $self ) = @_;

    my $my_id = $self->id;

    return GENDB::feature_type->fetchbySQL( "parent_feature_type = $my_id" );
};


#################################################
###  fetch the toplevel feature_types         ###
#################################################
sub get_toplevel_feature_types {
    my( $class ) = @_;

    return GENDB::feature_type->fetchbySQL( "parent_feature_type = 0" );
};


# get a feature by its name
# this should be a O2DBI-generated method since names are unique !
sub init_by_feature_name {
    my ($class, $name) = @_;
    my $features = GENDB::feature_type->fetchbySQL('name = "'.$name.'"');
    return $features->[0];
}

1;
