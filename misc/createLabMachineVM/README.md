
There will be one giant VM that runs on the student's lab machines.
This VM will be a full desktop environment and will also run the
vagrant boxes for the lab as well as a repo server to host a docker
registry and a yum repo.

The scripts in this directory help to create the lab machine.

# Mount up RHEL 7 Server - DVD and serve it from another terminal
sudo mount -o loop /mnt/rhel-server-7.2-x86_64-dvd.iso ./filestoshare/yumrepos/rhel-7-server-rpms/
cd ./filestoshare/ && python -m SimpleHTTPServer

# Start up VM
./virt-import.sh

# Run script.sh manually on after logging in to VM

# Shut down VM

# Dump libvirt XML

# Edit libvirt xml and Remove user data iso

# Save via 
tar -c --xz -f labvm.v1.tar.xz labvm.xml labvm.qcow2 README.md 

