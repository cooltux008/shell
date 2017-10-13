#!/bin/sh
set -x
[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" ||
for i in $(seq 10)
do
	echo $i
	sleep 1
done
