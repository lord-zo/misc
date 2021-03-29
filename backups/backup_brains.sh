#!/bin/sh

# backup_brains.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

# These are the brains of the backup script
# They are collected here so they can be tested

. ./backup_utils.sh

change_level () {
    # $1 should be an archive filename without dirname
    # $2 should be a single digit level
    echo "$1" | sed -E "s@.[0-9]-@.${2}-@"
}

change_incr () {
    # $1 should be an archive filename without dirname
    # $2 should be a single digit increment
    echo "$1" | sed -E "s@-[0-9]\.@-${2}.@"
}

change_date () {
    # $1 should be an archive filename without dirname
    # $2 should be a date in 'YYYY_Q_MM_WW_D' format
    echo "$1" | sed -E "s@[0-9]{4}_[0-9]_[0-9]{2}_[0-9]{2}_[0-9]@${2}@"
}

raise_level () {
    # Raise the level of an archive file by 1
    # $1 should be an archive filename without dirname
    local level=$((`file_level "$1"` + 1))
    if [ $level -gt 9 -o $level -lt 0 ]
    then
        echo "Error: cannot increase level of ${1}" 1>&2
        return 1
    else
        change_level "$1" "$level"
    fi
}

raise_incr () {
    # Raise the increment counter by 1
    # $1 should be an archive filename without dirname
    local incr=`file_incr "$1"`
    incr=$((${incr#0} + 1))
    if [ $incr -gt 9 -o $incr -lt 0 ]
    then
        echo "Error: cannot increase increment of ${1}" 1>&2
        return 1
    else
        change_incr "$1" "$incr"
    fi
}

raise_snar () {
    # Raise the archive (.snar) a level and update date
    # $1 should be an archive filename without dirname
    # $2 should be a date
    raise_level `change_date "$1" "$2"`
}

raise_tar () {
    # Raise the archive (.tar) an increment and update date
    # $1 should be an archive filename without dirname
    # $2 should be a date
    raise_incr `change_date "$1" "$2"`
}

name_incr_backup () {
    # Names backup files with appropriate levels and increments
    # $1 should be a directory to search
    # $2 should be a date
    # $3 should be a digit level (implemented 0-3)
    # Modifies global variables $BACKUP_ARXV, $BACKUP_SNAR as output

    local dir="$1" date="$2" level="$3"
    local pattern=`pattern_date_level "$date" "$level"`
    # Use up-to-date snar on level if it is unique (more means a bug)
    BACKUP_SNAR=`search_snar "$dir" "$pattern" "$level"`
    BACKUP_SNAR=`return_uniq_result "$BACKUP_SNAR" "Multiple .snars found"`
    # Create today's archive at this level one increment higher
    BACKUP_ARXV=`search_arxv "$dir" "$pattern" "$level" "[0-9]" | tail -1`
    BACKUP_ARXV=`raise_tar "$BACKUP_ARXV" "$date" | sed -E 's@snar\$@tar@'`
}

choose_backup () {
    # $1 is the archive directory
    # $2 should be a date of the form `date +%V_%q_%m_%V_%u`
    # Modifies global variables $BACKUP_ARXV, $BACKUP_SNAR as output

    local dir="$1" date="$2" i pattern_i pattern_i_1
    # Default level 0 filenames
    BACKUP_ARXV="${PREFIX}.${date}.0-0.tar"
    BACKUP_SNAR=/dev/null
    # Figure out the level at which to increment the archive
    i=1
    while [ $i -le $LEVEL ]
    do
        pattern_i=`pattern_date_level "$date" "$i"`
        pattern_i_1=`pattern_date_level "$date" $(($i - 1))`
        if [ `search_snar "$dir" "$pattern_i" "$i"` ]
        then
            # an up-to-date .snar is available at this level
            if [ $i -eq $LEVEL ]
            then
                # At highest level, use the snar
                name_incr_backup "$dir" "$date" "$i"
                break
            else
                # There may be a .snar at a higher level
                i=$(($i + 1))
                continue
            fi
        elif [ `search_snar "$dir" "$pattern_i_1" $(($i - 1))` ]
        then
            # Select the existing lower-level snar
            name_incr_backup "$dir" "$date" $(($i - 1))
            break
        else
            # Base case: there are no snars so prepare one for full backup
            BACKUP_SNAR="${PREFIX}.${date}.1-0.snar"
            break
        fi
    done
}

test_brains () {
    # test to see if the choices of archive work as expected
    # by giving 2 years worth of dates and creating dummy files in response

    local test_dir="testing" year quarter month week day i arxv_level REPLY

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
        for week in `seq -w 1 53`
        do
            # shorten a quarter to 12 weeks and a month to 4 weeks
            quarter=$((((${week#0} - 1) / 12) + 1))
            month=`printf '%02d' $((((${week#0} - 1) / 4) + 1))`
            for day in `seq 1 7`
            do
                date="${year}_${quarter}_${month}_${week}_${day}"
                choose_backup "." "$date"
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

    read -p "Remove $test_dir? [y/N] " REPLY
    if [ "$REPLY" = "y" ]
    then
        rm -rf "${test_dir}"
    fi
}
