package GENDB::Tools::Importer;

# super import class of GENDB
# this class is the toplevel class for all
# import filters
#
# each subclass is derived from this class
# and has to stick to its API

# $Id: Importer.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: Importer.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.1  2001/11/14 16:05:20  blinke
# Initial revision
#

use Carp qw(croak);
1;

# create a new importer
# parameter: $filename        file to import
#            $add_parameters  scalar to pass additional parameters
#
# add_parameter should be used by subclasses to configure arbitary
# options (e.g. the glimmer model file for fasta import)
#
# returns:   Import object ref
sub new {
    my ($class, $filename, $add_parameters) = @_;

    my $self = {file => $filename };
    
    bless $self, ref $class || $class;
    return $self;

}

# returns the name of the pseudo-annotator
# for this importer
sub annotator_name {
    croak "Abstract method 'annotator_name' called in GENDB::Tools::Import !";
}

# parse input file
# return: error message     if error occured
#         undef             if file was parsed without any error
sub parse {
    my ($self) = @_;

    # since this is an abstract class,
    # return at once
    return "Abstract method 'parse' called in GENDB::Tools::Import !";
}

# imports parsed sequence information to GENDB
# 
# parameters: $callback   code ref to inform about errors
#
# returns: undef         on succes
#          error message on failure
#
# the callback's parameters depend on the kind of error/information
# to report. refer to subclass documentation for more information
sub import_data {
    my ($self, $callback) = @_;

    # this is an abstract class, calling this method is
    # considered a failure
    return "Abstract method 'import' called in GENDB::Tools::Import !";
}
