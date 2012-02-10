#!/usr/bin/env perl
# $Id: add_user.pl,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

use lib "/local/cluster/genDB/share/perl";
use strict;
use vars qw($opt_p $opt_l $opt_d $opt_r $opt_U $opt_P $opt_a);
use Getopt::Std;
use GENDB::GENDB_CONFIG;
use DBI;
use Carp qw(croak);

require Projects;

### config area

# default rights for the three database tables
my $project_rights="INSERT,SELECT,UPDATE,DELETE";
my $pathway_rights="SELECT";
my $job_rights="INSERT,SELECT,UPDATE,DELETE";

### end of configuration

sub usage {
    print "add_user - adds a new user to a project\n";
    print "usage: add_user [-r] -l <new user> -d <description> -p project\n";
    print "where: -p project        name of GENDB project\n";
    print "       -l <new user>     login name of new user\n";
    print "       -d <description>  user description, used for annotator entry\n";
    print "       -r                restricts access to local host\n";
    print "       -U user name      user name used for database connect\n";
    print "       -P password       password used for database connect\n";
    print "       -a                add user as annotator\n";
    print "The user using this command should have sufficient permissions\n";
    print "to grant permissions to other users. Use the -u and -p parameters\n";
    print "to select the user name used for database connect (e.g. root)\n";
    print "The new user is automatically added to the annotator list of\n";
    print "the project if the option -a is given, using the username and\n";
    print "user description\n";
}

getopts('p:l:d:rU:P:a');

if (!$opt_p) {
    usage;
    print "\nno project name given\n\n";
    exit 1;
}

if (!$opt_l) {
    usage;
    print "\nno user name given\n\n";
    exit 1;
}

if (!$opt_d) {
    usage;
    print "\nno user description given\n\n";
    exit 1;
}
Projects::init_project($opt_p);

my (undef,undef,$project_table,$dbhost) = split /:/,$GENDB::Config::GENDB_DBSOURCE;

print "Connecting to $GENDB::Config::GENDB_DBSOURCE, $opt_U, $opt_P\n";
#my $dbh = DBI->connect($GENDB::Config::GENDB_DBSOURCE,$opt_U, $opt_P) or
my $dbh = DBI->connect($GENDB::Config::GENDB_DBSOURCE,$opt_U) or
    die "Cannot connect to database: $!\n";

# ok, we got a connection to the database
# now ´grant´ the rights to the user

# job database
$dbh->do("GRANT $job_rights ON gendb_jobs.* TO $opt_l\@localhost");
croak "error accesing database: ".$dbh->errstr if ($dbh->err);
$dbh->do("GRANT $job_rights ON gendb_jobs.* TO '$opt_l\@%'") if (!$opt_r);
croak "error accesing database: ".$dbh->errstr if ($dbh->err);

# pathway database
$dbh->do("GRANT $pathway_rights ON pathwaydb.* TO $opt_l\@localhost");
croak "error accesing database: ".$dbh->errstr if ($dbh->err);
$dbh->do("GRANT $pathway_rights ON pathwaydb.* TO '$opt_l\@%'") if (!$opt_r);
croak "error accesing database: ".$dbh->errstr if ($dbh->err);

# project database
$dbh->do("GRANT $project_rights ON ${project_table}.* TO $opt_l\@localhost");
croak "error accesing database: ".$dbh->errstr if ($dbh->err);
$dbh->do("GRANT $project_rights ON ${project_table}.* TO '$opt_l\@%'") if (!$opt_r);
croak "error accesing database: ".$dbh->errstr if ($dbh->err);

print "access granted to user $opt_l for project $opt_p\n";

if ($opt_a) {
    print "adding new user as annotator...";
    require GENDB::annotator;
    my $dummy=GENDB::annotator->init_name($opt_l);
    if (ref($dummy)) {
	print "failed\n";
	print "An annotator called $opt_l already exists.\n";
	exit 1;
    }
    my $new_annot=GENDB::annotator->create;
    if (ref($new_annot)) {
	$new_annot->name($opt_l);
	$new_annot->description($opt_d);
	print "done\n\n";
    }
    else {
	print "failed\n";
	print "You should add the new user manually to the annotator list\n";
    }
}

