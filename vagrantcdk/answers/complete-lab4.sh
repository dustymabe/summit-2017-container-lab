#!/bin/bash
# execute the functionality in lab4 that other labs depend on 
set -ex

# Start openshift since we haven't started it already
sudo systemctl start openshift

mkdir -p ~/workspace
cp -R ~/labs/lab4/* ~/workspace/
cd ~/workspace

# Login to openshift - creates .kubeconfig file 
oc login <<EOF
openshift-dev
devel
EOF

oc create -f ./mariadb/kubernetes/mariadb-pod.yaml
oc create -f ./mariadb/kubernetes/mariadb-service.yaml 
oc create -f ./wordpress/kubernetes/wordpress-pod.yaml 
oc create -f ./wordpress/kubernetes/wordpress-service.yaml 

