#!/bin/sh

# backup.sh
# By: Lorenzo Van Munoz
# On: 27/03/2021

USAGE="Usage: backup.sh [-h]

Description: Incremental backup script with tar

Options:
-h  show this message and exit

Details:
When called without arguments, performs an incremental backup of
files in backup_files.conf, excluding patterns in backup_ignore.conf.
Specify the backup directory in a backup_destination.conf.
To configure the frequency/level of full backups, edit backup_conf.sh.
"

if [ "$1" = "-h" ]
then
    echo "$USAGE"
    exit 0
fi

cd `dirname $0`

# Import
. ./backup_brains.sh

# Background

# Define
# Level Frequency of Full dumps
#   0   Daily
#   1   Weekly
#   2   Monthly
#   3   Yearly

# Extension Scheme
# archive.YYYY_MM_WW_D.I-L.snar
# archive.YYYY_MM_WW_D.I-L.tar
# YYYY is the 4-digit year
# MM is the month of the year
# WW is the week of the year
# D is the day of the week
# I in the ith increment per day
# (which is meaningless for snar)
# L is the level >= 0
# .tar is a Tape ARchive file
# .snar is a SNapshot ARchive file

# Note:
# This scheme will sort files by date,
# increment, and then level so that
# less sorting needs to be done later

# Note:
# A new week starts every Sunday
# A month is every 4 weeks

# Note:
# Allowing increments and snapshots per day
# may be relevant if large files should
# be backed up in real time or if there
# is an urgent need to backup latest work.
# By configuring I, someone may be able to
# create a backup rule for level L > 3 backups
# which occur on a shorter-than-one-day basis.
# To create longer-term leveled backups, consider
# using the digits of the year for decade,
# century, and millenial incremental backups.
# Some set of rules needs to be imposed and this
# script implements something reasonable

# A value of L = 0 is a full backup
# L = 1 backups are increments of L = 0 backups
# ...
# L = n backups are increments of L = n - 1 backups

# To properly do multi-level backups, read the
# manual page for tar, the --listed-incremental flag.
# The naming needs to provide all the information
# to identify the level so that all the associated .tar
# files can be retrieved to restore the file system
# (though that is the responsibility of another script)

# Get date
DATE=`date +%Y_%m_%U_%w`

if [ $LEVEL -eq 0 ]
then
    # choose name
    BACKUP_ARXV="${BACKUP_DEST}/${PREFIX}.${DATE}.0-0.tar"

    # ask for input if name is already taken
    if [ -f "$BACKUP_ARXV" ]
    then
        echo "A backup from today already exists. Overwrite [y] or save [s] another backup? [y/s/N]" 1>&2
        read input
        if [ "$input" = "y" ]
        then
            BACKUP_ARXV="$BACKUP_ARXV"
        elif [ "$input" = "s" ]
        then
            BACKUP_ARXV=`increment "$BACKUP_ARXV"`
        else
            echo Exiting 1>&2
            exit 0
        fi
    fi

    # make (full) backup
    tar -c -P \
        -f "$BACKUP_ARXV" \
        -X "$BACKUP_IGNR" \
        -T "$BACKUP_FILE"

elif [ $LEVEL -gt 0 ]
then

    choose_incr_backup $DATE

    # ask for input if name is already taken
    if [ -f "$BACKUP_ARXV" ]
    then
        echo "A backup from today already exists. Increment archive? [y/N]" 1>&2
        read input
        if [ "$input" = "y" ]
        then
            BACKUP_ARXV=`increment "$BACKUP_ARXV"`
        else
            echo Exiting 1>&2
            exit 0
        fi
    fi

    # make backup (full or incremental)
    tar -c -P \
        -g "$BACKUP_SNAR" \
        -f "$BACKUP_ARXV" \
        -X "$BACKUP_IGNR" \
        -T "$BACKUP_FILE"

    # Make a copy for the snar available at the next level so that
    # next time the script can go a level higher except at top or bottom
    ARXV_LEVEL=`file_level "$BACKUP_ARXV"`
    if [ $ARXV_LEVEL -ne $LEVEL -a $ARXV_LEVEL -ne 0 ]
    then # Not at top or bottom
        cp \
            "$BACKUP_SNAR" \
            `raise_snar $DATE`
    fi

fi

exit 0

