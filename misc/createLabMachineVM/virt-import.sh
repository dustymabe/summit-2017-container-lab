#!/bin/bash

# exit on any error
set -o errexit

# A few tunable variables
NAME='labvm'
ORIGINDISK='/guests/images/rhel-guest-image-7.2-20160219.1.x86_64.qcow2' # RHEL 7 Server --20160219.1
ORIGINDISK='/guests/images/rhel-guest-image-7.2-20151102.0.x86_64.qcow2'
DISK='/guests/images/labvm.qcow2'

RAMSIZE='10240' # IN MB
DISKSIZE='40'  # IN GB
VCPUS='4'      # NUM of CPUs
BRIDGE='virbr0'
TMPISO="/guests/storagepools/manual/user-data-iso.iso${RANDOM}"

USERDATA='
#cloud-config
password: student
chpasswd: { expire: False }
ssh_pwauth: True
'
METADATA='
instance-id: id-mylocal0001
local-hostname: cloudhost
'

echo "Creating user data iso $TMPISO"
pushd $(mktemp -d)
echo "$USERDATA" > user-data
echo "$METADATA" > meta-data
genisoimage -output $TMPISO -volid cidata -joliet -rock user-data meta-data
popd

#echo "Creating snapshot disk $TMPDISK"
#qemu-img create -f qcow2 -b $DISK $TMPDISK 10G
#echo "Will use backing disk $DISK"
#echo "Will use snapshot disk $TMPDISK"

echo "Copying $ORIGINDISK to $DISK"
cp $ORIGINDISK $DISK

echo "Resizing $DISK to ${DISKSIZE}G"
qemu-img resize $DISK "${DISKSIZE}G"

# Build up the virt-install command
cmd='virt-install --import'
cmd+=" --name $NAME"
cmd+=" --cpu  host-passthrough" # for nested virt
cmd+=" --ram  $RAMSIZE"
cmd+=" --vcpus $VCPUS"
cmd+=" --disk path=${DISK},bus=scsi,discard=unmap"
cmd+=" --controller scsi,model=virtio-scsi"
cmd+=" --disk path=$TMPISO"
cmd+=" --accelerate"
#cmd+=" --graphics none"
cmd+=" --force"
cmd+=" --network bridge=$BRIDGE,model=virtio"

# Run the command
echo "Running: $cmd"
$cmd
