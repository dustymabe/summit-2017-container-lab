#! /bin/bash

echo "ensure you have vagrant boxes called 'rhel-7.1' and 'rhel-atomic-host'"
echo "you also need qemu-img; e.g. yum install qemu-img"
echo "must be run with sudo"
#echo "kinda assumes you are in the vagrant dir.. not sure that is a good idea, be sure to vagrant halt though if you run this "
#echo "from somewhere else"
echo "disabled the vagrant halt part of this script, be sure you have halted before running this"
#vagrant up
#vagrant halt

#figure out the virsh domain name of dev vm
NAME_OF_DEV=`virsh list --all | awk '{print $2}' | grep summit_rhel_dev`
echo "Dev virsh domain name: $NAME_OF_DEV"
virsh dumpxml $NAME_OF_DEV > dev_example_com.xml

#figure out the virsh domain name of deploy vm
NAME_OF_DEPLOY=`virsh list --all | awk '{print $2}' | grep summit_rhel_deploy_target`
echo "Deploy virsh domain name: $NAME_OF_DEPLOY"
virsh dumpxml $NAME_OF_DEPLOY > deploy_example_com.xml

#convert to qcow, rebase image for dev machine
IMAGE=`sed -e "s/.*'\(.*summit_rhel_dev.img\)'.*/\1/g" dev_example_com.xml | grep img`
echo "Dev image name: $IMAGE; about to convert, might be awhile"
qemu-img convert -f qcow2 -O qcow2 -o compat=0.10 $IMAGE ./dev_example_com.qcow2
xz -z -k ./dev_example_com.qcow2
#mv ./dev_example_com.qcow2 /var/lib/libvirt/images/
#echo "moving ./dev_example_com.qcow2 /var/lib/libvirt/images/"
#chown qemu:qemu /var/lib/libvirt/images/dev_example_com.qcow2

#convert to qcow, rebase image for deploy machine
IMAGE=`sed -e "s/.*'\(.*summit_rhel_deploy_target.img\)'.*/\1/g" deploy_example_com.xml | grep img`
echo "Deploy image name: $IMAGE; about to convert, might be awhile"
qemu-img convert -f qcow2 -O qcow2 -o compat=0.10 $IMAGE ./deploy_example_com.qcow2
xz -z -k ./deploy_example_com.qcow2
#echo "moving ./deploy_example_com.qcow2 /var/lib/libvirt/images/"
#mv ./deploy_example_com.qcow2 /var/lib/libvirt/images/
#chown qemu:qemu /var/lib/libvirt/images/deploy_example_com.qcow2

echo "fix up the xml to give some prettier names"
sed -i -e "s|<name>.*</name>|<name>dev_example_com</name>|g" dev_example_com.xml
sed -i -e "s|<uuid>.*</uuid>|<uuid>`uuidgen`</uuid>|g" dev_example_com.xml
sed -i -e "s|<name>.*</name>|<name>deploy.example.com</name>|g" deploy_example_com.xml
sed -i -e "s|<uuid>.*</uuid>|<uuid>`uuidgen`</uuid>|g" deploy_example_com.xml

echo "fix up the xml to point to this new file"
echo "this may be wrong if you dont use the default pool for your vms"
sed -i -e "s|'\(.*summit_rhel_dev.img\)'|'./dev_example_com.qcow2'|g" dev_example_com.xml
sed -i -e "s|'\(.*summit_rhel_deploy_target.img\)'|'./deploy_example_com.qcow2'|g" deploy_example_com.xml

echo "fix up the xml to point to the containerize network including changing macs"
echo "this may be wrong if you dont use the default network for your vms"
sed -i -e "s|<source network='vagrant-libvirt'/>|<source network='containerize'/>|g" dev_example_com.xml
sed -i -e "s|<source network='vagrant-libvirt'/>|<source network='containerize'/>|g" deploy_example_com.xml
sed -i -e "s|<mac address='.*'/>|<mac address='52:54:00:b3:3e:1e'/>|g" dev_example_com.xml
sed -i -e "s|<mac address='.*'/>|<mac address='52:54:00:b3:3e:1d'/>|g" deploy_example_com.xml
sed -i -e '/<emulator>.*<\/emulator>/d' dev_example_com.xml
sed -i -e '/<emulator>.*<\/emulator>/d' deploy_example_com.xml


