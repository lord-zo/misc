#!/bin/sh

# backup_utils.sh
# By: Lorenzo Van Munoz
# On: 29/03/2021

# The functions gather information about archive file names
# (which have a $PREFIX.YYYY_Q_MM_WW_D.L-I.\(snar\)\|\(tar\) format)
# and allow one to walk along the graph to find dependencies
# Prefix must not have any periods

. ./backup_conf.sh
. ./backup_read_conf.sh

# This global variable specifies the actual number of implemented levels
# If you increase this, you'll also have to implement the additional levels
# You'll also have realized that the frequency of levels is specified by
# the date, so you'll have to change any date patterns in this library
N=4
# Constrain LEVEL to actual implementation
if [ $LEVEL -lt 0 ]
then
    echo "Negative level backups cannot be made. Exiting"
    exit 0
elif [ $LEVEL -gt $N ]
then
    echo "This script does not have a rule for level > ${N} backups. Exiting"
    exit 0
fi

DATE_PATTERN="[0-9]{4}_[0-9]_[0-9]{2}_[0-9]{2}_[0-9]"
alias filter_archive="grep -E '${PREFIX}\.${DATE_PATTERN}\.[0-9]-[0-9]\.(tar|snar)\$'"
alias filter_date="sed -E 's@${PREFIX}\.(${DATE_PATTERN})\..*\.(tar|snar)\$@\1@'"
alias filter_level="sed -E 's@.+\.([0-9])-[0-9]\.(tar|snar)\$@\1@'"
alias filter_incr="sed -E 's@.+\.[0-9]-([0-9])\.(tar|snar)\$@\1@'"

set_DATE () {
    # This function gets today's date in the usual format for these archives
    # Get date with ISO year and week
    # Format `date +%G_%q_%m_%V_%u`
    # For efficiency, shorten a month to exactly 4 weeks
    # and a quarter to exactly 3 months

    local year=`date +%G` week=`date +%V` day=`date +%u`
    local quarter=`printf '%02d' $((((${week#0} - 1) / 12) + 1))`
    local month=`printf '%02d' $((((${week#0} - 1) / 4) + 1))`
    echo "${year}_${quarter}_${month}_${week}_${day}"
}

pattern_date_level () {
    # Returns a pattern to use to filter up-to-date files of the same level
    # $1 should be a date in %G_%q_%m_%V_%u format
    # $2 should be a digit level (implemented 0-$N)
    local date="$1" level="$2"
    if [ ! $level -ge 0 -a $level -le $LEVEL ]
    then
        echo "Error: selected level ${level} not implemented" 1>&2
        return 1
    fi

    if [ $level -eq 0 ]
    then
        # Daily backup pattern
        echo "${PREFIX}\.${date}"
        # Note this case is for redundancy
    elif [ $level -eq $LEVEL ]
    then
        # Weekly full backup pattern
        echo "${PREFIX}\.${date%_*}"
    elif [ $level -eq $(($LEVEL - 1)) ]
    then
        # Monthly full backup pattern
        echo "${PREFIX}\.${date%_*_*}"
    elif [ $level -eq $(($LEVEL - 2)) ]
    then
        # Quarterly full backup pattern
        echo "${PREFIX}\.${date%_*_*_*}"
    elif [ $level -eq $(($LEVEL - 3)) ]
    then
        # Yearly full backup pattern
        echo "${PREFIX}\.${date%_*_*_*_*}"
    else
        echo "Error: selected level ${level} not implemented" 1>&2
        return 1
    fi
}

file_prefix () {
    # $1 should be an archive filename without dirname
    echo ${1%%.*}
}

file_ext () {
    # $1 should be an archive filename without dirname
    echo ${1##*.}
}

file_id () {
    # $1 should be an archive filename without dirname
    local id=${1#*.}
    echo ${id%.*}
}

file_li () {
    # $1 should be an archive filename without dirname
    local li=`file_id "$1"`
    echo ${li#*.}
}

file_level () {
    # $1 should be an archive filename without dirname
    local level=`file_li "$1"`
    echo ${level%-?}
}

file_incr () {
    # $1 should be an archive filename without dirname
    local incr=`file_li "$1"`
    echo ${incr#?-}
}

file_date () {
    # $1 should be an archive filename without dirname
    local date=`file_id "$1"`
    echo ${date%.*}
}

file_year () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f1
}

file_quarter () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f2
}

file_month () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f3
}

file_week () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f4
}

file_day () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f5
}

