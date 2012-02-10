#!/usr/bin/env perl

# little script to simply delete tools from GENDB

#use lib "@GENDB_INSTALL_DIR@/share/perl";
use lib "/local/cluster/genDB/share/perl";

use Projects;
use Getopt::Std;
use strict;
use vars qw ($opt_p $opt_n);

sub usage {
    print "delete_tool - delete tool from GENDB project\n";
    print "usage: -p <project> -n <tool name>\n";
    print "where : -p <project>     name of GENDB project\n";
    print "        -n <tool name>   name of tool to be deleted\n";
}

    
getopts('p:n:');

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
# start sanity checks

# initialize project
Projects::init_project($opt_p);

require GENDB::tool;

my $tool = GENDB::tool->init_name($opt_n);
if ($tool == -1) {
    usage;
    print "There no tool called $opt_n in project $opt_p !\n";
    exit 1;
}

printf "About to delete tool %s (%s) and related data\n", $tool->name, 
    $tool->description;
print "Press <ENTER> to continue or <CTRL>-<C> to abort.";

my $last_chance = <STDIN>;

# no abort, so delete the tool

$tool->delete_complete;

print "Tool $opt_n deleted.\n\n";
