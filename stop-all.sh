#!/bin/bash

DESTROY=no

usage() {
        echo "Usage $0:"
        echo "-h for help"
        echo "-k to destroy instead of shutdown"
        echo "-f <hosts file>"
}

stop_hosts() {
  if [ -z "$HOSTSFILE" ]; then
    # set the hosts file to 'hosts' if the user doesn't specify it with -f
    HOSTSFILE=hosts
  fi

  if [ ! -r "$HOSTSFILE" ]; then
    echo "${HOSTSFILE} is missing."
    exit 10
  fi

  # a safer, cleaner loop over the hosts file to read in lines, rather than words
  grep -E '^[^\[ ]' < "$HOSTSFILE" | while IFS= read -r i
  do
    if [ "$DESTROY" == 'yes' ]; then
      virsh destroy  "$i"
    else
      virsh shutdown "$i"
    fi
  done

  exit 0
}

while getopts h?k?f: option
do
case "${option}"
in
h) usage
   exit 0;;
f) HOSTSFILE="$OPTARG" ;;
k) DESTROY=yes;;
?) usage
   exit 1;;
esac
done

stop_hosts

virsh list --all
