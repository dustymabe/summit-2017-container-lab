#!/bin/bash

# Set root pw
echo student | passwd root --stdin
# Log out/log in as root

# Delete cloud-user
userdel cloud-user
rm -rf /home/cloud-user
# Disable cloud-init in the future
systemctl disable cloud-config cloud-final cloud-init-local cloud-init cloud-config
# Set hostname
hostnamectl set-hostname labvm

# Name of user to use
USERNAME=student
PASSWORD=student

# Add custom repo
cat <<EOF > /etc/yum.repos.d/custom.repo
[rhel-7-server-rpms]
baseurl = http://192.168.122.1:8000/yumrepos/rhel-7-server-rpms
sslverify = 0
name = RHEL 7 Server - DVD RPMs
enabled = 1
gpgcheck = 0
[vagrant-yumrepo]
baseurl = http://192.168.122.1:8000/yumrepos/vagrant-yumrepo
sslverify = 0
name = RHEL 7 Server - DVD RPMs
enabled = 1
gpgcheck = 0
EOF

# Install basic desktop software
yum install -y @gnome-desktop xorg-x11-server-Xorg xorg-x11-drv-evdev firefox vim git
# Make graphical Desktop the default
ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
cat > /etc/dconf/db/local.d/00-screensaver <<EOF
[org/gnome/desktop/session]
idle-delay=uint32 0
[org/gnome/desktop/screensaver]
lock-enabled=false
lock-delay=uint32 0
EOF
cat > /etc/dconf/db/local.d/locks/screensaver <<EOF
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/screensaver/lock-delay
EOF
dconf update

# Stuff for the CDK
yum groupinstall -y "Virtualization Host"
#   yum-config-manager --add-repo=http://mirror.centos.org/centos-7/7/sclo/x86_64/sclo/
#   echo gpgcheck=0 >> /etc/yum.repos.d/mirror.centos.org_centos-7_7_sclo_x86_64_sclo_.repo
#   yumdownloader --resolve --urls --archlist=x86_64,noarch \
#       --disablerepo=* \
#       --enablerepo=rhel-server-rhscl-7-rpms \
#       --enablerepo=rhel-7-server-optional-rpms \
#       --enablerepo=mirror.centos.org_centos-7_7_sclo_x86_64_sclo_ \
#       --enablerepo=srhel-7-server-rpms \
#       sclo-vagrant1 sclo-vagrant1-vagrant-libvirt sclo-vagrant1-vagrant-libvirt-doc 
yum install -y sclo-vagrant1 sclo-vagrant1-vagrant-libvirt sclo-vagrant1-vagrant-libvirt-doc
cp /opt/rh/sclo-vagrant1/root/usr/share/vagrant/gems/doc/vagrant-libvirt-*/polkit/10-vagrant-libvirt.rules /etc/polkit-1/rules.d

# Add alias for pulling the lab down from github
cat <<EOF > /usr/local/bin/getlab
#!/bin/bash
git clone https://github.com/dustymabe/summit-2017-container-lab
EOF
chmod 755 /usr/local/bin/getlab


# Enable nested virt (improves performance in L1 guest)
# will take effect after reboot
echo "options kvm-intel nested=y" > /etc/modprobe.d/nestvirt.conf

systemctl restart polkit
systemctl start libvirtd
systemctl enable libvirtd


# Set up the vagrantrepohost VM to host docker reg and yum repos
wget 192.168.122.1:8000/vagrant/vagrantRepoHostBox.box
function vagrant() { echo "vagrant $@" | scl enable sclo-vagrant1 bash; }
vagrant box add --name vagrantRepoHost  ./vagrantRepoHostBox.box
rm -f ./vagrantRepoHostBox.box
fstrim -v /
mkdir /root/vagrantRepoHost
pushd /root/vagrantRepoHost
curl 192.168.122.1:8000/vagrant/vagrantRepoHostBox.Vagrantfile > Vagrantfile
vagrant up # will fail but should upload box
vagrant destroy
> /root/.vagrant.d/boxes/vagrantRepoHost/0/libvirt/box.img
popd
fstrim -v /
#virsh autostart vagrantRepoHost_default
#virsh net-autostart vagrant-libvirt
#virsh net-autostart vagrantRepoHost0
#virsh shutdown vagrantRepoHost_default

