#!/bin/sh

# backup_clean.sh

# By: Lorenzo Van Munoz
# On: 28/03/2021

USAGE="Usage: backup_clean.sh [-h] [[OPTION NUMBER]]

Description: Deletes files in an incremental archive that are old

Options:
OPTION  one of y, q, m, w, d (years, quarters, months, weeks, days)
NUMBER  A positive integer (> 0)
-h      Show this message and exit

Details:
The script takes the requested duration and looks in the archive,
deleting all files older than the duration except those that are
needed to recover the state of the system.
A each day is a day, each week is 7 days, each month is 24 days,
each quarter is 72 days and each year is 365 days

Examples:
$ backup_clean.sh y 1 m 3 # deletes uneeded archives 455 days old
"

if [ "$1" = "-h" -o ! "$1" -o ! "$2" ]
then
    echo "$USAGE"
else
    i=1
    DAYS=0
    OPTION=`eval echo \$"$i"`
    LENGTH=`eval echo \$"$(($i + 1))"`
    while [ "$OPTION"`  -a "$LENGTH" ]
    do
        OPTION=`eval echo \$"$i"`
        LENGTH=`eval echo \$"$(($i + 1))"`
        if [ "$LENGTH" -ge 0 ]
            then
            if [ "$OPTION" = "d" ]
            then
                DAYS=$(($DAYS + $LENGTH))
            elif [ "$OPTION" = "w" ]
            then
                DAYS=$(($DAYS + 7 * $LENGTH))
            elif [ "$OPTION" = "m" ]
            then
                DAYS=$(($DAYS + 24 * $LENGTH))
            elif [ "$OPTION" = "q" ]
            then
                DAYS=$(($DAYS + 72 * $LENGTH))
            fi
            elif [ "$OPTION" = "y" ]
            then
                DAYS=$(($DAYS + 365 * $LENGTH))
            fi
        fi
        i=$(($i + 2))
    done
fi

. ./backup_graphs.sh

BACKUP_DLOG="./backup_delete.log"
touch "$BACKUP_DLOG"
find_old_arxv "$BACKUP_DEST" "$DAYS" > "$BACKUP_DLOG"

confirmation "cleaning" "$BACKUP_DEST" "$BACKUP_DLOG"

#cd "$BACKUP_DEST"
#cat "$BACKUP_DLOG" | xargs -i rm {}
#cd -

exit 0
