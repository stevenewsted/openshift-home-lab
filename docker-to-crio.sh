# https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine#installing-cri-o-with-a-new-openshift-container-platform-cluster

# perform the following actions on nodes to update mountpoints to change from docker to cri-o
/bin/rm -r /var/lib/docker/
umount /var/lib/docker
rmdir /var/lib/docker
sed -i 's/docker/containers/g' /etc/fstab
mount -a
df -h /var/lib/containers
