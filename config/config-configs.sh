#!/bin/sh

# config-configs.sh
# Lorenzo Van Munoz
# Feb 24 2021

# Script makes symbolic links of config files
# to home directory

# Run with `sh <script>.sh` (option 1)

# To execute correctly `chmod +x` the script
# and then run `./<script>.sh` so that it runs
# in its own process and resolves its path

# You can't `source` the script because it runs
# the commands in the shell as if you typed them
# as explained in `source --help`

CONFIG_PATH=`readlink -f "$0"`
CONFIG_FILE=`basename $CONFIG_PATH`
CONFIG_DIR=`dirname $CONFIG_PATH`
HOME_DIR=`readlink -f ~`

USAGE="
$CONFIG_FILE [-h]

Script to symlink config files to home directory

options:
    -h  show this help message and exit
"

if [ "$1" = "-h" ]
then
    echo "$USAGE"
    exit 0
fi

echo copying config files
echo at $CONFIG_DIR
echo to $HOME_DIR

for i in `ls -a $CONFIG_DIR`
do
    if [ -e $HOME_DIR/$i ]
    then
        echo $i already exists in $HOME_DIR
    else
        echo $i not present in $HOME_DIR
        # make symlinks (interactively?)
        echo "make symlink? [y/N]"
        read BOOL
        if [ "$BOOL" = "y" ]
        then
            ln -s  $CONFIG_DIR/$i $HOME_DIR/$i
        fi
    fi
done

exit 0
