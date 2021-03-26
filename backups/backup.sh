#!/bin/sh

# backup.sh
# By: Lorenzo Van Munoz
# On: 26/03/2021

USAGE="Usage: backup.sh [-h] [-y]

Description: Incremental backup script with tar

Options:
-h  show this message and exit
-y  always save latest incremental changes to archive

Details:
When called without arguments, performs an incremental backup of
files in backup_files.txt, excluding patterns in backup_ignore.txt.
Specify the backup directory in a backup_destination.txt.
To configure the frequency/level of full backups, edit backup_configuration.txt.
"

if [ "$1" = "-h" ]
then
    echo "$USAGE"
    exit 0
elif [ "$1" = "-y" ]
then
    SAVE="$1"
fi

# Configurable
. ./backup.conf.sh
. ./backup.read.conf.sh

# Background

# Define
# Level Frequency of Full dumps
#   0   Daily
#   1   Weekly
#   2   Monthly
#   3   Yearly

# Extension Scheme
# archive-L.YYYY.MM.W.D.snar
# archive-L.YYYY.MM.W.D.I.tar
# L is the level >= 0
# YYYY is the 4-digit year
# MM is the month of the year
# W is the week of the year
# D is the day of the week
# I in the ith increment per day
# .tar is a Tape ARchive file
# .snar is a SNapshot ARchive file
# A new week starts every Sunday
# A month is every 4 weeks
# Note: allowing increments per day
# may be relevant if large files should
# be backed up in real time or if there
# is an urgent need to backup latest work

# To properly do multi-level backups, read the
# manual page for tar, the --listed-incremental flag.
# The naming needs to provide all the information
# to identify the level so that all the associated .tar
# files can be retrieved to restore the file system
# (though that is the responsibility of another script)

# Constrain LEVEL to described implementation
if [ $LEVEL -lt 0 ]
then
    echo "Negative level backups cannot be made. Exiting"
    exit 0
elif [ $LEVEL -gt 3 ]
then
    echo "This script does not have a rule for level > 3 backups. Exiting"
    exit 0
fi

# Get dates
YEAR=`date +%Y`
MONTH=`date +%m`
WEEK=`date +%U`
DAY=`date +%w`
DATE="$YEAR"."$MONTH"."$WEEK"."$DAY"

# Make patterns using the only POSIX shell array - the argument list
set -- \
"$PREFIX"-1."$YEAR"."$MONTH"."$WEEK".*.snar \
"$PREFIX"-2."$YEAR"."$MONTH".*.snar \
"$PREFIX"-3."$YEAR".*.snar

# Decide what is the lowest level needing backup
# Create a .snar when there is none that is up-to-date
# Choose an existing .snar when it is there

# Default level 0 behavior
BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"-0."$DATE".0.tar
# For higher levels find an appropriate snar
i=1
while [ $i -le $LEVEL ]
do
    PATTERN=`eval echo \$"$i"`
    if [ -z `ls "$BACKUP_DEST" | grep "$PATTERN"` ]
    then # No up-to-date .snar was found at this level
        if [ $i -eq $LEVEL ]
        then # create full backup
            BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"-"$i"."$DATE".0.tar
            BACKUP_SNAR="$BACKUP_DEST"/"$PREFIX"-"$i"."$DATE".snar
            break
        # else continue through loop
        fi
    else # Use available .snar
        BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"-$(($i - 1))."$DATE".0.tar
        BACKUP_SNAR="$BACKUP_DEST"/`ls "$BACKUP_DEST" | grep "$PATTERN" | tail -1`
        break
    fi

    i=$(($i + 1))
done

# Check if a backup for today already exists.
# Because when a .snar is created the same day
# as a .tar causes the level of BACKUP_ARXV
# to decrease by 1, this case must be addressed
# by checking if there is a .tar from today with
# the same level as the identified .snar
if [ -f "$BACKUP_DEST"/`ls "$BACKUP_DEST" | grep "$DATE".*.tar | tail -1` ]
then
    if [ ! "$SAVE" = "-y" ]
    then
        echo "A backup from today already exists. Save changes to archive? [y/N]"
        read BOOL
        if [ ! "$BOOL" = "y" ]
        then
            echo Exiting
            exit 0
        fi
    fi

    if [ $LEVEL -gt 0 ]
        then # Increase increment counter
            while [ -f "$BACKUP_ARXV" ]
            do
                i=`echo "$BACKUP_ARXV" | sed -E 's/.+\.([0-9]+)\.tar/\1/'`
                BACKUP_ARXV=`echo "$BACKUP_ARXV" | sed -E "s/[0-9]+\.tar$/$(($i + 1)).tar/"`
            done
    fi
    echo Incrementing archive
fi

# Make today's backup
if [ "$BACKUP_SNAR" ]
then
    tar -c -P \
        -g "$BACKUP_SNAR" \
        -f "$BACKUP_ARXV" \
        -X "$BACKUP_IGNR" \
        -T "$BACKUP_FILE"
else # Level 0 behavior (every day a full backup)
    tar -c -P \
        -f "$BACKUP_ARXV" \
        -X "$BACKUP_IGNR" \
        -T "$BACKUP_FILE"
fi

# Make copies of lower-level backups
SNAR_LEVEL=`echo "$BACKUP_SNAR" | sed -E "s@$BACKUP_DEST/$PREFIX-([0-9]+)\.$DATE\.snar@\1@"`
while [ $SNAR_LEVEL -gt 1 ]
do
    SNAR_LEVEL=$(($SNAR_LEVEL - 1))
    cp "$BACKUP_SNAR" `echo "$BACKUP_SNAR" | sed -E "s/-([0-9]+)\./-$SNAR_LEVEL./"`
done

exit 0
