#!/bin/bash

HOSTSFILE=hosts
if [ ! -r "$HOSTSFILE" ]; then
	echo "${HOSTSFILE} is missing."
	exit 10
fi

# a safer, cleaner loop over the hosts file to read in lines, rather than words
grep -E '^[^\[ ]' < $HOSTSFILE | while IFS= read -r i
do 
	virsh start "$i"
	#sleep 5
done
