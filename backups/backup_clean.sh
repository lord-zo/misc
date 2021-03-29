#!/bin/sh

# backup_clean.sh

# By: Lorenzo Van Munoz
# On: 28/03/2021

USAGE="Usage: backup_clean.sh [-h] DATE

Description: Deletes files in an incremental archive that are old

Options:
DATE    A date with YYYY_Q_MM_WW_D format or archive filename
-h      Show this message and exit

Details:
This cleans up and saves space in a backup archive by deleting any
file older than the given date that isn't a dependency of a more
recent file

Examples:
$ ./backup_clean.sh 2021_5_14_53_7
$ ./backup_clean.sh archive.2021_5_14_53_7.4-5.tar
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

BACKUP_DLOG="./backup_delete.log"
touch "$BACKUP_DLOG"
find_old_arxv "$BACKUP_DEST" "$1" > "$BACKUP_DLOG"

confirmation "cleaning" "$BACKUP_DEST" "$BACKUP_DLOG"

#cd "$BACKUP_DEST"
#cat "$BACKUP_DLOG" | xargs -i rm {}
#cd -

exit 0
