# LAB 5: OpenShift templates and web console

In this lab we introduce how to simplify your container deployments w/ OpenShift templates.  We will also explore the web console.

This lab should be performed on **workstation.example.com** unless otherwise instructed.

Expected completion: 20 minutes

## Project preparation

We should still be in our "production" project space at this point.
```shell
$ oc project
Using project "production" on server "https://atomic-host.example.com:8443".
```

Ensure you're still logged in as the developer user & clean up the resources deployed in chapter 4.
```shell
$ oc whoami
developer

$ oc delete all --all
```

Ensure the following command displays "No resources found" before proceeding.
```shell
$ oc get all
No resources found.
```

## Wordpress templated deployment

This time, let's simplify our deployment by creating an application template.

Deploy the wordpress template file included w/ lab5:
```shell
$ cd ~/summit-2017-container-lab/labs/lab5/

# add your template to the production project
$ oc create -f wordpress-template.yaml
template "wordpress" created

# deploy your new template w/ "oc new-app" and notice its output
$ oc new-app --template wordpress
--> Deploying template "production/wordpress" to project production

     * With parameters:
        * MariaDB User=user
        * MariaDB Password=df7mjvdXeccV # generated
        * MariaDB Database Name=mydb

# view all of the newly created resources
$ oc get all

# wait for the database to start... ctrl-c when done.
$ oc logs -f dc/mariadb
mysqld_safe Starting mysqld daemon with databases from /var/lib/mysql

# wait for wordpress to start... ctrl-c when done.
$ oc logs -f dc/wordpress
/usr/sbin/httpd -D FOREGROUND

# oc status gives a nice view of how these resources connect
$ oc status
```

Check and make sure you can access the wordpress service through it's route:
```bash
$ curl -L http://wordpress-production.atomic-host.example.com
or
point your browser to the URL to view the GUI
```

Minishift includes several other ready-made templates. Let's take a look:
```shell
$ oc get templates -n openshift
```
