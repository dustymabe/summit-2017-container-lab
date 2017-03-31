#!/bin/bash

# exit on any error
set -o errexit

# A few tunable variables
NAME='atomic'
ISO='/extra-space/rhel-atomic-installer-7.3.3-1.x86_64.iso'
RAMSIZE='4500' # IN MB
DISKSIZE='20'  # IN GB
VCPUS='2'      # NUM of CPUs
IMAGEDIR='/extra-space/'

# Create some temporary files
TMPDIR=$(mktemp -d)
KS="${TMPDIR}/ks.conf"

# Populate the ks file
cat <<EOF > $KS
install
shutdown
lang en_US.UTF-8
keyboard us
rootpw redhat
authconfig --enableshadow --passalgo=sha512
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --driveorder=vda --append="crashkernel=auto"
network --bootproto=dhcp --onboot=yes

# Partition info
zerombr
clearpart --all
autopart --type=lvm

# For RHEL7
ostreesetup --osname="rhel-atomic-host" --remote="rhel-atomic-host" --url="file:///install/ostree" --ref="rhel-atomic-host/7/x86_64/standard" --nogpg

services --disabled="cloud-init,cloud-config,cloud-final,cloud-init-local"

%post --erroronfail
rm -f /etc/ostree/remotes.d/*.conf

# Configure docker
echo "INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16 --insecure-registry 192.168.0.0/16'" >> /etc/sysconfig/docker

# Grab oc
curl -L http://file.rdu.redhat.com/~dmabe/oc > /usr/local/bin/oc
chmod +x /usr/local/bin/oc

# Gives extra performance to L2 guests
echo "options kvm-intel nested=y" > /etc/modprobe.d/nestvirt.conf

# Create systemd unit file for oc cluster up
cat <<'IEOF' > /etc/systemd/system/openshift.service
[Unit]
Description=Start Openshift
Requires=docker.service
After=docker.service

[Service]
Type=forking
Environment=KUBECONFIG=/root/.kube/config
ExecStart=/usr/local/bin/oc cluster up --use-existing-config=true --host-data-dir=/var/lib/origin/openshift.local.etcd/ --public-hostname atomic-host.example.com --routing-suffix atomic-host.example.com
ExecStartPost=/bin/bash -c "/usr/bin/docker inspect -f '{{.State.Pid}}' origin > /root/openshift.pid"
PIDFile=/root/openshift.pid
ExecStop=/usr/local/bin/oc cluster down
TimeoutStartSec=10min
IEOF

ln -sf /etc/systemd/system/openshift.service /etc/systemd/system/multi-user.target.wants/openshift.service

cat <<'AEOF' > /etc/sysconfig/network-scripts/ifcfg-eth0 
NAME="eth0"
ONBOOT=yes
NETBOOT=yes
IPV6INIT=yes
TYPE=Ethernet
BOOTPROTO=none
IPADDR=192.168.124.100
GATEWAY=192.168.124.1
AEOF

%end
EOF

# Build up the virt-install command
cmd='virt-install'
cmd+=" --name $NAME"
cmd+=" --ram  $RAMSIZE"
cmd+=" --vcpus $VCPUS"
cmd+=" --disk path=${IMAGEDIR}/${NAME}.img,size=$DISKSIZE"
cmd+=" --accelerate"
cmd+=" --location $ISO"
cmd+=" --initrd-inject $KS"
cmd+=" --graphics none"
cmd+=" --force"
cmd+=" --network network=default"
cmd+=" --noreboot"

# Variable for kernel args.
extras="console=ttyS0 ks=file://ks.conf text"

# Run the command
echo "Running: $cmd --extra-args=$extras"
$cmd --extra-args="$extras"

# Clean up tmp dir
rm -rf $TMPDIR/
