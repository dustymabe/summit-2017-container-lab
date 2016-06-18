#!/bin/bash
#execute the functionality in lab5
set -eux

mkdir -p ~/workspace/nulecule/
cp -R ~/labs/lab5/* ~/workspace/nulecule/

# Fix nulecule file
sed -i 's|#   source: "docker://mariadb-rhel7-atomicapp"|    source: "docker://mariadb-rhel7-atomicapp" |' ~/workspace/nulecule/wordpress-atomicapp/Nulecule

# Log back in to CDK openshift
oc login --insecure-skip-tls-verify=true -u openshift-dev -p devel localhost:8443

# Clean up items from previous lab
oc delete project sample-project
sleep 10
oc new-project sample-project

# Inspect atomicapp docker image
docker pull devstudio/atomicapp:0.5.0
sudo atomic info devstudio/atomicapp:0.5.0

# Generate Answers file
cd ~/workspace/nulecule/wordpress-atomicapp/
sudo -E atomic run devstudio/atomicapp:0.5.0 --mode genanswers ./

# Populate the contents of the answers file
export CONTENTS="
[mariadb]
image = rhel-cdk.example.com:5000/mariadb
db_pass = password
db_user = user
db_name = name
[wordpress]
image = rhel-cdk.example.com:5000/wordpress
db_pass = password
db_user = user
db_name = name
[general]
namespace = sample-project
provider = openshift
provider-config = /home/vagrant/.kube/config
"
sudo -E su -c 'echo "$CONTENTS" > answers.conf'

# Run the Atomic App
sudo -E atomic run devstudio/atomicapp:0.5.0 ./


# Build the Atomic App
docker build -t wordpress-rhel7-atomicapp ./

# Tag+Push
docker tag wordpress-rhel7-atomicapp rhel-cdk.example.com:5000/wordpress-rhel7-atomicapp
docker push rhel-cdk.example.com:5000/wordpress-rhel7-atomicapp