# Set up for root user and put in systemd service for it to start on boot
cat <<EOF > /etc/systemd/system/vagrantrepohost.service                                                                                                                                                                          
[Unit]
Description=vagrantrepohost
After=libvirtd.service
[Service]
Environment="HOME=/root/"
Type=oneshot
ExecStart=/bin/bash -c "cd /root/vagrantRepoHost && echo 'vagrant up' | scl enable sclo-vagrant1 bash"
EOF
# Enable service; for some reason was getting an error when
# trying to do this via systemctl enable vagrantrepohost
ln -s /etc/systemd/system/vagrantrepohost.service  /etc/systemd/system/multi-user.target.wants/


# Add user
useradd $USERNAME
echo $PASSWORD | passwd student --stdin
echo "${USERNAME} ALL=NOPASSWD: ALL" > /etc/sudoers.d/student
# Add user to vagrant group
usermod -a -G vagrant $USERNAME

# Become user 
su - $USERNAME

# Grab boxes/cdk files
# Temporary function to allow us to run vagrant directly
function vagrant() { echo "vagrant $@" | scl enable sclo-vagrant1 bash; }
mkdir -p ~/Desktop/tmp
pushd ~/Desktop/tmp

# Install plugins
# Installing from cdk.zip does not work right now: 
#   https://bugzilla.redhat.com/show_bug.cgi?id=1330216
# Crap to make vagrant plugin installs work GRRRRRRR
sudo yum install -y rh-ruby22-ruby-devel gcc gcc-c++ zlib-devel patch libvirt-devel
vagrant plugin install vagrant-registration --plugin-version 1.2.1 
vagrant plugin install vagrant-sshfs --plugin-version 1.1.0
vagrant plugin install vagrant-service-manager --plugin-version 1.0.1
####wget 192.168.122.1:8000/vagrant/cdk.zip
####unzip cdk.zip
####pushd ./cdk/plugins
####vagrant plugin install ./vagrant-registration-1.2.1.gem ./vagrant-service-manager-1.0.1.gem ./vagrant-sshfs-1.1.0.gem
####popd


wget 192.168.122.1:8000/vagrant/rhel-atomic-cloud-7.2-19.x86_64.vagrant-libvirt.box
vagrant box add --name rhelah ./rhel-atomic-cloud-7.2-19.x86_64.vagrant-libvirt.box
rm -f ./rhel-atomic-cloud-7.2-19.x86_64.vagrant-libvirt.box
sudo fstrim -v /
vagrant init rhelah
vagrant up
vagrant destroy
> /home/student/.vagrant.d/boxes/rhelah/0/libvirt/box.img
sudo fstrim -v /
rm Vagrantfile


wget 192.168.122.1:8000/vagrant/rhel-cdk-kubernetes-7.2-23.x86_64.vagrant-libvirt.box
vagrant box add --name cdkv2  ./rhel-cdk-kubernetes-7.2-23.x86_64.vagrant-libvirt.box
rm -f ./rhel-cdk-kubernetes-7.2-23.x86_64.vagrant-libvirt.box 
sudo fstrim -v /
vagrant init cdkv2
vagrant up
vagrant destroy
> /home/student/.vagrant.d/boxes/cdkv2/0/libvirt/box.img
sudo fstrim -v /
rm Vagrantfile

popd
rmdir ~/Desktop/tmp
exit

# Add some custom info to /etc/hosts
cat <<EOF >>/etc/hosts
10.1.2.2 rhel-cdk.example.com
10.1.2.2 dev.example.com
10.1.2.3 deploy.example.com
10.1.2.2 wordpress-sample-project.rhel-cdk.10.1.2.2.xip.io
10.1.2.3 wordpress-production.deploy.example.com.10.1.2.3.xip.io
EOF

# Done installing software remove custom repo
rm -f /etc/yum.repos.d/custom.repo
fstrim -v /



