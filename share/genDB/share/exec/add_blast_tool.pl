#!/usr/bin/env perl
# $Id: add_blast_tool.pl,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $
# little script to simply adding new tools to GENDB

use lib "$ENV{HOME}/projects/BGA/share/genDB/share/perl";

use Projects;
use GENDB::GENDB_CONFIG qw($GENDB_BLAST_PATH $GENDB_INSTALL_DIR);
use Getopt::Std;
use strict;
use vars qw ($opt_p $opt_b $opt_d $opt_u $opt_n $opt_D $opt_g $opt_f);

# blast application management
# key = blastapp, value = suffix of database file
my $valid_blast_apps = { blast2n => 'nin',
			 blast2p => 'pin',
			 blast2x => 'pin',
			 tblast2n => 'nin',
			 tblast2x => 'nin' };

# list of input data type (0 = nucleotide, 1 = amino acid)
my $blast_input_types = { blast2n => 0,
			  blast2p => 1,
			  blast2x => 0,
			  tblast2n => 1,
			  tblast2x => 0};
my $dbpath = "/dbase/NCBI/db";
# end of config

sub usage {
    print "add_blast_tool - adst ds tools to GENDB project\n";
    print "usage: -p <project> -b <blastapp> -d <database>\n";
    print "       -D <description> -n <tool name> -u <SRS-URL>\n";
    print "where : -p <project>     name of GENDB project\n";
    print "        -b <blastapp>    blast application to use\n";
    print "                         (blastn, blastp, tblastn etc)\n";
    print "        -d <database>    filename of database file\n";
    print "        -u <SRS-URL>     URL-fragment for SRS access\n";
    print "        -n <tool name>   name for new tool\n";
    print "        -D <description> description of new tool\n";
    print "        -g               use genome helper instead of blast helper\n";
    print "        -f               disable blast filter\n\n";
}
print "GENDB_BLAST_PATH = '$GENDB_BLAST_PATH'\n";
# check whether we can use blast at all
if (!$GENDB_BLAST_PATH) {
    print "Blast-usage was not setup properly during GENDB installation\n";
    print "Add the path to blastall to the GENDB configuration file";
    print "if you want to use the blast tools for GENDB !\n";
    exit 1;
}
    
getopts('p:b:d:u:D:n:gf');

if (!$opt_p) {
    usage;
    print "no project name given !\n";
    exit 1;
}
if (!$opt_b) {
    usage;
    print "no blast application given !\n";
    exit 1;
}
if (!$opt_d) {
    usage;
    print "no database file given !\n";
    exit 1;
}
#if (!$opt_u) {
#    usage;
#    print "no SRS url given !\n";
#    exit 1;
#}
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

# check blastapp
if (!defined($valid_blast_apps->{$opt_b})) {
    usage;
    print "invalid blast application: $opt_b\n";
    exit 1;
}

# we know which blast app we use
# so check the database and whether blast indices exists

if (! -r $dbpath . "/" . $opt_d . "." . $valid_blast_apps->{$opt_b}) {
    usage;
    print "Cannot read from $opt_d\n";
    exit 1;
}
my $db_index_file_name = $dbpath . "/" . $opt_d.".".$valid_blast_apps->{$opt_b};

if (! -r $db_index_file_name) {
    usage;
    print "Cannot read from $db_index_file_name\n";
    print "Check whether blast indices are built and\n";
    print "you have specified the right blast application.\n";
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
$new_tool->input_type($blast_input_types->{$opt_b});
$new_tool->executable_name($GENDB_INSTALL_DIR."/bin/$opt_b");
$new_tool->description($opt_D);
$new_tool->dbname($opt_d);
$new_tool->dburl($opt_u);
if ($opt_g) {
    if ($opt_f) {
	$new_tool->helper_package("genome_helper_no_filter");
    }
    else {
	$new_tool->helper_package("genome_helper");
    }
} 
else {
    if ($opt_f) {
	$new_tool->helper_package("blast_helper_no_filter");
    }
    else {
	$new_tool->helper_package("blast_helper");
    }
}

my $tool_number = GENDB::tool->highest_tool_number() +1;
$new_tool->number($tool_number);

# setup tool levels
# these are default values which SHOULD be changed by the user

$new_tool->level1('1E-50');
$new_tool->level2('1E-40');
$new_tool->level3('1E-30');
$new_tool->level4('1E-20');
$new_tool->level5('1E-10');

printf "Tool %s has been added to project $opt_p. (id %d)\n",
    $opt_n, $new_tool->id;
print "You SHOULD adjust the tool level settings before using facts\n";
