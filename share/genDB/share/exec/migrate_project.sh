#!/bin/sh

# little script to copy GENDB 1.0.5 project configuration 
# to GENDB 1.1

### config area
GENDB_INSTALL_DIR=$HOME/projects/BGA/share/genDB
PATH=/bin:/usr/bin

usage ()
{
    echo "migrate_project - migrates a GENDB 1.0.5 project to GENDB 1.1"
    echo "usage: migrate_project <GENDB 1.0.5 directory> <project name>"
    echo 
    echo "This script copies the project configuration files from GENDB"
    echo "1.0.5 to GENDB 1.1 and creates an entry in the project list."
    echo
}

if [ $# = 0 ]; then
    usage;
    exit 0
fi

if [ $# = 1 ]; then
    usage;
    exit 0
fi

old_gendb_dir=$1; shift
project_name=$1; shift

echo -n "Checking project..."
if [! -e $old_gendb_dir/lib/$project_name/GENDB/Config.pm ]; then
    echo "not found, aborting"
    echo
    exit 1
fi
echo "found"

echo -n "Copying files..."
cp -R $old_gendb_dir/lib/$project_name $GENDB_INSTALL_DIR/lib
echo "done"

echo -n "Appending $project_name to projects list..."
echo "$project_name $old_gendb_dir/lib/$project_name" >> $GENDB_INSTALL_DIR/lib/projects.lst
echo "done"
echo

