#!/bin/sh

# backup_graphs.sh
# By: Lorenzo Van Munoz
# On: 27/03/2021

# Functions to help navigate the dependency graph

find_next_tar () {
    # Return an archive file guaranteed to move along the most recent branch
    # $1 should be a .tar archive file
    if [ `file_level` -eq 0 ]
    then
        # unless a same-day level 1 snar archive exists, stop here
        if $(ls | grep -q "${PREFIX}\.`file_date ${1}`\.0-1\.snar")
        then
            echo $(ls | grep "${PREFIX}\.`file_date ${1}`\.0-1\.snar" | tail -1)
            return 0
        else
            # STOP CONDITION
            return
        fi
    elif [ ! `file_level` -eq $LEVEL ]
    then
        if true
        then
            return
        fi
    else
        # This is the top level
        # Look for a tar archive at this level until the branch ends
        echo Error: could not find the next most recent dependency 1>&2
        exit 1
    fi
}

find_next_snar () {
    # Return an archive file guaranteed to move along the most recent branch
    # $1 should be a .snar archive file
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
                if [ `file_day "$test"` = "06" ]
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
