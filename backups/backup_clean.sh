#!/bin/sh

# backup_clean.sh

# By: Lorenzo Van Munoz
# On: 29/03/2021

USAGE="Usage: backup_clean.sh [-h] FILE

Description: Deletes files in an incremental archive that are old

Options:
FILE    An archive filename or a date with YYYY_Q_MM_WW_D format
-h      Show this message and exit

Details:
This cleans up and saves space in a backup archive by deleting any
file older than the given date that isn't a dependency of a more
recent file

Examples:
$ ./backup_clean.sh archive.2021_1_02_05_7.4-5.tar
$ ./backup_clean.sh 2021_1_02_05_7
"
cd `dirname $0`
. ./backup_graphs.sh

if [ "$1" = "-h" -o ! "$1" ] || `echo "$1" | grep -q -v -E "${DATE_PATTERN}"`
then
    echo "$USAGE"
    exit 0
fi

# filter out just the date
set -- `echo "$1" | sed -E "s@.*(${DATE_PATTERN}).*@\1@"`

DATE=`set_DATE`
BACKUP_DLOG="backup_delete_${DATE}.log"

find_old_arxv "$BACKUP_DEST" "$1" > "$BACKUP_DLOG"

confirmation "cleaning" "$BACKUP_DEST" "$BACKUP_DLOG"

cat "$BACKUP_DLOG" | xargs -i rm "$BACKUP_DEST"/{}

exit 0
