#!/bin/bash

set -eu

# A wrapper script to make sure Stata/MP is only run inside a Slurm job, and
# that a Stata/MP license has been reserved for the job (the number of
# concurrent users is limited).
#
# Robert Karlsson
#
# 2025-11-18

# get the binary name we are called as (should be one of stata-mp, xstata-mp)
BINNAME=$(basename "$0")
# Stata installation folder set by EasyBuild generated module file
STATAMPDIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")"

case "$BINNAME" in
	stata-mp|xstata-mp)
		# check that we are in a slurm job and that we have a license
		if [[ -z ${SLURM_JOBID+x} ]]; then
			echo "Stata/MP on tensor must be run within a Slurm job"
			echo "(with the flag \"-L statamp\" added to sbatch/salloc to reserve a license)"
			exit 1
		elif [[ -z ${SLURM_JOB_LICENSES+x} || ${SLURM_JOB_LICENSES} != *statamp* ]]; then
			# alternative: check return value of
			# squeue -h -j $SLURM_JOBID -o'%W'
			# (should be "statamp")
			echo "No statamp license reserved for this job!"
			echo "Please add the flag \"-L statamp\" to your sbatch or salloc command."
			exit 1
		else
			exec "$STATAMPDIR/$BINNAME" "$@"
		fi
		;;
	stata|stata-se|xstata|xstata-se)
		# don't run single core Stata (SE or BE) using the Statamp package
		echo "Please use the module \"Stata\" for the single-core version of Stata (BE)"
		exit 1
		;;
	*)
		# don't run this wrapper directly
		echo "This wrapper script should not be called directly!"
		echo "Run one of stata-mp, xstata-mp instead."
		exit 1
		;;
esac
