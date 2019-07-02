#!/bin/bash

source ./env.sh

echo "copying sample configuration hosts.ocp, hosts and 3-keys.sh to the jumpstation"
# TODO: this should be updated to use a real jump machine hostname from the list of hosts, and not assume 'jump' is valid
#scp hosts.ocp root@jump.$DOMAIN:~/
#scp hosts     root@jump.$DOMAIN:~/
#scp 3-keys.sh root@jump.$DOMAIN:~/
scp -r * root@jump.$DOMAIN:~/
echo "Now go do these steps:"
echo " hypervisor$ ssh root@jump.$DOMAIN"
echo "       jump# ssh-keygen    # accept the defaults"
echo "       jump# bash ./3-keys.sh"
echo "       jump# ansible-playbook -i hosts.ocp /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml"
echo "       jump# ansible-playbook -i hosts.ocp /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml"
# TODO: master node name could be pulled from the list of masters in the envs/hosts/etc
echo "       jump# ssh root@<master node> \"htpasswd -b /etc/origin/master/htpasswd <user> <pass>\" " 
# uncomment this out when we fix why oadm isn't on the jump host. Should this be run on the master instead of the jump?
#echo "       jump# oadm policy add-role-to-user system:registry <user> (optional)   

exit
