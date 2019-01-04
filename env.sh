# See README.md
export DOMAIN="home.lan"
declare -A MACADDRESS=( \
        ["jump."$DOMAIN]="52:54:00:42:B4:AD" \
     ["master1."$DOMAIN]="52:54:00:AC:C6:E1" \
       ["node1."$DOMAIN]="52:54:00:4A:22:9B"   \
       ["node2."$DOMAIN]="52:54:00:4A:22:9C"   \
)
export OCPDOMAIN="ocp.home.lan"
export WORKSPACE="$HOME/ocp"
export VMS="$WORKSPACE/VMs"
export ORIGINALKEY=$HOME/.ssh/id_rsa.pub
export CLUSTERKEY=$WORKSPACE/vm_id_rsa.pub
export ISOS="/isos"
export RHEL_IMAGE="$ISOS/rhel-server-7.6-x86_64-kvm.qcow2"
export BRIDGE="brtwo" # or virbr0 depending on your needs
#export BRIDGE="virbr0"
export VMRAM_JUMP=8192
export VMRAM_OCP=24576
export VMROOTDISK=60G
export VMDOCKERDISK=10G
export VMGLUSTERFSDISK=10G
export CPUMODEL=Westmere-IBRS
export INITIALPASSWD=redhat
