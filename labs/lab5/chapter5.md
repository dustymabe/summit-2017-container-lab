# LAB 5: OpenShift simplified app deployment

In this lab we introduce how to simplify your container deployments w/ OpenShift.

This lab should be performed on **workstation.example.com** unless otherwise instructed.

Expected completion: 20 minutes

## Project preparation

Let's switch back to our development OpenShift env
```shell
$ oc config use-context minishift
```

Ensure you're still logged in as the developer user & clean up our former development space.
```shell
$ oc whoami
developer

$ oc delete project devel --as=system:admin
project "devel" deleted
```

Ensure the following command displays "No resources found" before proceeding. It could take 10-30 seconds.
```shell
$ oc get project devel --as=system:admin
No resources found.
Error from server: namespaces "devel" not found
```

```shell
$ oc new-project devel
Now using project "devel" on server "https://192.168.xx.xxx:8443".
```

## MariaDB templated deployment

This time, let's save ourselves some work and avoid creating the MariaDB image, pod, or service.
OpenShift comes w/ many supported, templated deployments. Minishift packages a few of them for use.

Let's take a look:
```shell
$ oc get templates -n openshift
```

Deploy the included mariadb offering... it's a one-liner:
```shell
$ oc new-app --template=mariadb-ephemeral -p MYSQL_USER=user -p MYSQL_PASSWORD=mypass -p DATABASE_SERVICE_NAME=db
--> Creating resources ...
    service "db" created
    deploymentconfig "db" created
--> Success

# wait for the container to start
$ oc logs -f dc/db
--> Success
$ oc logs -f dc/db
[Note] /opt/rh/rh-mariadb101/root/usr/libexec/mysqld: ready for connections.
Version: '10.1.19-MariaDB'  socket: '/var/lib/mysql/mysql.sock'  port: 3306  MariaDB Server
```
## Wordpress deployment via 'oc new-app'

First, let's import our wordpress image from our registry:
```shell
$ oc import-image cdk.example.com:5000/wordpress --insecure=true --confirm
The import completed successfully.
```

Now, let's deploy our wordpress application, which  is configured via command-line to leverage our new DB instance.
```shell
$ oc new-app wordpress -e DB_ENV_DBUSER=user -e DB_ENV_DBPASS=mypass -e DB_ENV_DBNAME=sampledb
--> Creating resources ...
    deploymentconfig "wordpress" created
    service "wordpress" created
--> Success

# view the deploymentconfig which was auto-generated for you by OpenShift
$ oc describe dc/wordpress

# wait for the container to start
$ oc logs -f dc/wordpress
--> Success
$ oc logs -f dc/wordpress
+ /usr/sbin/httpd -D FOREGROUND

# create a route to the wordpress service
$ oc expose svc/wordpress

# view all of the resources in this project
$ oc get all

# oc status gives a nice view of how these resources connect
$ oc status
```

Check and make sure you can access the wordpress service through it's route:
```bash
$ curl -L wordpress-devel.cdk.example.com
or
point your browser to the URL to view the GUI
```
