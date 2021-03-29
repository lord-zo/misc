#!/bin/sh

# backup.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

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

. ./backup_brains.sh

cd "$BACKUP_DEST"

# Get date with ISO year and week
# Format `date +%G_%q_%m_%V_%u`
# For efficiency, shorten a month to exactly 4 weeks
# and a quarter to exactly 3 months
year=`date +%G`
week=`date +%V`
day=`date+%u`
quarter=`printf '%02d' $((((${week#0} - 1) / 12) + 1))`
month=`printf '%02d' $((((${week#0} - 1) / 4) + 1))`
DATE="${year}_${quarter}_${month}_${week}_${day}"

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
