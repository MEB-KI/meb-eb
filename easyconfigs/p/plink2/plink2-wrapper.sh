#!/bin/bash

set -eu

# A wrapper script to limit the memory and thread usage of plink 2.0
# by default (can be overridden by specifying --memory and --threads)
#
# Robert Karlsson <robert.karlsson@ki.se>
# 2023-10-31 - use AMD builds on AMD AVX2 CPUs
# 2019-02-04 - choose appropriate version by CPU capabilities
# 2018-09-18 - first version

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# choose binary depending on CPU capabilities
if grep -q avx2 /proc/cpuinfo && grep -q AuthenticAMD /proc/cpuinfo; then
    # AVX2 enabled AMD CPU
    PLINK2="$SCRIPTDIR/plink2.bin.amd"
elif grep -q avx2 /proc/cpuinfo; then
    # AVX2 enabled (Intel) CPU
    PLINK2="$SCRIPTDIR/plink2.bin"
else 
    # generic non-AVX2 CPU
    PLINK2="$SCRIPTDIR/plink2.bin.x86_64"
fi

default_args=( "--memory" "--threads" )
default_values=( "8000" "1" )

# do not substitute arguments if running the --help command
# or running with no options
if [[ "$#" -gt 0 && ! "$*" =~ "--help" ]]; then
    for (( i=0; i < ${#default_args[@]}; i++ )); do
        if [[ ! "$*" =~ "${default_args[i]}" ]]; then
            set -- "$@" "${default_args[i]}" "${default_values[i]}"
        fi
    done
fi

"$PLINK2" "$@"
