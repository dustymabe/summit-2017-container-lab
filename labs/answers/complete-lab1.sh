#!/bin/bash
#execute the functionality in lab1 that other labs depend on 
set -eux

cd ~/labs/lab1

docker build -t redhat/apache .
docker run -dt -p 80:80 --name apache redhat/apache
docker exec apache yum -y install iproute
docker rm -f apache

docker build -t registry registry/
docker run --restart="always" --name registry -p 5000:5000 -d registry
