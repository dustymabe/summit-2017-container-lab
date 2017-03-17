# Mount the RHEL 7 Server - iso under rpms dir 

sudo mount -o loop /mnt/rhel-server-7.2-x86_64-dvd.iso ./yumrepos/rhel-7-server-rpms/

# Bring up the vagrantRepoHostBuild box

vagrant up

# Wait for files to be copied into box

# Fix perms so vagrant can package it

sudo chmod a+r /guests/storagepools/libvirt/vagrantRepoHostBuild_default.img 

# Package it up

vagrant package --output vagrantRepoHostBox.box 

 -- ignore: virt-sysprep: error: no operating systems were found in the guest image

# Add box 

vagrant box add --name vagrantRepoHost ./vagrantRepoHostBox.box

