#!/bin/bash

# exit on any error
set -o errexit

# A few tunable variables
NAME='cdrom'
ISO='/extra-space/rhel-server-7.3-x86_64-boot.iso'
ISO='http://download-node-02.eng.bos.redhat.com/released/RHEL-7/7.3/Workstation/x86_64/os/'
RAMSIZE='14000' # IN MB
DISKSIZE='50'  # IN GB
VCPUS='6'      # NUM of CPUs
IMAGEDIR='/extra-space/'

# Create some temporary files
TMPDIR=$(mktemp -d)
KS="${TMPDIR}/ks.conf"

# Populate the ks file
cat <<EOF > $KS
install
#url --url=http://download-node-02.eng.bos.redhat.com/released/RHEL-7/7.3/Server/x86_64/os/
reboot
lang en_US.UTF-8
keyboard us
rootpw redhat
authconfig --enableshadow --passalgo=sha512
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --driveorder=vda --append="crashkernel=auto"
user --name=student --password=student --groups=libvirt
#network --bootproto=static --ip=192.168.122.100 --netmask=255.255.255.0  --gateway=192.168.122.1 --nameserver=192.168.122.1
network --bootproto=dhcp
firstboot --disable
repo --name=rhel-7-server-extras-rpms-local --baseurl=http://192.168.122.250/pub/rhel-7-server-extras-rpms 
repo --name=rhel-7-server-optional-rpms-local --baseurl=http://192.168.122.250/pub/rhel-7-server-optional-rpms
repo --name=rhel-7-server-ose-3.4-rpms-local --baseurl=http://192.168.122.250/pub/rhel-7-server-ose-3.4-rpms
repo --name=rhel-7-server-rpms-local --baseurl=http://192.168.122.250/pub/rhel-7-server-rpms



# Partition info
zerombr
clearpart --all
part / --size=3000 --fstype=ext4 --grow

%packages --instLangs=en_US
@gnome-desktop
@x-window-system
firefox
vim
atomic
docker
git
libvirt
qemu-kvm
%end


%post --erroronfail

# Set graphical login

# Grab minishift
curl -L http://cdk-builds.usersys.redhat.com/builds/plain/dusty_lab/linux-amd64/minishift > /usr/local/bin/minishift
chmod +x /usr/local/bin/minishift

# Grab docker-machine-driver-kvm
curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.8.2/docker-machine-driver-kvm > /usr/local/bin/docker-machine-driver-kvm
chmod +x /usr/local/bin/docker-machine-driver-kvm

# Grab oc
curl -L http://file.rdu.redhat.com/~dmabe/oc > /usr/local/bin/oc
chmod +x /usr/local/bin/oc

# Grab atomic qcow2
curl -L http://192.168.122.1:8000/atomic.qcow2 >  /var/lib/libvirt/images/atomic.qcow2
qemu-img create -f qcow2 -b /var/lib/libvirt/images/atomic.qcow2 /var/lib/libvirt/images/atomic-1.qcow2 

# Gives extra performance to L2 guests
echo "options kvm-intel nested=y" > /etc/modprobe.d/nestvirt.conf

# Add yum repo to the system
cat <<'IEOF' > /etc/yum.repos.d/summit-2017-lab.repo 
[rhel-7-server-extras-rpms-local]
metadata_expire = 86400
baseurl = http://192.168.122.250/pub/rhel-7-server-extras-rpms
name = rhel-7-server-extras-rpms
enabled = 1
gpgcheck = 0

[rhel-7-server-optional-rpms-local]
metadata_expire = 86400
baseurl = http://192.168.122.250/pub/rhel-7-server-optional-rpms
name = rhel-7-server-optional-rpms
enabled = 1
gpgcheck = 0

[rhel-7-server-ose-3.4-rpms-local]
metadata_expire = 86400
baseurl = http://192.168.122.250/pub/rhel-7-server-ose-3.4-rpms
name = rhel-7-server-ose-3.4-rpms
enabled = 1
gpgcheck = 0

[rhel-7-server-rpms-local]
metadata_expire = 86400
baseurl = http://192.168.122.250/pub/rhel-7-server-rpms
name = rhel-7-server-rpms
enabled = 1
gpgcheck = 0
IEOF


cat <<'AEOF' > /etc/sysconfig/network-scripts/ifcfg-eth0 
NAME="eth0"
ONBOOT=yes
NETBOOT=yes
IPV6INIT=yes
TYPE=Ethernet
BOOTPROTO="dhcp"
#BOOTPROTO=none
#IPADDR=192.168.122.100
#GATEWAY=192.168.122.1
AEOF

cat <<'BEOF' > /etc/sudoers.d/student
student ALL=(ALL)    ALL
BEOF

echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot
echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> /home/student/.bashrc
chown student:student /home/student/.bashrc

fstrim -v / || true

%end
EOF



# Build up the virt-install command
cmd='virt-install'
cmd+=" --name $NAME"
cmd+=" --cpu  host-passthrough" # for nested virt
cmd+=" --ram  $RAMSIZE"
cmd+=" --vcpus $VCPUS"
cmd+=" --disk path=${IMAGEDIR}/${NAME}.img,size=$DISKSIZE,sparse=true"
cmd+=" --accelerate"
cmd+=" --location $ISO"
cmd+=" --initrd-inject $KS"
#cmd+=" --graphics none"
#cmd+=" --console pty,target_type=virtio --noautoconsole"
cmd+=" --noautoconsole"
cmd+=" --force"
cmd+=" --network network=default"

# Variable for kernel args.
#extras="console=ttyS0 ksdevice=link inst.sshd ks=file://ks.conf"
extras="ksdevice=link inst.sshd ks=file://ks.conf"

# Run the command
echo "Running: $cmd --extra-args=$extras"
$cmd --extra-args="$extras"

# Clean up tmp dir
rm -rf $TMPDIR/
