#!/usr/bin/env perl

# little script to simply adding new tools to GENDB

use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";

use Projects;
use GENDB::GENDB_CONFIG qw($GENDB_PFAM $PFAM_DB_DIR);
use Getopt::Std;
use strict;
use vars qw ($opt_p $opt_d $opt_u $opt_n $opt_D);

sub usage {
    print "add_pfam_tool - adds hmmpfam tool to GENDB project\n";
    print "usage: -p <project> -d <database> -n <tool name>\n";
    print "       -D <description> -u <SRS-URL>\n";
    print "where : -p <project>     name of GENDB project\n";
    print "        -d <database>    filename of database file\n";
    print "        -u <SRS-URL>     URL-fragment for SRS access\n";
    print "        -n <tool name>   name for new tool\n";
    print "        -D <description> description of new tool\n";
}

# check whether we can use pfam at all
if (!$GENDB_PFAM) {
    print "Pfam-usage was not setup properly during GENDB installation\n";
    print "Add the path to hmmpfam and hmmfetch to the GENDB configuration file";
    print "if you want to use the Pfam tool for GENDB !\n";
    exit 1;
}

getopts('p:d:u:D:n:');

if (!$opt_p) {
    usage;
    print "no project name given !\n";
    exit 1;
}

if (!$opt_d) {
    if (!$PFAM_DB_DIR) {
	usage;
	print "no database file given and no default database configured\n";
	exit 1;
    }
    print "no database file given, using default database ".$PFAM_DB_DIR."/Pfam\n";
    $opt_d = $PFAM_DB_DIR."/Pfam";
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

# we know which blast app we use
# so check the database and whether blast indices exists

if (! -r $opt_d) {
    usage;
    print "Cannot read from $opt_d\n";
    exit 1;
}

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
$new_tool->executable_name(""); # pfam_helper gets its executable name
                                # from the global config file
$new_tool->description($opt_D);
$new_tool->dbname($opt_d);
$new_tool->dburl($opt_u);
$new_tool->helper_package("pfam_helper");
my $tool_number = GENDB::tool->highest_tool_number() +1;
$new_tool->number($tool_number);

# setup tool levels
# these are default values which SHOULD be changed by the user

$new_tool->level1('1E-30');
$new_tool->level2('1E-20');
$new_tool->level3('1E-10');
$new_tool->level4('1E-5');
$new_tool->level5('1E-3');

printf "Tool %s has been added to project $opt_p. (id %d)\n",
    $opt_n, $new_tool->id;
print "You SHOULD adjust the tool level settings before using facts\n";
