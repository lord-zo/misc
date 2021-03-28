#!/bin/sh

# backup_history_utils.sh
# By: Lorenzo Van Munoz
# On: 27/03/2021

# The functions gather information about archive file names
# (which have a $PREFIX.YYYY_MM_WW_D.L-II.\(snar\)\|\(tar\) format)
# and allow one to walk along the graph to find dependencies
# Prefix must not have any periods

. ./backup_conf.sh
. ./backup_read_conf.sh

alias filter_archive="grep -E '${PREFIX}\.[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]\.[0-9]-[0-9]{2}\.(tar|snar)\$'"
alias filter_date="sed -E 's@${PREFIX}\.([0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]).*\.(tar|snar)\$@\1@'"
alias filter_level="sed -E 's@.+\.([0-9])-[0-9]{2}\.(tar|snar)\$@\1@'"
alias filter_incr="sed -E 's@.+\.[0-9]-([0-9]{2})\.(tar|snar)\$@\1@'"

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
    echo ${level%-??}
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

file_month () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f2
}

file_week () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f3
}

file_day () {
    # $1 should be an archive filename without dirname
    echo `file_date "$1"` | cut -d_ -f4
}

file_age () {
    # Returns the age of the file in days compared to today
    # $1 should be an archive filename without dirname
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

change_level () {
    # $1 should be an archive filename without dirname
    # $2 should be a single digit level
    echo "$1" | sed -E "s@.[0-9]-@.${2}-@"
}

change_incr () {
    # $1 should be an archive filename without dirname
    # $2 should be a two-digit increment
    echo "$1" | sed -E "s@-[0-9]{2}\.@-${2}.@"
}

change_date () {
    # $1 should be an archive filename without dirname
    # $2 should be a date in 'YYYY_MM_WW_D' format
    echo "$1" | sed -E "s@[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{1}@${2}@"
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
    if [ $incr -gt 99 -o $incr -lt 0 ]
    then
        echo "Error: cannot increase increment of ${1}" 1>&2
        return 1
    else
        change_incr "$1" `printf '%02d' "$incr"`
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
    search_arxv "$1" "$2" "$3" "[0-9]{2}" | grep "snar$"
}
