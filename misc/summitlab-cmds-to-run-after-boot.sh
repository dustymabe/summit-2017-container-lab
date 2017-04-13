# add console=ttyS0 to grub2.cfg 

cat <<EOF >> /etc/hosts
192.168.124.1 workstation.example.com

192.168.124.99 cdk cdk.example.com
192.168.124.99 wordpress-devel.cdk.example.com
192.168.124.99 mariadb-devel.cdk.example.com

192.168.124.100 atomic-host atomic-host.example.com
192.168.124.100 wordpress-production.atomic-host.example.com
192.168.124.100 mariadb-production.atomic-host.example.com
EOF


virsh net-destroy default
virsh net-undefine default
virsh net-define /dev/stdin <<EOF
<network>
  <name>default</name>
  <bridge name="virbr0"/>
  <forward/>
  <ip address="192.168.124.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.124.99" end="192.168.124.99"/>
    </dhcp>
  </ip>
</network>
EOF
virsh net-start default
virsh net-autostart default

#Add alias for pulling the lab down from github
cat <<EOF > /usr/local/bin/getlab
#!/bin/bash
# Grab from https://github.com/dustymabe/summit-2017-container-lab 
cd ~/
curl -L https://github.com/dustymabe/summit-2017-container-lab/archive/master.tar.gz | tar -xz --exclude='misc' --exclude='updateyumrepos.sh' --strip-components 1
EOF
chmod 755 /usr/local/bin/getlab



curl -L http://192.168.122.1:8000/atomic.xml | virsh define /dev/stdin
#virsh autostart atomic-host
virsh start atomic-host
ssh root@atomic-host systemctl status openshift
ssh root@atomic-host oc login -u system:admin
ssh root@atomic-host oc adm policy add-scc-to-group anyuid system:authenticated
virsh shutdown atomic-host

# XXXXXXXXXXXXXXXXXXXXx
# switch to student user
#

minishift setup-cdk
minishift config set show-libmachine-logs true
minishift config set memory 10240
minishift config set cpus 4
mkdir /home/student/.minishift/logs
minishift config set log_dir /home/student/.minishift/logs

minishift start --skip-registration --alsologtostderr --show-libmachine-logs --insecure-registry 172.30.0.0/16 --insecure-registry 192.168.0.0/16 --public-hostname cdk.example.com --routing-suffix cdk.example.com
eval $(minishift docker-env)
docker pull registry.access.redhat.com/rhel7:7.3-74
docker pull registry.access.redhat.com/rhel7
docker pull registry.access.redhat.com/rhel
oc login -u system:admin
oc adm policy add-scc-to-group anyuid system:authenticated
oc login -u developer
minishift stop

# so that we can 'atomic run' on remote tls docker
sudo yum install http://download.eng.bos.redhat.com/brewroot/packages/atomic/1.16.5/1.el7/x86_64/atomic-1.16.5-1.el7.x86_64.rpm

# shutdown and then run
virt-sparsify --convert qcow2 --compress --tmp /extra-space-2/ /extra-space/cdrom.img /extra-space-2/cdrom-sparse.img

# When I parsed the squid access log to determine what rpms to
# download and create a repo out of I used this command
# 1 - truncate white space down to a single space
# 2 - grab the 7th field from the file
# 3 - find only lines where rpms were downloaded
# 4 - get rid of everything but the filename
# 5 - get rid of .rpm on the end 
cat access.log | tr -s ' ' | cut -d ' ' -f 7 | grep -P ".*rpm$" | sed 's|.*/||' | sed 's|\.rpm||'
