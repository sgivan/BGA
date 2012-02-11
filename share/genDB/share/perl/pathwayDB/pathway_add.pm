########################################################################
#
# This module defines extensions to the automagically created file
# pathway.pm. Add your own code below.
#
########################################################################

1;

# get all objects from the database efficiently and return an array reference
sub fetchall_pathway_names {
    my ($class) = @_;
    local @pathway_names = ();
    my $sth = $pathwayDB_DBH->prepare(qq {
	SELECT pathway_name FROM pathway
	});
    $sth->execute;
    while (($pathway_name) = $sth->fetchrow_array) {
	push(@pathway_names, $pathway_name);
    }
    $sth->finish;
    return(\@pathway_names);
}



# sub foo {
#     my ($self, $arg1, $arg2) = @_;
#     ....
#     return($result);
# }
