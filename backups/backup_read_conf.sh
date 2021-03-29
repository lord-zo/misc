# Create backup data files if not present
if [ -s "$BACKUP_DEST" ]
then
    BACKUP_DEST=`cat "$BACKUP_DEST" | grep -v -E ^# | head -1`
else
    if [ ! -f "$BACKUP_DEST" ]
    then
        touch "$BACKUP_DEST"
    fi
    echo "No backup path in $BACKUP_DEST. Exiting"
    echo "For help use the '-h' flag"
    exit 0
fi

if [ ! -f "$BACKUP_FILE" ]
then
    touch "$BACKUP_FILE"
fi

if [ ! -f "$BACKUP_IGNR" ]
then
    touch "$BACKUP_IGNR"
fi

if [ ! -s "$BACKUP_FILE" ]
then
    echo "$BACKUP_FILE is empty, so nothing to back up. Exiting"
    echo "For help use the '-h' flag"
    exit 0
fi
