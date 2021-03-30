#!/bin/sh

# backup.sh
# By: Lorenzo Van Munoz
# On: 29/03/2021

USAGE="Usage: backup.sh [-h] [-t]

Description: Incremental backup script with tar

Options:
-t  test this script as if it made backups once a day for 2 years
-h  show this message and exit

Details:
When called without arguments, performs an incremental backup of
files in backup_files.conf, excluding patterns in backup_ignore.conf.
Specify the backup directory in a backup_destination.conf.
To configure the frequency/level of full backups, edit backup_conf.sh.

Examples:
$ echo LEVEL=3 >> ./backup_conf.sh
$ echo /some/files > ./backup_files.conf
$ echo /some/dir > ./backup_destination.conf
$ ./backup.sh
"
cd `dirname "$0"`
. ./backup_brains.sh

if [ "$1" = "-h" ]
then
    echo "$USAGE"
    exit 0
elif [ "$1" = "-t" ]
then
    test_brains
    exit 0
fi

cd "$BACKUP_DEST"

DATE=`set_DATE`

choose_backup "$BACKUP_DEST" "$DATE"

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
then
    # Not at top or bottom, so raise snar to next level
    cp \
        "$BACKUP_SNAR" \
        `raise_snar "$BACKUP_SNAR" "$DATE"`
fi

exit 0
