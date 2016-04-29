#!/bin/bash
#execute the functionality in lab5

cd ~/lab5/nulecule_template

TARGET_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

mv Nulecule Nulecule.template
mv Nulecule.reference Nulecule

docker build -t wordpress-rhel7-atomicapp .

atomic run wordpress-rhel7-atomicapp

kubectl get pods

docker tag wordpress-rhel7-atomicapp $TARGET_IP/wordpress-rhel7-atomicapp

docker push $TARGET_IP:5000/wordpress-rhel7-atomicapp

