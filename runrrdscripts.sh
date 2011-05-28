#!/bin/sh
#
# Shell wrapper around runrrd.pl
# 2011 (c) by Tobias Diedrich <ranma+github@tdiedrich.de>
# Licensed under GNU GPL.
#

PATH=/usr/bin:/bin:/usr/sbin:/sbin
BASEDIR=`dirname $0`
LOCKFILE="/var/lock/runrrdscripts.lock"

renice -5 $$ >/dev/null

if dotlockfile -p -r 0 $LOCKFILE; then
	trap "dotlockfile -u $LOCKFILE" EXIT

	cd "$BASEDIR"

	# external load update (D'Oh)
	rrdtool update /root/rrd/load.rrd N:$( PROCS=`echo /proc/[0-9]*|wc -w|tr -d ' '`; read L1 L2 L3 DUMMY < /proc/loadavg ; echo ${L1}:${L2}:${L3}:${PROCS} )
	perl runrrd.pl >/dev/null
fi
