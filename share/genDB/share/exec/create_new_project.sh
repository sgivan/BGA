#!/bin/sh

# little script to initialize a new project database for GENDB

# $Id: create_new_project.sh,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: create_new_project.sh,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.3  2001/06/26 11:38:25  tk
# don't require db password on cmdline
# reduce # mysql client calls
#
# Revision 1.2  2001/05/30 15:55:48  tk
# *** empty log message ***
#
# Revision 1.1  2001/05/30 15:37:00  blinke
# Initial revision
#
# Revision 1.1  2001/05/30 15:34:37  blinke
# Initial revision
#

### config area
GENDB_INSTALL_DIR=$HOME/projects/BGA/share/genDB
PATH=/bin:/usr/bin:$HOME/projects/BGA/bin
    
DEFAULT_SQL_SCRIPT=$GENDB_INSTALL_DIR/share/sql-scripts/main_init.sql
CUSTOM_SCRIPTS_DIR=$GENDB_INSTALL_DIR/share/sql-scripts/custom_sql_scripts

#DEFAULT_SQL_SERVER=localhost
#DEFAULT_SQL_SERVER=littlegac.science.oregonstate.local
DEFAULT_SQL_SERVER=pearson.science.oregonstate.local

# end of configuration


# most stuff should be leaved untouched....

usage ()
{
    echo "create_new_project.sh - create standard entries for new GENDB projects"
    echo "usage: create_new_project [-d -h <dbhost> -u <user> -p ] project description"
    echo "where: -d              debug mode"
    echo "                       (echo SQL command instead of sending to server)"
    echo "       -h <dbhost>     hostname of database server"
    echo "       -u <user>       username for database connection"
    echo "       -p              use a password for database authentification ?"
    echo "       project         name of GENDB project"
    echo "       description     description of new project"
    echo
}

if [ $# = 0 ]; then
    usage;
    exit 0
fi

# read command line parameters

while getopts "dh:u:p" par; do
    case "$par" in
    d) debug=1 ;;
    h) dbhost=$OPTARG ;;
    u) username=$OPTARG ;;
    p) use_password=1 ;;
    \?) echo
	usage
        exit 1 ;;
    esac
done
shift `expr $OPTIND - 1`

project=$1; shift

description=$1; shift

if [ "${project}z" = "z" ]; then
    usage;
    echo "no project name given..."
    exit 1;
fi

# use the default host if no dbhost is given as commandline argument
if [ -z "$dbhost" ]; then
    echo "no database host given, using default host '$DEFAULT_SQL_SERVER'";
    dbhost=$DEFAULT_SQL_SERVER
fi
 
databasename="${project}_gendb"

mysql_bin=`which mysql`

if [ -z $mysql_bin ]; then
    usage;
    echo "mysql binary not found in your path, aborting..."
    exit 1;
fi

if [ $debug ]; then
    mysql_call="cat";
else
    mysql_call="$mysql_bin ${dbhost:+-h $dbhost} ${username:+--user=$username} ${use_password:+-p} $databasename";
fi

echo -n checking for database..

$mysql_call <<EOF
show tables;
EOF

if [ ! $? ]; then
    echo "cannot connect to database, aborting..."
    exit 1
fi

echo creating standard entries for project $project

echo -n "creating tables...."
cat $DEFAULT_SQL_SCRIPT  ${CUSTOM_SCRIPTS_DIR}/*.sql | $mysql_call || {
    echo "failed"
    echo "error(s) occured during initializing of the database"
    echo "in most cases this renders the database useless"
    echo "drop and recreate the database and rerun this script"
    exit 1
}

echo "done"

projectdir=$GENDB_INSTALL_DIR/lib/$project
mkdir -p $projectdir
mkdir -p $projectdir/GENDB

echo -n "creating project perl module..."
perlfile=$projectdir/GENDB/Config.pm
cat <<EOF > $perlfile
package GENDB::Config;

#
# configure GENDB for $project project
#

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(\$GENDB_CODON \$GENDB_PROJECT \$GENDB_DBSOURCE \$GENDB_CONFIG);

\$GENDB_CODON = 0;
\$GENDB_PROJECT = "$description";
\$GENDB_DBSOURCE = "DBI:mysql:$databasename:$dbhost";
\$GENDB_CONFIG = "$project";

EOF

echo done

echo -n "creating project configuration..."
configfile=$projectdir/GENDB/.gendbproject.rc
cat <<EOF > $configfile
[defaults]
genetic code=4
signalp_tool format=summary
signalp_tool type=gram+
signalp_tool trunc=80
gene products=hypothetical protein predicted by Glimmer/Critica,conserved hypothetical protein,putative secreted protein,putative membrane protein

EOF

echo done

echo -n "adding project to project list..."

echo "$project $projectdir" >> $GENDB_INSTALL_DIR/lib/projects.lst
echo "done"

echo "You should now add tool to your new project."
echo "Use the add_*_tool scripts in ${GENDB_INSTALL_DIR}."
