#!/bin/bash
# execute the functionality in lab4 that other labs depend on 
set -eux

# Start openshift since we haven't started it already
sudo systemctl start openshift

mkdir -p ~/workspace
cp -R ~/labs/lab4/* ~/workspace/

## Local
# Login to openshift - creates .kubeconfig file 
oc login -u openshift-dev -p devel

oc create -f ~/workspace/mariadb/openshift/mariadb-pod.yaml
oc create -f ~/workspace/mariadb/openshift/mariadb-service.yaml
oc create -f ~/workspace/wordpress/openshift/wordpress-pod.yaml
oc create -f ~/workspace/wordpress/openshift/wordpress-service.yaml
oc expose svc/wordpress

## REMOTE
oc login --insecure-skip-tls-verify=true -u openshift-dev -p devel https://deploy.example.com:8443
oc new-project production
oc create -f ~/workspace/mariadb/openshift/mariadb-pod.yaml
oc create -f ~/workspace/mariadb/openshift/mariadb-service.yaml
oc create -f ~/workspace/wordpress/openshift/wordpress-pod.yaml
oc create -f ~/workspace/wordpress/openshift/wordpress-service.yaml
oc expose svc/wordpress
