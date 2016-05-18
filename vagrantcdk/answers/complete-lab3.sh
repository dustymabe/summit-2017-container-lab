#!/bin/bash
#execute the functionality in lab3 that other labs depend on 
set -eux

cd ~/labs/lab3

docker stop bigapp #a little safer then $(docker ps -ql)
docker rm bigapp #a little safer then $(docker ps -ql)

sudo mkdir -p /var/lib/mariadb
sudo mkdir -p /var/lib/wp_uploads
sudo chcon -Rt svirt_sandbox_file_t /var/lib/mariadb
sudo chcon -Rt svirt_sandbox_file_t /var/lib/wp_uploads

docker build -t mariadb -f mariadb/Dockerfile.reference mariadb/.
docker build -t wordpress -f wordpress/Dockerfile.reference wordpress/.

docker build -t mariadb -f mariadb/Dockerfile.reference mariadb/.
docker build -t wordpress -f wordpress/Dockerfile.reference wordpress/.

TARGET_IP='dev.example.com'

docker tag -f mariadb $TARGET_IP:5000/mariadb
docker tag -f wordpress $TARGET_IP:5000/wordpress

docker push $TARGET_IP:5000/mariadb
docker push $TARGET_IP:5000/wordpress
