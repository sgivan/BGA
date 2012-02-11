package GENDB::Tools::GODB;

# this package interface the GODB database
# it is used to look up similar fact associated
# with the same GO number, e.g. all interpro
# ids which corellate to a given EC number

# $Id: GODB.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: GODB.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2002/04/12 12:28:40  blinke
# Initial revision
#


use vars qw($initialized);
use strict;
use GENDB::GENDB_CONFIG qw($GENDB_GODB_PATH);

# package global variable to indicate 
# the state of this package
# >0 : package has been initialized and GODB is accesible
# -1 : not initialized yet
# -2 : unable to initalize, e.g. due to wrong paths to GODB
#      or insufficient database permissions
my $initialized = -1;

1;

# init this package
# this method tries to include the GODB modules
# if this fails (e.g. due to errornous paths)
# it return -1 and set $initialized
# on sucessful init it returns a TRUE value
sub _initialize {
    if ($initialized == -1) {
	unshift @INC,$GENDB_GODB_PATH;
	eval {require godb::go_cat;};
	if ($@) {
	    print STDERR "unable to initialize GODB module: $@\n";
	    $initialized = -2;
	    return -1;
	}
	$initialized = 1;
    }
    return $initialized;
}

# fetch all interpro-ids associated with an EC number
# by GO mapping
sub fetch_ipr_ids_for_EC_number {
    my ($class,$ec_number) = @_;
    
    if ($initialized < 0) {
	if (!_initialize) {
	    return -1;
	}
    }
    require godb::ecnr;

    my $go_numbers = godb::ecnr::fetch_go_nrs($ec_number);
    
    # nothing to do, since we got no GO numbers for that EC number
    return -1 if ($go_numbers == -1);

    my $result = [];
    foreach (@$go_numbers) {
	my $temp = godb::go_cat->fetch_interpro_ids($_);
	push @$result, @$temp if ($temp != -1);
    }
    return $result;
}
