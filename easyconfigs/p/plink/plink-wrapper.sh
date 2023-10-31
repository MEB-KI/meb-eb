#!/bin/bash

set -eu

# A wrapper script to limit the memory and thread usage of plink 1.90
# by default (can be overridden by specifying --memory and --threads)
#
# Robert Karlsson <robert.karlsson@ki.se>
# 2019-12-04 - call plink in the same path as this script instead of hardcoded
# 2016-11-22 - first version

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLINK=$SCRIPTDIR/plink.bin

default_args=( "--memory" "--threads" )
default_values=( "8000" "8" )

# do not substitute arguments if running the --help command
# or running with no options
if [[ "$#" -gt 0 && ! "$*" =~ "--help" ]]; then
    for (( i=0; i < ${#default_args[@]}; i++ )); do
        if [[ ! "$*" =~ "${default_args[i]}" ]]; then
            set -- "$@" "${default_args[i]}" "${default_values[i]}"
        fi
    done
fi

"$PLINK" "$@"
