#!/bin/bash

set -eu

# stop a running k5start created by this module (pid saved in K5S_PID)
K5S_PID="/tmp/k5start.$UID.pid"
[ -f "$K5S_PID" ] && kill $(cat "$K5S_PID") 2>/dev/null
