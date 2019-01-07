#!/bin/bash

usage() {
	echo "$0:"
	echo "-h for help"
	echo "-f <hosts file>"
	exit 0
}

start_hosts() {
  if [ -z "$1" ]; then
    # set the hosts file to 'hosts' if the user doesn't specify it with -f 
    HOSTSFILE=hosts
  else
    HOSTSFILE=$1
  fi

  if [ ! -r "$HOSTSFILE" ]; then
  	echo "${HOSTSFILE} is missing."
  	exit 10
  fi
  
  # a safer, cleaner loop over the hosts file to read in lines, rather than words
  grep -E '^[^\[ ]' < "$HOSTSFILE" | while IFS= read -r i
  do 
  	virsh start "$i"
  	#sleep 5
  done

  echo "DEBUG: start_hosts end"
  exit 0
}

while getopts h?f: option
do
case "${option}"
in
h) usage
   exit 0;;
f) start_hosts "$OPTARG" ;;
?) echo "unexpected flag: '${OPTARG}'"
   exit;;
esac
done

start_hosts

