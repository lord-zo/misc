#!/bin/sh

# backup_history_utils.sh
# By: Lorenzo Van Munoz
# On: 27/03/2021

# The functions gather information about archive file names
# and allow one to walk along the graph to find dependencies


change_date () {
    # Change the date of an archive file
    # $1 should be a date in 'YYYY_MM_WW_D' format
    # $2 should be an archive filename
    echo `echo "$2" | sed -E "s@[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{1}@$1@"`
}

raise_level () {
    # Raise the level of an archive file
    # $1 should be an archive filename
    local level
    level=`file_level "$1"`
    echo `echo "$1" | sed -E "s@-$level\.@-$(($level + 1)).@"`
}

increment () {
    # Increases increment counter until the file name is new
    local f
    f=`basename "$1"`
    while [ -f "$f" ]
    do
        i=`echo "$f" | sed -E 's/.+([0-9]+)-.+/\1/'`
        f=`echo "$f" | sed -E "s/[0-9]+-/$(($i + 1))-/"`
    done
    echo `dirname "$1"`/"$f"
}

file_level () {
    local level
    level=${1#*-}
    level=${level%%\.[snt]*ar}
    echo $level
}

file_date () {
    local date
    date=${1#$PREFIX-[0-9]*.}
    date=${date%\.[snt]*ar}
    echo $date
}

file_year () {
    local year
    year=`file_date "$1"`
    year=`echo "$year" | cut -d. -f1`
    echo "$year"
}

file_month () {
    local month
    month=`file_date "$1"`
    month=`echo "$month" | cut -d. -f2`
    echo "$month"
}


file_week () {
    local week
    week=`file_date "$1"`
    week=`echo "$week" | cut -d. -f3`
    echo "$week"
}


file_day () {
    local day
    day=`file_date "$1"`
    day=`echo "$day" | cut -d. -f4`
    echo "$day"
}

file_increment () {
    local incr
    if `echo "$1" | grep -q .tar`
    then
        incr=`file_date "$1"`
        incr=`echo "$incr" | cut -d. -f5`
    else
        echo "Error: file extension does not end in .tar" 1>&2
        return 1
    fi
}

file_age () {
    # Returns the age of the file in days compared to today
    local year month week day YEAR MONTH WEEK DAY age
    YEAR=`date +%Y`
    MONTH=`date +%m`
    WEEK=`date +%U`
    DAY=`date +%w`
    year=`file_year "$1"`
    month=`file_month "$1"`
    week=`file_week "$1"`
    day=`file_day "$1"`
    age=$((
        ${DAY##0} - ${day##0}
        + 7 * (${WEEK##0} - ${week##0})
        + 30 * (${MONTH##0} - ${month##0})
        + 365 * (${YEAR##0} - ${year##0})
        ))
    echo "$age"
}

file_age_cmp () {
    # Returns the age difference between $1 and $2
    echo $((`file_age "$1"` - `file_age "$2"`))
}

file_old () {
    # Returns 0 if the file is older than $DAYS, else 1
    [ `file_age "$1"` -gt $DAYS ]
}

file_old_cmp () {
    # Returns 1 if file $1 is older than $2
    [ "$1" = $(echo -e `file_date "$1"`'\n'`file_date "$2"` | sort | head -1) ]
}

find_next_tar () {
    # Return the filename of the corresponding snar file or next tar increment
    # if there is a snar file from the same day, pass this
    if $(ls "$BACKUP_DEST" | grep -q ${1%[0-9]*.tar}.snar)
    then
        echo $(ls "$BACKUP_DEST" | grep -q ${1%[0-9]*.tar}.snar | head -1)
        return 0
    elif [ `file_level` -eq 0 ]
    then # look for the next day of backups
        return
    else
        echo Error: could not find the next most recent dependency 1>&2
        exit 1
    fi
}

find_next_snar () {
    # Return the filename of the next dependent tar file or copied snar file
    return
}

find_prev_tar () {
    # Return the filename of the corresponding snar file or next tar increment
    return
}

find_prev_snar () {
    # Return the filename of the next file in the dependency tree
    return
}

independent () {
    # Returns 0 if the file is not a dependency, else 1
    local test
    if file_old "$1"
    then
        # need to decide if the given file is needed to recover a file that is not old
        test="$1"
        while file_old "$test"
        do
            # propose a newer file dependent on this one
            # if it's a .snar look for the next level lower .snar else 1st dependent .tar
            # if it's a .tar

            if `echo "$1" | grep -q .tar`
            then
                if [ file_day "$test" = "06" ]
                then
                    return 0
                else
                    test=`find_next_tar "$test"`
                fi
            elif `echo "$1" | grep -q .snar`
            then
                test=`find_next_snar "$test"`
            fi
            break
        done
    else
        return 1
    fi
}
