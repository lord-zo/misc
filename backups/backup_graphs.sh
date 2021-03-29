#!/bin/sh

# backup_graphs.sh
# By: Lorenzo Van Munoz
# On: 28/03/2021

. ./backup_utils.sh

# Functions to help navigate the dependency graph

find_next_incr () {
    # Return an archive file on the same level with the next increment
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file
    # $3 should be an integer number of increments to jump (e.g. 1, -1)
    local incr=`file_incr "$2"`
    local date=`file_date "$2"`
    local level=`file_level "$2"`
    local pattern=`pattern_date_level "$date" "$level"`
    local test=$(search_tar "$1" "$pattern" "$level" $(($incr + $3)))
    if [ "$test" ]
    then
        # Found files on the same level branch with next increment
        return_uniq_result "$test" "Couldn't find unique increment ${3} for ${2}"
    else
        # Specified increment found, end of branch on this level
        echo "$2"
    fi
}

find_next_level () {
    # Return an archive file on the same day as input archive
    # If .snar looks down a level, if .tar, looks up a level
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file
    local ext=`file_ext "$2"`
    local date=`file_date "$2"`
    local level=`file_level "$2"`
    if [ "$ext" = "tar" ]
    then
        # Look up a level for a same-day .snar one level higher
        local test=$(search_snar "$1" "$date" $(($level + 1)))
        if [ "$test" ]
        then
            # Found a higher level .snar
            return_uniq_result "$test" "Couldn't find unique next level for ${2}"
        else
            # Reached highest level
            echo "$2"
        fi
    elif [ "$ext" = "snar" ]
    then
        # Look down for a same-day, lower-level tar
        local test=$(search_tar "$1" "$date" $(("$level" - 1)) | tail -1)
        if [ "$test" ]
        then
            # Found a lower level .tar
            return_uniq_result "$test" "Couldn't find unique next level for ${2}"
        else
            # Reached highest level
            echo "Error: snapshot ${2} has no same-day source tar" 1>&2
            return 1
        fi
    else
        echo "Error: ${2} is not an archive file" 1>&2
        return 1
    fi
}

find_next_arxv () {
    # Return an archive file guaranteed to move along the most recent branch
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file
    test_level=`find_next_level "$1" "$2"`
    test_incr=`find_next_incr "$1" "$2"`
    if [ "$test_level" != "$2" ]
    then
        # Move along level towards newest files
        echo "$test_level"
    elif [ "$test_incr" != "$2" ]
    then
        # Move up a level when cannot continue along that level
        echo "$test_incr"
    else
        # Reached end of branch
        echo "$2"
    fi
}

find_prev_arxv () {
    # Return an archive file guaranteed to move back down the branch
    # If no such file exists, returns the original file
    # $1 should be a directory
    # $2 should be a .tar or .snar archive file
    test_level=`find_next_level "$1" "$2"`
    test_incr=`find_next_incr "$1" "$2" "-1"`
    if [ "$test_incr" != "$2" ]
    then
        # Move along level towards older files
        echo "$test_level"
    elif [ "$test_level" != "$2" -a `file_ext "$2"` = "snar" ]
    then
        # Move down a level when cannot continue along that level
        echo "$test_level"
    else
        # Reached end / source of archive
        echo "$2"
    fi
}

find_recovery_arxv () {
    # Returns all the archives needed to restore the input states
    # $1 should be a directory
    # $2 should be a .tar archive file
    local test="$2" prev
    while [ "$test" != "$prev" ]
    do
        if [ `file_ext "$test"` = "tar" ]
        then
            echo "$test"
        fi
        prev="$test"
        test=`find_prev_arxv "$1" "$prev"`
    done
}

find_old_arxv () {
    # Returns all the archives not needed to recover files created after date
    # $1 should be a directory
    # $2 should be a date in %Y_%m_%U_%w format
    return
    # This should make a call to find_recovery_arxv and perform a grep -v
}
