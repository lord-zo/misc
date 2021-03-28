#!/bin/bash

# backup_restore.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

USAGE="Usage: backup_restore.sh [-h] FILE

Description: Restores the state of the system to the specified backup

Options:
FILE    An archive file (.tar) in the backup
-h      Show this message and exit

Details:
This restores the backup by restoring in order from oldest to newest
the incremental backups created by tar. It is a matter of navigating
the dependency graph correctly and automatically. Note that the date
of the files in the backup are in a YYYY_MM_WW_D format equivalent
to `date +%Y%m%U%w` so finding the backup you want shouldn't be hard
"

. ./backup_graphs

if [ "$1" = "-h" ] || [ ! -f "$1" -a `echo "$1" | filter_archive` ]
then
    echo "$USAGE"
else

BACKUP_RCVR="./backup_recover.log"
touch "$BACKUP_RCVR"
find_recovery_arxv "$BACKUP_DEST" "$1" > "$BACKUP_RCVR"
cat "$BACKUP_RCVR" | tar -P -x -f - -g /dev/null

exit 0