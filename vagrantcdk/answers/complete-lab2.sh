#!/bin/bash
#execute the functionality in lab2 that other labs depend on 
set -eux

cd ~/labs/lab2/bigapp
docker build -t bigimg .
docker run -p 80 --name=bigapp -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb -d bigimg