file_age () {
    # Returns the age of the file in days compared to today
    # $1 should be an archive filename without dirname
    local year month week day YEAR MONTH WEEK DAY age
    YEAR=`date +%G`
    WEEK=`date +%V`
    DAY=`date +%u`
    year=`file_year "$1"`
    week=`file_week "$1"`
    day=`file_day "$1"`
    age=$((
        ${DAY##0} - ${day##0}
        + 7 * (${WEEK##0} - ${week##0})
        + 365 * (${YEAR##0} - ${year##0})
        # In reality, an ISO year is 364 or 371 days
        ))
    echo "$age"
}

search_arxv () {
    # Search for tar or snar files by pattern and level and increment
    # $1 should be a directory or file
    # $2 should be a ERE pattern (to match part of a date)
    # $3 should be a digit level or ERE
    # $4 should be a 2-digit increment or ERE
    if [ -f "$1" ]
    then
        cat "$1" | grep -E "${2}[._0-9]*\.${3}-${4}\.(tar|snar)$"
    elif [ -d "$1" ]
    then
        ls "$1" | grep -E "${2}[._0-9]*\.${3}-${4}\.(tar|snar)$"
    fi
}

search_tar () {
    # Search for tar files by pattern and level and increment
    # $1 should be a directory or file
    # $2 should be a ERE pattern (to match part of a date)
    # $3 should be a digit level or ERE
    # $4 should be a 2-digit increment or ERE
    search_arxv "$1" "$2" "$3" "$4" | grep "tar$"
}

search_snar () {
    # Search for snar files by pattern and level
    # $1 should be a directory or file
    # $2 should be a ERE pattern
    # $3 should be a digit level or ERE
    search_arxv "$1" "$2" "$3" "[0-9]" | grep "snar$"
}

return_uniq_result () {
    # Returns the result of a search if it is unique, otherwise error
    # $1 should be a search result
    # $2 is an optional error message
    if [ $(echo "$1" | wc -w) -eq 1 ]
    then
        # Return the unique file
        echo "$1"
    else
        # Found multiple files with the same increment
        echo "Error: ${2}" 1>&2
        echo "Error: Search yielded: ${1}" 1>&2
        return 1
    fi
}

confirmation () {
    # Interactively ask before action-ing
    # $1 should be an action verb (e.g. removing) to display in prompts
    # $2 should be the directory containing those actual files
    # $3 should be a file with archive filenames to review

    local action="$1" arxv_dir="$2" arxv_files="$3" REPLY
    read -p "review archive files before ${action}? [y/N] " REPLY
    if [ "${REPLY=N}" = "y" ]
    then
        while true
        do
            read -p "view filenames [y] or archive graph [g]? [y/g/N] " REPLY
            if [ "${REPLY=N}" = "y" ]
            then
                less "$arxv_files"
            elif [ "${REPLY=N}" = "g" ]
            then
                draw_arxv "$arxv_dir" "$arxv_files" | less
            else
                break
            fi
            tput cuu1
            tput el
        done
    fi

    read -p "proceed ${action} archive? [y/N] " REPLY
    if [ "${REPLY=N}" = "y" ]
    then
        echo "${action} archive"
    else
        echo "no action, exiting"
        exit 0
    fi
}

draw_arxv () {
    # Print a graphical representation of the archive structure to console
    # $1 is an optional directory (default: $BACKUP_DEST)
    # $2 is an optional file whose lines are archive files to be emphasized

    local dir="$1" file_hl="$2"
    local arxvs_date arxvs tars snars
    local arxvs_date_hl arxvs_hl tars_hl snars_hl
    local date level marks mark incr

    if [ ! -d "$dir" ]
    then
        dir="$BACKUP_DEST"
    fi

    # Print column headers
    echo "| YYYY_Q_MM_WW_D | 0 1 2 3 4 | I |"
    echo "| -----date----- | --level-- | - |"

    # Find all archive files with a unique date
    for date in `ls "$dir" | filter_archive | filter_date | uniq`
    do
        # Print one line of information per day
        marks=""
        # Find all archives from that day
        arxvs_date=`search_arxv "$dir" "$date" "[0-9]" "[0-9]"`
        if [ -f "$file_hl" ]
        then
            arxvs_date_hl=`search_arxv "$file_hl" "$date" "[0-9]" "[0-9]"`
        fi
        # Count the total number of archives written that day
        incr=`echo "$arxvs_date" | grep tar$ | wc -w`
        # Find all unique levels per date (from 0 to 4)
        for level in `seq 0 $N`
        do
            # filter the current level
            arxvs=`echo "$arxvs_date" | grep "\.${level}-[0-9]\.\(tar\|snar\)$"`

            if [ ! "$arxvs" ]
            then
                mark=" "
            elif [ -f "$file_hl" ]
            then
                arxvs_hl=`echo "$arxvs_date_hl" | grep "\.${level}-[0-9]\.\(tar\|snar\)$"`
                # figure out what exists at each level
                tars=`echo "$arxvs" | grep tar$`
                snars=`echo "$arxvs" | grep snar$`
                # Check out if things should be highlighted
                tars_hl=`echo "$arxvs_hl" | grep tar$`
                snars_hl=`echo "$arxvs_hl" | grep snar$`
                if [ "$tars_hl" -a ! "$snars" ]
                then
                    # Only higlighted archive present
                    mark="X"
                elif [ "$snars_hl" -a ! "$tars" ]
                then
                    # Only highlighted metadata present
                    mark="O"
                elif [ "$tars_hl" -a "$snars_hl" ]
                then
                    # Both metadata and archive present and at least one highlighted
                    mark="B"
                elif [ "$tars" -a ! "$snars" ]
                then
                    # Only archive present
                    mark="x"
                elif [ "$snars" -a ! "$tars" ]
                then
                    # Only metadata present
                    mark="o"
                else
                    # Both metadata and archive present
                    mark="b"
                fi
            else
                # figure out what exists at each level
                tars=`echo "$arxvs" | grep tar$`
                snars=`echo "$arxvs" | grep snar$`
                if [ "$tars" -a ! "$snars" ]
                then
                    # Only archive present
                    mark="x"
                elif [ "$snars" -a ! "$tars" ]
                then
                    # Only metadata present
                    mark="o"
                else
                    # Both metadata and archive present
                    mark="b"
                fi
            fi
            marks="${marks} ${mark}"
        done
        echo "| ${date} |${marks} | ${incr} |"
    done

    # Print column footers
    echo "| YYYY_Q_MM_WW_D | 0 1 2 3 4 | I |"
    echo "| -----date----- | --level-- | - |"

    # Print Legend
    echo
    echo "Legend:"
    echo "x/X  - archive made"
    echo "o/O  - snapshot made"
    echo "b/B  - archive and snapshot made"
    echo "I    - total increments per day"
    echo "date - format: %G_%q_%m_%V_%u"

    if [ -f "$file_hl" ]
    then
        # Print info about emphasis
        echo
        echo "Files in ${file_hl}"
        echo "are capitalized for emphasis"
    fi
}
