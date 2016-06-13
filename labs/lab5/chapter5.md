# LAB 5: Packaging an Atomic App -- Bonus

In this lab we walk through packaging an application into a single deployment 
unit. This is called an Atomic App and is based on the 
[Nulecule specification](https://github.com/projectatomic/nulecule/).

So far in the previous labs we have:

1. Decomposed an application into services
1. Created docker images and pushed them to a registry
1. Created kubernetes files to orchestrate the running of the containers

In a production environment we still have several problems:

1. How do we manage the orchestration files?
1. How do we manage changing parameters to reflect the deployment target?
1. How can we re-use common services such as a database so we don't have 
   to re-write them every time?
1. How can we support different deployment targets (docker, kubernetes, 
   openshift, etc) managed by a single deployment unit?

## Terms

* **Nulecule**: Nulecule is a specification that defines a pattern and model 
                for packaging complex multi-container applications, referencing 
                all their dependencies, including orchestration metadata in a 
                container image for building, deploying, monitoring, and active 
                management.
* **Atomic app**: An implementation of the Nulecule specification. Atomic App
                  supports running applications packaged as a Nulecule.
* **Provider**: Plugin interface for specific deployment platform, an orchestration provider
* **Artifacts**: Provider files
* **Graph**: Declarative representation of dependencies in the context of a
             multi-container Nulecule application

This lab should be performed on **rhel-cdk.example.com** unless otherwise instructed.

## Packaging Wordpress

In this section we will look at how to package our Wordpress application as an 
Atomic App. To demonstrate the composite nature of Atomic Apps we will
use a pre-made Atomic App for the database part of the Wordpress Atomic App.
In this use case a partnering software vendor might provide an Atomic App 
that is certified on Red Hat platforms. The Wordpress application will 
reference and connect to the certified Atomic app database service.

In a disconnected lab environment the database Atomic App we will be
using will be hosted in the lab environment. 

In a non-disconnected environment we will pull a database Atomic App 
from the upstream Atomic App Nulecule Library.

### The Nulecule file

* Create a directory and copy the Nulecule template files into place.

```
mkdir -p ~/workspace/nulecule/
cp -R ~/labs/lab5/* ~/workspace/nulecule/
```

* Open the Nulecule file for the wordpress Atomic App in a text editor.

```
vi ~/workspace/nulecule/wordpress-atomicapp/Nulecule
```

The file is reproduced here for convenience:

```
---
specversion: 0.0.2
id: summit-2016-wp
metadata:
  name: Wordpress
  appversion: v1.0.0
  description: >
    WordPress is web software you can use to create a beautiful
    website or blog. We like to say that WordPress is both free
    and priceless at the same time.
graph:
  - name: mariadb
#   source: "docker://projectatomic/mariadb-centos7-atomicapp"
#   source: "docker://mariadb-rhel7-atomicapp"
  - name: wordpress
    artifacts:
      openshift:
        - file://artifacts/openshift/wordpress-pod.yaml
        - file://artifacts/openshift/wordpress-service.yaml
    params:
      - name: image
        description: wordpress docker image
        default: rhel-cdk.example.com:5000/wordpress
      - name: db_user
        description: wordpress database username
      - name: db_pass
        description: wordpress database password
      - name: db_name
        description: wordpress database name
```

There are two primary sections: metadata 
and graph. The graph is a list of components to deploy, like the database 
and wordpress services in our lab. The artifacts are a list of provider 
files to deploy. In this lab we have one provider, OpenShift, and the 
provider artifact files are the service and pod YAML files. The params 
section defines the parameters that may be changed when the application 
is deployed.


* Inspect the file. The graph specifies the different elements 
  of the Atomic App:

```
graph:
  - name: mariadb
#   source: "docker://projectatomic/mariadb-centos7-atomicapp"
#   source: "docker://mariadb-rhel7-atomicapp"
  - name: wordpress
```

Above you can see there is a ```mariadb``` part of the application
as well as a ```wordpress``` part of the application. We have elected to
pull a database that someone else has packaged for us. In the file
we have two lines commented out. You can easily choose which one you
should use based on if you are in a lab setting (disconnected), or if
you are in a non-lab (connected to internet) setting.

If you are in a lab, delete the ```docker://projectatomic/mariadb-centos7-atomicapp```
and uncomment the ```docker://mariadb-rhel7-atomicapp``` line.

If you are following along at home delete the ```docker://mariadb-rhel7-atomicapp```
and uncomment the ```docker://projectatomic/mariadb-centos7-atomicapp``` line.

* Inspect the artifacts that are to be packaged in the Nulecule:

```
  - name: wordpress
    artifacts:
      openshift:
        - file://artifacts/openshift/wordpress-pod.yaml
        - file://artifacts/openshift/wordpress-service.yaml
```

These are the artifacts that we be sent to the provider to create the
application.

What are the contents of these files? Very similar to the content from 
lab4. Let's look at the ```wordpress-pod.yaml``` for example:

```
apiVersion: v1
kind: Pod
metadata:
  name: wordpress
  labels:
    name: wordpress
spec:
  containers:
  - name: wordpress
    image: $image
    ports:
      - containerPort: 80
    env:
      - name: DB_ENV_DBUSER
        value: $db_user 
      - name: DB_ENV_DBPASS
        value: $db_pass
      - name: DB_ENV_DBNAME
        value: $db_name
```


Wait. Something is different. What are those ```$image```, ```$db_user```, 
```$db_pass```, ```$db_name``` variables? Those are actually
parameters that correspond to the ```params``` section of the
Nulecule file. We'll check that out below.

* Inspect the parameters in the Nulecule:

```
    params:
      - name: image
        description: wordpress docker image
        default: rhel-cdk.example.com:5000/wordpress
      - name: db_user
        description: wordpress database username
      - name: db_pass
        description: wordpress database password
      - name: db_name
        description: wordpress database name
```

You'll see that these parameters correspond directly to the variables
within the ```wordpress-pod.yaml``` file. These are values that can be
easily changed by the user at deployment time by providing answers to
questions. You'll notice that we have pre-populated the default image
to be our wordpress application we already pushed to the registry in lab3.


* Save and close the Nulecule file.

As a final step, save the file and close it.


## Building the Atomic App

Before we test our work let's switch back to the OpenShift running on
the CDK.

```bash
oc login --insecure-skip-tls-verify=true -u openshift-dev -p devel localhost:8443
```

And let's delete the project we were using and recreate it so we get a
fresh playground:

```bash
oc delete project sample-project
oc new-project sample-project
```

Now we'll deploy Wordpress as an Atomic app.

We will run the atomic app base container image where the `Nulecule` file 
is in `~/workspace`.

```
cd ~/workspace/nulecule/wordpress-atomicapp/
```

Inspect the Atomic app base container image. Notice how the `RUN` LABEL 
mounts in the current working directory with the `-v ${PWD}:/atomicapp` option. 
This allows for the files in the current directory to be used by atomicapp.

```
docker pull devstudio/atomicapp:0.5.0
sudo atomic info devstudio/atomicapp:0.5.0
```

Generate an answers file for the Atomic App

```
sudo -E atomic run devstudio/atomicapp:0.5.0 --mode genanswers ./
```

Edit the `answers.conf` file to populate variables as well as point Atomic
App at the appropriate OpenShift instance. The contents should look
something like this:

```
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
```

Run the Atomic app. This will look at the files that we just created in the 
current directory and bring up the application in Openshift

```
sudo -E atomic run devstudio/atomicapp:0.5.0 ./
```

The MariaDB Atomic App will be downloaded. Since it is a remote source the MariaDB 
Atomic App files are placed in directory `external`. Once complete, the wordpress 
and mariadb pods and services should be deployed to OpenShift.

Check the deployment progress in the same way we did in lab 4.

```bash
oc get pods
oc get services
```

Finally, expose the wordpress service again and then test out the connection:

```bash
oc expose svc/wordpress
curl -L wordpress-sample-project.rhel-cdk.10.1.2.2.xip.io
```

## Build

So we just used `atomicapp` to start containers/services using files from a local 
working directory. Now let's build a container with those files that we can distribute 
to others to use. 

Notice one of the files in the wordpress-atomicapp directory is a `Dockerfile`. It has
these contents:

```
FROM devstudio/atomicapp:0.5.0

MAINTAINER Student <student@foo.io>

ADD /Nulecule /Dockerfile /application-entity/
ADD /artifacts /application-entity/artifacts
```

Building this Dockerfile yields a container that has the `Nulecule` and `artifacts` that 
we just created. This new container will also be layered on top of 
`projectatomic/atomicapp:0.5.0` so it automatically contains the atomicapp software. 
This *Atomic App* we are creating is a self-executing metadata container. This way there 
is no "out of band" metadata mangement channel: everything is a container.

To build the Atomic App you simply use the `docker build` command.

```bash
docker build -t wordpress-rhel7-atomicapp ./
```

At this point the `wordpress-rhel7-atomicapp` container image may be distributed across 
a datacenter or around the world as a single deployment unit. We can pretend that we are
uploading it for it to be used by others by pushing it to our registry now:

```bash
docker tag wordpress-rhel7-atomicapp rhel-cdk.example.com:5000/wordpress-rhel7-atomicapp 
docker push rhel-cdk.example.com:5000/wordpress-rhel7-atomicapp
```

Now others could run this application with a simple:

```bash
sudo -E atomic run rhel-cdk.example.com:5000/wordpress-rhel7-atomicapp
```

