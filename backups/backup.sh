#!/bin/sh

# backup.sh
# By: Lorenzo Van Munoz
# On: 26/03/2021

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

# Configurable
. ./backup_conf.sh
. ./backup_read_conf.sh

# Import
. ./backup_history_utils.sh

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

# Constrain LEVEL to described implementation
N=3
if [ $LEVEL -lt 0 ]
then
    echo "Negative level backups cannot be made. Exiting"
    exit 0
elif [ $LEVEL -gt $N ]
then
    echo "This script does not have a rule for level > 3 backups. Exiting"
    exit 0
fi

# Get dates
YEAR=`date +%Y`
MONTH=`date +%m`
WEEK=`date +%U`
DAY=`date +%w`
DATE="$YEAR"_"$MONTH"_"$WEEK"_"$DAY"

if [ $LEVEL -eq 0 ]
then
    # choose name
    BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"."$DATE".0-0.tar

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
    # Make patterns using the only shell array - the argument list
    set -- \
    "$PREFIX"."$YEAR" \
    "$PREFIX"."$YEAR"_"$MONTH" \
    "$PREFIX"."$YEAR"_"$MONTH"_"$WEEK"

    # Figure out the oldest thing to back up starting from lowest level of archive
    i=0
    while [ $i -le $(($N - $LEVEL)) ]
    do # The offset of $i to $N - $LEVEL means correct pattern & frequency
        i=$(($i + 1)) # This means the current level of backup
        SNAR_PATTERN=`eval echo \$"$(($i + $N - $LEVEL))"`*.[0-9]*-"$i".snar
        if [ $i -gt 1 ]
        then
            LLVL_PATTERN=`eval echo \$"$(($i + $N - $LEVEL))"`*.[0-9]*-"$(($i - 1))".snar
            PREV_PATTERN=`eval echo \$"$(($i - 1 + $N - $LEVEL))"`*.[0-9]*-"$(($i - 1))".snar
        fi
        if [ `ls "$BACKUP_DEST" | grep "$SNAR_PATTERN"` ]
        then # an up-to-date .snar is available
            if [ $i -eq $LEVEL ]
            then # The highest level is reached, so use the .snar
                BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"."$DATE".0-$i.tar
                BACKUP_SNAR="$BACKUP_DEST"/`ls "$BACKUP_DEST" | grep "$SNAR_PATTERN" | tail -1`
            else # There may be a .snar at a higher level
                continue
            fi
        else # no up-to-date .snar is available at this level, so go down
            if [ $i -eq 1 ]
            then # there is no valid full backup, so create one (cannot recover from this
                BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"."$DATE".0-0.tar
                BACKUP_SNAR="$BACKUP_DEST"/"$PREFIX"."$DATE".0-1.snar
            elif [ `ls "$BACKUP_DEST" | grep "$LLVL_PATTERN"` ]
            then # move up a level because a lower level .snar is in
            # current level time window
            # This is also a layer of redundancy
                BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"."$DATE".0-$i.tar
                BACKUP_SNAR="$BACKUP_DEST"/"$PREFIX"."$DATE".0-$i.snar
                cp "$BACKUP_DEST"/`ls "$BACKUP_DEST" | grep "$LLVL_PATTERN" | tail -1` "$BACKUP_SNAR"
            else # Increment the lower level since the timeframe for this level has past
                BACKUP_ARXV="$BACKUP_DEST"/"$PREFIX"."$DATE".0-$(($i - 1)).tar
                BACKUP_SNAR="$BACKUP_DEST"/`ls "$BACKUP_DEST" | grep "$PREV_PATTERN" | tail -1`
            fi
            break
        fi
    done

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

    # If went up a level, but not at top or bottom, copy the metadata up a level
    SNAR_LEVEL=`file_level "$BACKUP_SNAR"`
    if [ $SNAR_LEVEL -ne $LEVEL -a $SNAR_LEVEL -ne 1 ]
    then # not at top or at bottom
        cp \
            "$BACKUP_SNAR" \
            ${BACKUP_SNAR%%[0-9]*.snar}$(($SNAR_LEVEL + 1)).snar
    fi
fi

exit 0
