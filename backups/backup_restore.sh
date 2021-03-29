#!/bin/sh

# backup_restore.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

USAGE="Usage: backup_restore.sh [-h] FILE

Description: Restore the state of the system to the specified backup

Options:
FILE    An archive file (.tar) in the backup
-h      Show this message and exit

Details:
This restores the backup by restoring in order from oldest to newest
the incremental backups created by tar. It is a matter of navigating
the dependency graph correctly and automatically. Note that the date
of the files in the backup are in a YYYY_Q_MM_WW_D format equivalent
to `date +%G_%q_%m_%V_%u` so finding the backup you want is not hard

Example:
$ ./backup_restore.sh archive.2021_5_14_53_7.4-5.tar
"

cd `dirname $0`
. ./backup_graphs.sh

if [ "$1" = "-h" ] || [ ! -f "${BACKUP_DEST}/${1}" -a `echo "$1" | filter_archive` ]
then
    echo "$USAGE"
    exit 0
fi

BACKUP_RLOG="./backup_recover.log"
touch "$BACKUP_RLOG"

echo $BACKUP_DEST `pwd` $1

find_recovery_arxv "$BACKUP_DEST" "$1" > "$BACKUP_RLOG"

confirmation "restoring" "$BACKUP_DEST" "$BACKUP_RLOG"

#cd "$BACKUP_DEST"
#cat "$BACKUP_RLOG" | tar -P -x -f - -g /dev/null
#cd -

exit 0
