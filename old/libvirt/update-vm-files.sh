#!/bin/bash

#check to be sure the dir to store connections exists
if ! test ~/.ssh/ctl ; then
    mkdir ~/.ssh/ctl
fi

SCRIPT_PATH=$(dirname $0)

SERVER=deploy.example.com
#"host" doesn't use /etc/hosts so we have to use this semi-esoteric method
if ! getent hosts $SERVER > /dev/null 2>&1 ; then
    echo "$SERVER doesn't resolve, this won't work"
    exit 1
fi
if ping $SERVER -c 1 > /dev/null 2>&1 ; then 
    #create a connection to share amongst all the rsync calls so you don't get reprompted for password
    ssh -nNf -M -S "$HOME/.ssh/ctl/%L-%r@%h:%p" root@$SERVER
    for i in `seq 1 5` ; do
  	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/answer/* root@$SERVER:/root/answers/
	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/support/* root@$SERVER:/root/lab$i/
	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/chapter*md root@$SERVER:/root/markdown_lab_docs/
    done
    #kill the connection
    ssh -O exit -S "$HOME/.ssh/ctl/%L-%r@%h:%p" root@$SERVER
else
    echo "Skipped $SERVER as it is un-ping-able."
fi
  
SERVER=dev.example.com
#"host" doesn't use /etc/hosts so we have to use this semi-esoteric method
if ! getent hosts $SERVER > /dev/null 2>&1 ; then
    echo "$SERVER doesn't resolve, this won't work"
    exit 1
fi
if ping $SERVER -c 1 > /dev/null 2>&1 ; then 
    #create a connection to share amongst all the rsync calls so you don't get reprompted for password
    ssh -nNf -M -S "$HOME/.ssh/ctl/%L-%r@%h:%p" root@$SERVER
    #copy over the local.repo file
    rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/../shared-files/local.repo root@$SERVER:/etc/yum.repos.d/
    #build the mariadb atomicapp
    ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p' root@$SERVER "docker build -t mariadb-atomicapp /root/lab5/mariadb/."
    for i in `seq 1 5` ; do
	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/answer/* root@$SERVER:/root/answers/
	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/support/* root@$SERVER:/root/lab$i/
	rsync -e "ssh -S '$HOME/.ssh/ctl/%L-%r@%h:%p'" -avzP $SCRIPT_PATH/labs/lab$i/chapter*md root@$SERVER:/root/markdown_lab_docs/
    done
    #kill the connection
    ssh -O exit -S "$HOME/.ssh/ctl/%L-%r@%h:%p" root@$SERVER
else
    echo "Skipped $SERVER as it is un-ping-able."
fi
