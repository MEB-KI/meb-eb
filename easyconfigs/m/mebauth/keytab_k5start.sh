#!/bin/bash

set -eu

# refresh/create keytab file in ~/.kt by asking for password, then run k5start
# to get a kerberos ticket and keep it alive

KEYTAB="$HOME/.kt"

# if running interactively, restore echo if interrupted while entering password
trap "tty -s && stty echo" EXIT
# if interrupted with Ctrl-C (typically when asked to enter password), exit
# instead of trying again
trap "exit 1" INT

get_ticket() {
	kinit $USER@MEB.KI.SE -k -t "$KEYTAB" 2>/dev/null
}

create_keytab() {
	{
		echo "addent -password -p $USER@MEB.KI.SE -k 1 -e aes256-cts -s \"MEB.KI.SE$USER\""
    	systemd-ask-password --emoji=no --echo=no "Password for $USER@MEB.KI.SE:"
    	echo "wkt \"$KEYTAB\""
    	echo "q"
	} | ktutil >/dev/null
}

# Try to not run more than one k5start in the same session by saving the PID in
# /tmp (which is unique for each slurm job), and checking if it is still
# running.
K5S_PID="/tmp/k5start.$UID.pid"
if [ -f "$K5S_PID" ] && kill -0 $(cat "$K5S_PID") 2>/dev/null; then
	echo "Already authenticated - k5start running with PID $(cat "$K5S_PID")." >&2
	exit
fi

# check for existing keytab - if it exists and is valid, we are done,
# otherwise remove it and make a new one
if [ -f "$KEYTAB" ]; then
	if get_ticket; then
		echo "Valid keytab exists in $KEYTAB. Using for authentication." >&2
	else
		echo "Keytab exists in $KEYTAB, but is invalid or password expired. Deleting." >&2
		rm -f "$KEYTAB"
	fi
fi

# after possibly removing invalid keytab above
if [ ! -f "$KEYTAB" ]; then
	# generate new keytab, prompting for password - but stop with error if this
	# is not an interactive session (as password cannot be entered)
	if ! tty -s; then
		echo "No keytab found, and not running interactively. Cannot create keytab." >&2
		echo "Please run 'module load mebauth' in an interactive session at least once per" >&2
		echo "password change cycle." >&2
		exit 1
	else
		echo "Creating new keytab in $KEYTAB." >&2
		create_keytab
		# try again up to two times if the password was wrong
		for i in {1..2}; do
			if get_ticket; then
				break
			else
				echo "Password incorrect. Please try again." >&2
				create_keytab
			fi
		done
		# if we didn't get a good ticket, give up and don't run k5start
		if ! klist -s; then
			echo "Could not get a ticket using keytab in $KEYTAB - giving up." >&2
			exit 1
		fi
	fi
fi

# At this point, we should have a valid keytab - run k5start (but exit on any error)

k5start -U -f "$KEYTAB" -K 10 -x -p "$K5S_PID" -b