#!/usr/bin/env perl

# little script to simply adding interpro tools to GENDB

use lib "/local/cluster/genDB/share/perl";

use Projects;
use GENDB::GENDB_CONFIG qw($GENDB_INTERPRO_DIR);
use Getopt::Std;
use strict;
use vars qw ($opt_p $opt_n $opt_D);


sub usage {
    print "add_interpro_tool - adds interpro tool to GENDB project\n";
    print "usage: -p <project> -D <description> -n <tool name>\n";
    print "where : -p <project>     name of GENDB project\n";
    print "        -n <tool name>   name for new tool\n";
    print "        -D <description> description of new tool\n";
}

# check whether we can use interpro at all
if (!$GENDB_INTERPRO_DIR) {
    print "InterPRO-usage was not setup properly during GENDB installation\n";
    print "Add the path to your InterPRO directory to the GENDB configuration\n";
    print "file if you want to use the InterPRO tool for GENDB !\n";
    exit 1;
}
getopts('p:D:n:');

if (!$opt_p) {
    usage;
    print "no project name given !\n";
    exit 1;
}

if (!$opt_n) {
    usage;
    print "no tool name given !\n";
    exit 1;
}
if (!$opt_D) {
    usage;
    print "no description given !\n";
    exit 1;
}

# start sanity checks

# initialize project
Projects::init_project($opt_p);

require GENDB::tool;

if (length($opt_n)>20) {
    print "stripping tool name to ";
    $opt_n = substr($opt_n,0,20);
    print "$opt_n\n";
}

# check whether the tool name is valid
my $tool_check = GENDB::tool->init_name($opt_n);
if ($tool_check != -1) {
    usage;
    print "tool $opt_n already exists, please choose\n";
    print "another tool name\n";
    exit 1;
}

# so everything seems to be ok....lets rumble

my $new_tool = GENDB::tool->create($opt_n);

# fill in the record fields...
$new_tool->input_type(1);
$new_tool->executable_name(""); # the global config file is used for this
$new_tool->description($opt_D);
$new_tool->dburl("INTERPRO");
$new_tool->helper_package("interpro_helper");
my $tool_number = GENDB::tool->highest_tool_number() +1;
$new_tool->number($tool_number);

# no need to setup the tool levels
# this is done in the global config file

printf "Tool %s has been added to project $opt_p. (id %d)\n",
    $opt_n, $new_tool->id;
