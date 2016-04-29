#!/bin/bash
#execute the functionality in lab2 that other labs depend on 

cd ~/lab4

echo "make sure your /etc/hosts file has the two servers listed"

TARGET_IP='dev.example.com:5000'

cp -R ~/lab4/* ~/workspace

sed -i -e "s/YOUR_LAB_DEV_MACHINE/$TARGET_IP\/wordpress/g" ~/workspace/wordpress/kubernetes/wordpress-pod.yaml
sed -i -e "s/YOUR_LAB_DEV_MACHINE/$TARGET_IP\/mariadb/g" ~/workspace/mariadb/kubernetes/mariadb-pod.yaml 

mkdir ~/.kube
touch ~/.kube/.kubeconfig

kubectl config set-cluster local --server=http://localhost:8080
kubectl config set-context local-context --cluster=local
kubectl config use-context local-context

kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-pod.yaml &&  kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-service.yaml 
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-pod.yaml && kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-rc.yaml && kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-service.yaml 
  
kubectl config set-cluster remote --server=summit_rhel_deploy_target:8080 
kubectl config set-context remote-context --cluster=remote
kubectl config use-context remote-context

kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-pod.yaml &&  kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-service.yaml 
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-pod.yaml && kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-rc.yaml && kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-service.yaml 

