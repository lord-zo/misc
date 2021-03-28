#!/bin/sh

# backup_brains.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

# These are the brains of the backup script
# They are collected here so they can be tested

. ./backup_utils.sh

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

    local i pattern_i pattern_i_1 snars

    if [ ! -d "$2" ]
    then
        set -- "$1" "$BACKUP_DEST"
    fi

    # Figure out the archive which should be incremented at the given day
    i=0
    while [ $i -lt $LEVEL ]
    do
        i=$(($i + 1))
        pattern_i=`pattern_date_level "$1" "$i"`
        snars=`search_snar "$2" "$pattern_i" "$i"`
        if [ "$snars" ]
        then
            # an up-to-date .snar is available
            if [ $i -eq $LEVEL ]
            then
                # The highest level is reached, so use the .snar
                BACKUP_SNAR="$snars"
                # Create today's archive at this level one increment higher
                BACKUP_ARXV=$(raise_incr `search_arxv "$2" "$pattern_i" "$i" "[0-9]{2}" | tail -1`)
                BACKUP_ARXV="${PREFIX}.${1}.`file_li ${BACKUP_ARXV}`.tar"
            else
                # There may be a .snar at a higher level
                continue
            fi
        else
            # no up-to-date .snar is available so return a level
            if [ $i -eq 1 ]
            then
                # Create a full backup
                BACKUP_ARXV="${PREFIX}.${1}.0-00.tar"
                BACKUP_SNAR="${PREFIX}.${1}.1-00.snar"
            else
                # Select the existing lower-level snar
                pattern_i_1=`pattern_date_level "$1" $(($i - 1))`
                BACKUP_SNAR=`search_snar "$2" "$pattern_i_1" $(($i - 1))`
                # Create this archive on lower level one increment higher
                BACKUP_ARXV=$(raise_incr `search_arxv "$2" "$pattern_i_1" $(($i - 1)) "[0-9]{2}" | tail -1`)
                BACKUP_ARXV="${PREFIX}.${1}.`file_li ${BACKUP_ARXV}`.tar"
                if [ `echo "$BACKUP_SNAR" | wc -w` -ne 1 ]
                then
                    # Multiple snars found
                    echo "Error: Multiple snars found ${BACKUP_SNAR}" 1>&2
                    return 1
                fi
            fi
            break
        fi
    done
}

draw_arxv () {
    # Print a graphical representation of the archive structure to console
    # $1 is an optional directory (default: $BACKUP_DEST)
    # $2 is an optional file whose lines are archive files to be emphasized
    local date l0 l1 l2 l3 incr tars snars i j tars_hl snars_hl mark

    if [ ! -d "$1" ]
    then
        set "$BACKUP_DEST"
    fi

    # Print column headers
    echo "| YYYY_MM_WW_D | 0 1 2 3 | II |" 1>&2
    echo "| ----date---- | -level- | -- |" 1>&2

    # Find all archive files with a unique date
    for i in `ls "$1" | filter_archive | filter_date | uniq`
    do
        # Print one line of information per day
        date="$i"
        l0=" "; l1=" "; l2=" "; l3=" ";
        # Count the total number of archives written that day
        incr=`search_tar "$1" "$i" "[0-9]" "[0-9]{2}" | wc -w`
        # Find all unique levels per date
        for j in `ls "$1" | grep "$i" | filter_level | uniq`
        do
            tars=`search_tar "$1" "$i" "$j" "[0-9]{2}"`
            snars=`search_snar "$1" "$i" "$j"`

            # Check out if things should be highlighted
            tars_hl=`search_tar "$2" "$i" "$j" "[0-9]{2}"`
            snars_hl=`search_snar "$2" "$i" "$j"`

            # figure out what exists at each level
            if [ "$tars_hl" -a "$snars_hl" ] || [ "$tars_hl" -a "$snars" ] || [ "$tars" -a "$snars_hl" ]
            then
                # Both metadata and archive present and at least one highlighted
                mark="B"
            elif [ "$tars_hl" ]
            then
                # Only higlighted archive present
                mark="X"
            elif [ "$snars_hl" ]
            then
                # Only highlighted metadata present
                mark="O"
            elif [ "$tars" -a "$snars" ]
            then
                # Both metadata and archive present
                mark="b"
            elif [ "$tars" ]
            then
                # Only archive present
                mark="x"
            elif [ "$snars" ]
            then
                # Only metadata present
                mark="o"
            else
                mark=" "
            fi
            eval `echo l${j}="${mark}"`
        done
        echo "| ${date} | ${l0} ${l1} ${l2} ${l3} | `printf '%02d' ${incr}` |" 1>&2
    done

    # Print column footers
    echo "| ----date---- | -level- | -- |" 1>&2
    echo "| YYYY_MM_WW_D | 0 1 2 3 | II |" 1>&2

    # Print Legend
    echo 1>&2
    echo "Legend:" 1>&2
    echo "date - format: %Y%m%U%w" 1>&2
    echo "x/X  - archive made" 1>&2
    echo "o/O  - snapshot made" 1>&2
    echo "b/B  - archive and snapshot made" 1>&2
    echo "II   - total increments per day" 1>&2

    if [ -f $2 ]
    then
        # Print info about emphasis
        echo 1>&2
        echo "Files in ${2}" 1>&2
        echo "are capitalized for emphasis" 1>&2
    fi
}

test_brains () {
    # test to see if the choices of archive work as expected
    # by giving 2 years worth of dates and creating dummy files in response

    local test_dir year month week day i arxv_level

    test_dir="testing"
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
                    touch `raise_snar "$BACKUP_SNAR" "$date"`
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
