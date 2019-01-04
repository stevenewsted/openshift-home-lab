#!/bin/bash

source ./env.sh

for i in `cat hosts|grep -v \\\\[`;
do

    echo "########################################################################"
    echo "Removing: ${i}"

    baseimage="$VMS/$i-base.qcow2"
    image="$VMS/$i.qcow2"
    xmlfile="$VMS/$i.xml"
    dockerdisk="$VMS/$i-docker.qcow2"
    glusterdisk="$VMS/$i-glusterfs.qcow2"

    virsh destroy $i
    virsh undefine $i
    rm $baseimage $image $dockerdisk $xmlfile $glusterdisk
    ssh-keygen -R $i

done

virsh list --all

exit

