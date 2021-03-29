#!/bin/sh

# backup_graphs.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

# WARNING: do not run this in bash because echo works differently

. ./backup_utils.sh

# Functions to help navigate the dependency graph

find_next_incr () {
    # Return an archive file on the same level with the next increment
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file
    # $3 should be an integer number of increments to jump (e.g. 1, -1)

    local dir="$1" arxv_file="$2" jump="$3"
    local incr=`file_incr "$arxv_file"`
    local date=`file_date "$arxv_file"`
    local level=`file_level "$arxv_file"`
    local pattern=`pattern_date_level "$date" "$level"`
    local test=$(search_arxv "$dir" "$pattern" "$level" $(($incr + $jump)))
    if [ "$test" ]
    then
        # Found files on the same level branch with next increment
        return_uniq_result "$test" "Couldn't find unique increment ${jump} for ${arxv_file}"
    else
        # Specified increment found, end of branch on this level
        echo "$arxv_file"
    fi
}

find_next_level () {
    # Return an archive file on the same day as input archive
    # If .snar looks down a level, if .tar, looks up a level
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file

    local dir="$1" arxv_file="$2"
    local ext=`file_ext "$arxv_file"`
    local date=`file_date "$arxv_file"`
    local level=`file_level "$arxv_file"`
    if [ "$ext" = "tar" ]
    then
        # Look up a level for a same-day .snar one level higher
        local test=$(search_snar "$dir" "$date" $(($level + 1)))
        if [ "$test" ]
        then
            # Found a higher level .snar
            return_uniq_result "$test" "Couldn't find unique next level for ${arxv_file}"
        else
            # Reached highest level
            echo "$arxv_file"
        fi
    elif [ "$ext" = "snar" ]
    then
        # Look down for a same-day, lower-level tar
        local test=$(search_tar "$dir" "$date" $(($level - 1)) "[0-9]" | tail -1)
        if [ "$test" ]
        then
            # Found a lower level .tar
            return_uniq_result "$test" "Couldn't find unique next level for ${arxv_file}"
        else
            # Reached highest level
            echo "Error: snapshot ${arxv_file} has no same-day source tar" 1>&2
            return 1
        fi
    else
        echo "Error: ${arxv_file} is not an archive file" 1>&2
        return 1
    fi
}

find_next_arxv () {
    # Return an archive file guaranteed to move along the most recent branch
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file

    local dir="$1" arxv_file="$2"
    test_level=`find_next_level "$dir" "$arxv_file"`
    test_incr=`find_next_incr "$dir" "$arxv_file" "1"`
    echo "${test_level}\n${test_incr}" | sort | tail -1
}

find_prev_arxv () {
    # Return an archive file guaranteed to move back down the branch
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file

    local dir="$1" arxv_file="$2"
    test_level=`find_next_level "$dir" "$arxv_file"`
    test_incr=`find_next_incr "$dir" "$arxv_file" "-1"`
    echo "${test_level}\n${test_incr}" | sort | head -1
}

find_recovery_arxv () {
    # Returns all the archives needed to restore the input states
    # $1 should be a directory
    # $2 should be a .tar archive file

    local dir="$1" test="$2" prev
    while [ "$test" != "$prev" ]
    do
        if [ `file_ext "$test"` = "tar" ]
        then
            echo "$test"
        fi
        prev="$test"
        test=`find_prev_arxv "$dir" "$prev"`
    done
}

find_old_arxv () {
    # Returns all the archives not needed to recover files created after date
    # $1 should be a directory
    # $2 should be a date in %Y_%m_%U_%w format

    local dir="$1" date="$2" tmp_file="backup_graphs.tmp" arxv
    > "$tmp_file"
    for arxv in `ls "$dir" | filter_archive | grep -A 10000 "${date}.*tar$" | tac`
    do
        # find all dependencies of this file
        if `cat "$tmp_file" | grep -q -v "$arxv"`
        then
            # if file is not already included, find dependencies
            find_recovery_arxv "$dir" "$arxv" >> "$tmp_file"
        fi
    done
    cat "$tmp_file" | uniq | sort > "$tmp_file"
    ls "$dir" | filter_archive | grep -v -f "$tmp_file"
#    rm "$tmp_file"
}
