#!/bin/bash
#execute the functionality in lab2 that other labs depend on 

cd ~/lab3

docker stop bigapp #a little safer then $(docker ps -ql)
docker rm bigapp #a little safer then $(docker ps -ql)

mkdir -p /var/lib/mariadb
mkdir -p /var/lib/wp_uploads
chcon -Rt svirt_sandbox_file_t /var/lib/mariadb
chcon -Rt svirt_sandbox_file_t /var/lib/wp_uploads

docker build -t mariadb -f mariadb/Dockerfile.reference mariadb/.
docker build -t wordpress -f wordpress/Dockerfile.reference wordpress/.

echo -e '\nLABEL RUN docker run -d -v /var/lib/mysql:/var/lib/mysql  --name NAME -e DBUSER=${DBUSER} -e DBPASS={$DBPASS} -e DBNAME=${DBNAME} -e NAME=NAME -e IMAGE=IMAGE IMAGE' >> mariadb/Dockerfile.reference

echo -e '\nLABEL RUN docker run -d -v /var/lib/wp_uploads:/var/www/html/wp-content/uploads -p 80:80 --link=mariadb:db --name NAME -e NAME=NAME -e IMAGE=IMAGE IMAGE' >> wordpress/Dockerfile.reference

docker build -t mariadb -f mariadb/Dockerfile.reference mariadb/.
docker build -t wordpress -f wordpress/Dockerfile.reference wordpress/.

#TARGET_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
TARGET_IP=summit-rhel-dev

docker tag -f mariadb $TARGET_IP:5000/mariadb
docker tag -f wordpress $TARGET_IP:5000/wordpress

docker push $TARGET_IP:5000/mariadb
docker push $TARGET_IP:5000/wordpress
