#!/bin/bash

DESTROY=no

usage() {
        echo "$0:"
        echo "-h for help"
        echo "-f <hosts file>"
        exit 0
}

stop_hosts() {
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
    echo "################################## Removing: ${i}"

      BASEIMAGE="${VMS}/${i}-base.qcow2"
          IMAGE="${VMS}/${i}.qcow2"
        XMLFILE="${VMS}/${i}.xml"
     DOCKERDISK="${VMS}/${i}-docker.qcow2"
    GLUSTERDISK="${VMS}/${i}-glusterfs.qcow2"

    if [ "$DESTROY" == 'yes' ]; then
      virsh destroy  "$i"
    else 
      virsh shutdown "$i"
    fi

    virsh undefine "$i"
    rm "$BASEIMAGE" "$IMAGE" "$DOCKERDISK" "$XMLFILE" "$GLUSTERDISK"
    ssh-keygen -R "$i"
  done

  exit 0
}

source ./env.sh

while getopts h?k?f: option
do
case "${option}"
in
h) usage
   exit 0;;
f) stop_hosts "$OPTARG" ;;
k) DESTROY=yes;;
?) echo "unexpected flag: '${OPTARG}'"
   exit;;
esac
done

stop_hosts

virsh list --all
