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

This time, let's simplify things by deploying an application template.  We've already included a template w/ lab5 which leverages our wordpress & mariadb images.
```shell
$ cd ~/summit-2017-container-lab/labs/lab5/
$ grep -i cdk.example.com wordpress-template.yaml
```

Let's deploy this wordpress template:
```shell
# add your template to the production project
$ oc create -f wordpress-template.yaml
template "wordpress" created

# deploy your new template w/ "oc new-app" and note its output
$ oc new-app --template wordpress
--> Deploying template "production/wordpress" to project production
```

Watch all of the newly created resources until the pods are in "Running" status... ctrl-c to exit
```shell
$ watch -n 5 oc get all
NAME                   READY     STATUS    RESTARTS   AGE
po/mariadb-1-nujmr     1/1	 Running   0          2m
po/wordpress-1-pz9fu   1/1	 Running   0          2m

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

OpenShift includes several ready-made templates. Let's take a look at some of them:
```shell
$ oc get templates -n openshift
```

For more information on templates, reference the official OpenShift documentation:
https://docs.openshift.com/container-platform/latest/dev_guide/templates.html
https://docs.openshift.com/container-platform/latest/install_config/imagestreams_templates.html#is-templates-subscriptions