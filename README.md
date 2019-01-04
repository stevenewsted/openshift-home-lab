# openshift-home-lab
Sample script to build a KVM environment for OpenShift 3.11 in a lab environment. This is not intended for production use, but rather for testing. 

Thanks to mmagnani, ruchika, @hupiper, and @MarcNo for kickstarting the initial work.

## What do you get

* Three RHEL7.5 VMs running in KVM (1 master, 1 node, 1 jump). 
  * You can add more as desired as part of the initial installation, or after you get things up and running. 
* Registered and appropriate subscriptions attached
* required RPMs installed, including atomic-openshift-installer
* docker installed and storage configured
* an OpenShift cluster (installed from the jump VM)

## Requirements

* Access to a DNS server. (Either public or internal)
* Access to a DHCP server. (Anything that can provide static leases) 
* RHEL 7 KVM hypervisor host (or compatible, like Fedora/CentOS)
* `rhel-server-7.5-x86_64-kvm.qcow2` from:
  * From [Redhat download section](https://access.redhat.com/downloads/) > Red Hat Enterprise Linux > the KVM guest image
* 1 free NIC on the host

**If you are looking at this the first time, and wondering what you need to know to get up and running, this is the place to start reading.**

### 1. Pull a local copy of the scripts

Clone this git repo to your hypervisor, or fork it and clone your own fork of this git repo.

### 2. Create working directories
Create two working directories: one for ISOs (specifically the rhel kvm image), and one to store your local VM disks and configs. 
```
mkdir ~/ocp/VMs
mkdir ~/ISOs
```
These can be anywhere, but the examples here correlate to the default configuration in the `env.sh` configuration.

### 3. Edit hosts file

There are several host files in this repo. The first one you want to look at is hosts. After the [ocp] line, make sure the next two lines are the FQDN's for your master(s) and your node(s):

```
[ocp]
master0.domain.com
node0.domain.com
```
Edit the hosts.jump file to include the FQDN of your new jump host:
```
[jump]
jump.domain.com
```
These instructions assume you are installing a jump VM in addition to a master and node VMs. The install scripts for the jump are separate to allow you to skip the jump server if you choose to.

### 4. Edit env.sh

When you look at the `env.sh` file, you'll notice that the MAC addresses are already set up for your VMs. You need to take those MACs and add them to the 

  - DOMAIN - the domain name to use for the hosts (ie: domain.com)
  - MACADDRESS - MAC addresses for your VMs (be unique)
  - OCPDOMAIN - the domain name for the cluster (ie: ocp.ocpdomain.com, \*.apps.ocpdomain.com\)  
  - WORKSPACE, VMS - where VMs, etc are stored
  - ISOS - where your ISOs can be found
  - RHEL_IMAGE - your rhel-server-7.5-x86_64-kvm.qcow2 image
  - BRIDGE - which bridge to use.  See Network Notes below

### 5. Add DNS A records for your domains
You can use public DNS like godaddy to host your DNS records; or something internal like dnsmasq so I don't need to hack `/etc/resolv.conf`. But you will need to create/update your DNS A records to point to the local addresses so it looks like this.  eg:

        $ nslookup jump.$DOMAIN
        Server:		8.8.8.8
        Address:	8.8.8.8#53

        Non-authoritative answer:
        Name:	jump.$DOMAIN
        Address: 192.168.88.99

Your A record for domain.com would be:
```
Host *           Points to *            TTL
jump             192.168.88.99          1 hour
```

Also setup wildcard DNS entry for ocp.$OCPDOMAIN, \*.apps.$OCPDOMAIN to point to the master0.$DOMAIN IP address.

### 6. Update your DHCP server
Tie those specific IP addresses defined in DNS to known mac addresses using static DHCP leases.  We need the VMs to always get the same IP address.

### 7. Add required packages to your hosts
Install the required pacakages on your host:

```
$ sudo yum install -y ansible
$ sudo yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install
```
Start and enable the libvirtd virtualization daemon:
```
$ sudo systemctl enable libvirtd
$ sudo systemctl start libvirtd
```
You may also need to install libguestfs-xfs if it isn't installed as a dependency.

### 8. Create ssh keys
```
$ ssh-keygen -f /home/user/.ssh/id_rsa -t rsa -N ''
$ cp ~/.ssh/id_rsa.pub ~/ocp/vm_id_rsa.pub
```
### 9. Check CPU model in 2-build.sh script
1-create.sh creates the VMs for your nodes. 2-build.sh configures them to run in your KVM environment. The virt-install command in this file has a --cpu variable that is read from the `env.sh` configuration. To see what model CPU you are using, use the following command.
```
$ virsh capabilities | grep -i model | head -n1
```
It should output a single line of XML, showing the model, like:
```<model>Skylake-client</model>```
Use the value in between the `model` tags in the `env.sh` configuration file. 

### 10. Set up Linux Bridging

We are using Linux bridging to connect the physical NIC to the VMs in the hypervisor.  The bridge is called LondonBridge (it was that way when I forked - you can use br0 or something similar if you like, but you'll have to make sure all of the scripts are using that name too). This process expects/uses NetworkManager. If you have it disabled, create this configuration yourself.

We need ipv4 forwarding turned on persistently for the host, so add this line to /etc/sysctl.conf:
`net.ipv4.ip_forward=1`

Replace <NIC> in the following with the host interface you want to use for external connectivity for the cluster. (Something like enp0s25, eno2, eth1, etc)
```
$ sudo nmcli con add type bridge con-name LondonBridge ifname LondonBridge
$ sudo nmcli con add type ethernet con-name UK-slave ifname enp0s25 master LondonBridge
$ sudo nmcli con modify LondonBridge bridge.stp no
$ sudo nmcli con up LondonBridge
$ sudo nmcli con up UK-slave
$ brctl show LondonBridge
$ nmcli con show # should be all green
$ ifconfig
```
Then edit /etc/qemu-kvm/bridge.conf and add the line:

`allow LondonBridge`

Optional:

`sudo virsh net-list --all`

If you don't see a `default` network entry from the previous command, do this:

```
$ sudo virsh net-define /usr/share/libvirt/networks/default.xml
$ sudo virsh net-start default
$ sudo virsh net-autostart default
```

### 11. Edit variables.yml

You need to set the `openshift_subscription_pool` for your own Red Hat account. From a RHEL system with an active subscription, use this command will find your pool id:

`subscription-manager list --all --available --matches "*openshift*"`

(You can also find your subscription info in the Red Hat portal.)

Make variable.yml look something like this:

`openshift_subscription_pool: 8a85f98c63842fef01647d9012060465`

### 12. Create ansible-vault vault.yml

Create a vault to store your own Red Hat subscription username/password in variables. (ie: what you use on the Red Hat portal)

**Delete the vault.yml file cloned in this repo first**

  `ansible-vault create vault.yml` - this command will ask you for a new vault password, and open an editor with a file called vault.yml. Add these two lines to this file (quote the password if if has special characters in it):

```
vault_rhn_username: rhn-support-username
vault_rhn_password: secretpassword-for-rhn
```

  Check the resulting file and it should not have the variables in cleartext, but should show something like this:
```
$ cat vault.yml
$ANSIBLE_VAULT;1.1;AES256
35613131303036653238396335393661623664383461633066633431633038666665663365623434
3738376238623639333262633131393738663232376135390a363532346165613633336533326631
65353032326234326434313834613231653064313231396562336563363430396162373036303261
6266623032333137360a653465656263633863336232383632383435613865393335333237626138
36656530653361336463663563306466336462656164313365373338323564663264316462343630
33383730316539363632366235623266613364633135316261623339383963623235343334373933
30383730613836306530383266343139363335363431376366333132643232316462373937363235
34386365613330636266313337616236356262613432313231383864343261316638353864353435
6164
```

### 14. (not superstitious, just careful) Edit hosts.ocp
Change these:
`oreg_auth_user` to your Red Hat subscription name
`oreg_auth_password` to the Red Hat subscription password

Change `openshift_master_default_subdomain` to the OCPDOMAIN you specified in the `env.sh` file.

## Run on your hypervisor

*   `1-create.sh` -- Create qemu files for OS, container storage, OS config
*   `1-create-jump.sh` -- ditto for jump server
*   `2-build.sh` -- Install VMs and attach disks
*   `2-build-jump.sh` -- Install jump VM and attach disk
*   `start-all.sh` -- boot them up /  `$ virsh start jump.domain.com`
*   `3-keys.sh` -- push ssh keys around
*   `4-prep.sh` -- update the VMs with required packages, etc -- this step takes a while
*   `4-prep-jump.sh` -- update the VMs with required packages, etc
*   `5-cluster.sh` -- copy files to jump VMs and remind the next steps

### Install OpenShift

* `hypervisor$ ssh root@jump.pokitoach.com # password is redhat`
* `      jump# ssh-keygen` (accept all defaults)
* `      jump# bash ./3-keys.sh`
* `      jump# ansible-playbook -i hosts.ocp /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml`
* `      jump# ansible-playbook -i hosts.ocp /usr/share/ansible/openshift-ansible/playbooks/deploy-cluster.yml`
* `      jump# ssh root@<master node> "htpasswd -b /etc/origin/master/htpasswd <user> <pass>" `


* Based on what we specified in the hosts.ocp file we are using the HTPasswdPasswordIdentityProvider type of RBAC in OpenShift. So we need to populate
the htpasswd file with users for our system.

  `# touch /etc/origin/master/htpasswd`

  `# htpasswd /etc/origin/master/htpasswd someuser`

### Start using OpenShift

The easiest way to get started is to point a browser to
https://ocp.$OCPDOMAIN:8443/

Good luck!

# Troubleshooting notes

## SSH Keys
If you run into the `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` message, use `ssh-keygen -R node.domain.com` for each host. Then you need to ssh into them again to add them to the `known_hosts` file. This shouldn't come up often though, as the `kill-all.sh` script should be removing them automatically.

May need to scp ssh keys and/or ssh into the other nodes from the jump node to make sure the `known_hosts` file is updated.


# Random notes from the 5-cluster script:

https://access.redhat.com/documentation/en-us/openshift_container_platform/3.5/html/installation_and_configuration/installing-a-cluster#what-s-next-2

Once the cluster is created, 

ssh root@master0.$DOMAIN and do:

   htpasswd -b /etc/origin/master/htpasswd marc SekretPassword
   oadm policy add-role-to-user system:registry marc


https://access.redhat.com/documentation/en-us/openshift_container_platform/3.5/html/installation_and_configuration/setting-up-the-registry#install-config-registry-overview

for non production use (may not have to do)

$ sudo chown 1001:root <path>
$ oadm registry --service-account=registry \
    --config=/etc/origin/master/admin.kubeconfig \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --mount-host=<path>

https://access.redhat.com/documentation/en-us/openshift_container_platform/3.5/html/installation_and_configuration/setting-up-a-router#install-config-router-overview

oadm policy add-cluster-role-to-user \
    cluster-reader \
    system:serviceaccount:default:router

oadm router <router_name> --replicas=<number> --service-account=router

https://master0.$DOMAIN:8443/
