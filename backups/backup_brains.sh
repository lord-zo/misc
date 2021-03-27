#!/bin/sh

# backup_brains.sh
# By: Lorenzo Van Munoz
# On: 27/03/2021

# These are the brains of the backup script
# They are collected here so they can be tested

. ./backup_conf.sh
. ./backup_read_conf.sh
. ./backup_history_utils.sh

N=3
# Constrain LEVEL to actual implementation
if [ $LEVEL -lt 0 ]
then
    echo "Negative level backups cannot be made. Exiting"
    exit 0
elif [ $LEVEL -gt $N ]
then
    echo "This script does not have a rule for level > 3 backups. Exiting"
    exit 0
fi

choose_incr_backup () {
    # $1 should be a date of the form `date +%Y_%m_%U_%w` or 'YYYY_MM_WW_D'
    # $2 is an optional directory (default $BACKUP_DEST)
    # Modifies global variables $BACKUP_ARXV, $BACKUP_SNAR as output

    local i p1 p2 p3 snar_pattern llvl_pattern prev_pattern

    if [ ! -d "$2" ]
    then
        set -- "$1" "$BACKUP_DEST"
    fi

    # backup frequency patterns
    p1="${PREFIX}.${1%_*_*_*}"
    p2="${PREFIX}.${1%_*_*}"
    p3="${PREFIX}.${1%_*}"

    # Figure out the oldest thing to back up starting from lowest level of archive
    i=0
    while [ $i -lt $LEVEL ]
    do # The offset of $i to $N - $LEVEL means correct pattern & frequency
        i=$(($i + 1)) # This means the current level of backup

        snar_pattern=`eval echo \$\p$((${i} + ${N} - ${LEVEL}))`"[_0-9.]*-${i}.snar"

        if [ `ls "$2" | grep "$snar_pattern"` ]
        then # an up-to-date .snar is available
            if [ $i -eq $LEVEL ]
            then # The highest level is reached, so use the .snar
                BACKUP_ARXV="${2}/${PREFIX}.${1}.0-${i}.tar"
                BACKUP_SNAR="${2}/`ls ${2} | grep ${snar_pattern} | tail -1`"
            else # There may be a .snar at a higher level
                continue
            fi
        else # no up-to-date .snar is available at this level, so go down
            if [ $i -eq 1 ]
            then # there is no valid full backup, so create one (cannot recover from this
                BACKUP_ARXV="${2}/${PREFIX}.${1}.0-0.tar"
                BACKUP_SNAR="${2}/${PREFIX}.${1}.0-1.snar"
            else # Increment the lower level since the timeframe for this level has past
                prev_pattern=`eval echo \$\p$((${i} - 1 + ${N} - ${LEVEL}))`"[_0-9.]*-$((${i} - 1))".snar
                BACKUP_ARXV="${2}/${PREFIX}.${1}.0-$((${i} - 1)).tar"
                BACKUP_SNAR="${2}/`ls ${2} | grep ${prev_pattern} | tail -1`"
            fi
            break
        fi
    done
}

raise_snar () {
    # Raise the snar a level
    # $1 should be a date
    echo $(change_date "$1" `raise_level "$BACKUP_SNAR"`)
}

draw_arxv () {
    # Optionally accepts a directory as $1
    local msg l0 l1 l2 l3 incr i j
    if [ ! -d "$1" ]
    then
        set "$BACKUP_DEST"
    fi
    echo "YYYY_MM_WW_D | 0 1 2 3 | I" 1>&2
    echo "----date---- | -level- | -" 1>&2
    for i in `ls "$1" | \
    grep -E "${PREFIX}\.[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]\.[0-9]*-[0-9]\.[snt]{1,2}ar" | \
    sed -E "s@(${PREFIX}\.[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]).*@\1@" | \
    uniq`
    do
        # Print one line per day
        # Get day
        msg=${i#$PREFIX\.}
        # Collect other variables to print
        l0=" "
        l1=" "
        l2=" "
        l3=" "
        incr=0
        for j in `ls "$1" | grep "$i" | sed -E "s@.+-([0-9]*)\.[snt]{1,2}ar@\1@" | uniq`
        do
            # figure out what exists at each level
            if `ls "$1" | grep -q -E "${i}\.[0-9]*-${j}\.tar"`
            then
                if `ls "$1" | grep -q -E "${i}\.[0-9]*-${j}\.snar"`
                then
                    # Both metadata and archive present
                    eval `echo l${j}="b"`
                else
                    # Only archive present
                    eval `echo l${j}="x"`
                fi
            elif `ls "$1" | grep -q -E "${i}\.[0-9]*-${j}\.snar"`
            then
                # Only metadata present
                eval `echo l${j}="o"`
            fi
            # Find the number of increments at this level
            incr=$(($incr + `ls "$1" | grep -E "${i}\.[0-9]*-${j}\.tar" | wc -l`))
        done
        msg="${msg} | ${l0} ${l1} ${l2} ${l3} | ${incr}"
        echo "$msg" 1>&2
    done
}

test_brains () {
    # test to see if the choices of archive work as expected
    # by giving 2 years worth of dates and creating dummy files in response

    local test_dir year month week day i arxv_level

    test_dir=testing
    if [ ! -d "$test_dir" ] && $(basename `pwd` | grep -q -v "$test_dir")
    then
        mkdir "$test_dir"
        echo "Performing test in $test_dir" 1>&2
        cd "$test_dir"
    elif [ -d "$test_dir" ]
    then
        cd "$test_dir"
    fi

    for year in `seq 2020 2021`
    do
        for week in `seq -w 0 53`
        do
            for i in `seq -w 0 11`
            do
                # approximate a month by 4.5 weeks
                if [ $((${week#0} * 2)) -ge $((${i#0} * 9)) -a $((${week#0} * 2)) -lt $(((${i#0} + 1) * 9)) ]
                then
                    month=`printf "%02d" $((${i#0} + 1))`
                    break
                fi
            done
            for day in `seq 0 6`
            do
                date="${year}_${month}_${week}_${day}"
                choose_incr_backup "$date" "."
                touch "$BACKUP_ARXV" "$BACKUP_SNAR"
                arxv_level=`file_level "$BACKUP_ARXV"`
                if [ $arxv_level -ne $LEVEL -a $arxv_level -ne 0 ]
                then # Not at top or bottom
                    touch `raise_snar "$date"`
                fi
            done
        done
    done
    cd ..

    draw_arxv "$test_dir"

    echo "Remove $test_dir? [y/N]"
    read BOOL
    if [ "$BOOL" = "y" ]
    then
        rm -rf "${test_dir}"
    fi
}
