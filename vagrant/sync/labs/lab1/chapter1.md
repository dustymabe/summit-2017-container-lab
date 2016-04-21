## LAB 1: Docker refresh

In this lab we will explore the docker environment. If you are familiar with docker this may function as a brief refresher. If you are new to docker this will serve as an introduction to docker basics.  Don't worry, we will progress rapidly.  To get through this lab, we are going to focus on the environment itself as well as walk through some exercises with a couple of Docker images / containers to tell a complete story and point out some things that you might have to consider when containerizing your application.

This lab should be performed on dev.example.com unless otherwise instructed.  

Username: root
Password: redhat

Expected completion: 15-20 minutes

Agenda:

* Review Docker and systemd
* Review Docker help
* Explore a Dockerfile
* Build an image
* Launch a container
* Inspect a container
* Build Docker registry


###Docker and systemd

* Check out the systemd unit file that starts Docker on our host and notice that it includes 3 EnvironmentFiles.  These files tell Docker how the Docker daemon, storage and networking should be set up and configured.  Take a look at those files too.  Specifically, in the /etc/sysconfig/docker check out the registry settings.  You may find it interesting that you can `ADD_REGISTRY` and `BLOCK_REGISTRY`.  Think about the different use cases for that.

Perform the following commands as root unless instructed otherwise.

```
cat /usr/lib/systemd/system/docker.service
cat /etc/sysconfig/docker
cat /etc/sysconfig/docker-storage
cat /etc/sysconfig/docker-network
```

* Now start Docker, or make sure that it is started before moving forward.

```
systemctl start docker
systemctl status docker
```

###Docker Help

* Now that we see how the Docker startup process works, we should make sure we know how to get help when we need it.  Run the following commands to get familiar with what is included in the Docker package as well as what is provided in the man pages.  Spend some time exploring here, it's helpful.  When you run `docker info` check out the storage configuration.  You will notice that by default it is using *device mapper loopback*.  This can and should be changed to *device mapper direct LVM*.  Performance and stability will be improved.  See the storage section on the [RHEL Atomic Getting Started Guide.](https://access.redhat.com/articles/rhel-atomic-getting-started#storage) 

Check out the executables provided:

```
rpm -ql docker | grep bin
```

Check out the configuration files that are provided:

```
rpm -qc docker
```

Check out the documentation that is provided:

```
rpm -qd docker
docker --help
docker run --help
docker info
```

* Take a look at the Docker images on the system.  These images have been cached here ahead of time. You should see some RHEL images.
  
```
docker images
```

###Let's explore a Dockerfile

Here we are just going to explore a simple Dockerfile.  The purpose for this is to have a look at some of the basic commands that are used to construct a Docker image.  For this lab, we will explore a basic Apache Dockerfile and then confirm functionality.

* As root, change directory to `~/lab1/` and `cat` out the Dockerfile

```
cd ~/lab1
cat Dockerfile
FROM registry.access.redhat.com/rhel:7.1-6
MAINTAINER Student <student@foo.io>

ADD ./local.repo /etc/yum.repos.d/local.repo
ADD ./hosts /new-hosts
RUN cat /new-hosts >> /etc/hosts && yum -y update && yum clean all
RUN cat /new-hosts >> /etc/hosts && yum -y install httpd && yum clean all
RUN echo "Apache" >> /var/www/html/index.html
RUN echo 'PS1="[apache]#  "' > /etc/profile.d/ps1.sh

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart 
ADD run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

CMD ["/run-apache.sh"]
```

Here you can see in the `FROM` command that we are pulling a RHEL 7.1 base image that we are going to build on.  We are also using a local yum repo that is local to this environment.  We are doing this because we are in a disconnected lab environment.  However, the way RHEL images normally get access to content is by inheriting the subscriptions that are on the host they are running on.  Next we update the container and install `httpd`.  You will notice here that we have an additional command `cat /new-hosts >> /etc/hosts`. The reason for this is simply to provide name resolution.  Why do we do it on two lines?  Well, we have to make the change for each layer.  Finally, we modify the index.html file, `EXPOSE` port 80 which allows traffic into the container and start the container with a a `CMD` of `run-apache.sh`.  


## Build an Image

* Now that we have taken a look at the Dockerfile, let's build this image.

```
docker build -t redhat/apache .
```

## Run the Container


* Next, let's run the image and make sure it started.

```
docker run -dt -p 80:80 --net=host --name apache redhat/apache
docker ps
```

Here we are using a few switches to configure the running container the way we want it.  We are running a `-dt` to run in detached mode with a psuedo TTY.  Next we are mapping a port from the host to the contianer.  We are being explicit here.  We are telling Docker to map port 80 on the host to port 80 in the container.  Now, we could have let Docker handle the host side port mapping dynamically by passing a `-p 80`, in which case Docker would have randomly assigned a port to the container.  You can find that by doing a `docker ps` and see what port got assigned.  Finally we passed in the name of the image that we built earlier.


* OKay, let's make sure we can access the web server.

```
curl http://localhost
Apache
```

* Now that we have built an image, launched a container and confirmed that it is running, lets do some further inspection of the container.  We should take a look at the container IP address.  Let's use `docker inspect` to do that.

## Time to Inspect

```
docker inspect apache
```

We can see that this gives us quite a bit of information in json format.  We can scroll around and find the IP address, it will be towards the bottom.  

* Let's be more explicit with our `docker inspect`

```
docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache
```

Why don't we get an IP address?  The reason is, because we used the --net=host option.  The container is sharing an interface with the host.

We can apply the same filter to any value in the json output.  Try a few different ones.

* Now lets look inside the container and see what that environment looks like.  We first need to get the PID of the container so we can attach to the PID namespace with nsenter.  After we have the PID, go ahead and enter the namespaces of the container substituting the PID on your container for the one listed below.  Take a look at the man page to understand all the flags we are passing to nsenter.

```
docker inspect --format '{{ .State.Pid }}' apache
15492

man nsenter
nsenter -m -u -n -i -p -t 15492

```

* Now run some commands and explore the environment.  Remember, we are in a slimmed down container at this point - this is by design.  You may find yourself restricted.


```
ps aux
ip a
ifconfig
ls /bin
cat /etc/hosts
```

Well, what can we do?  You can install software into this container.

```
yum -y install iproute
ip a
```

Exit the container namespace with `CTRL+d` or `exit`.

In addition to using `nsenter` to enter the namespace of your container, you can also execute commands in that namespace with `docker exec`.  

```
docker exec apache pwd
```

Whew, so we do have some options.  Now, remember that this lab is all about containerizing your existing apps.  You will need some of the tools listed above to go through the process of containerizing your apps. Troubleshooting problems when you are in a container is going to be something that you get very familiar with.

### Deploy a Container Registry

To prepare for the next lab let's deploy a simple registry to store our images.

1. Inspect the Dockerfile that has been prepared. Notice the defaults that have been chosen. These may be overriden.

        cat registry/Dockerfile

1. Build the registry

        docker build -t registry registry/

1. Run the registry in daemonized mode using default parameters. However, we want to make sure this container always comes back on docker restarts or machine reboots. As a result, we include ```--restart="always"```.

        docker run  --restart="always" --name registry -p 5000:5000 -d registry

1. Confirm the registry is running.

        docker ps

In the next lab we will be pushing our work to this registry. Before we can do so we need to configure the docker client to connect to the registry insecurely since we do not have a CA-signed certificate.

1. Edit `/etc/sysconfig/docker`
1. Find the line in the file that has INSECURE_REGISTRY and make the following change.  We are telling Docker that it is safe to use this registry.

         INSECURE_REGISTRY='--insecure-registry dev.example.com:5000'

1. Save, exit and restart docker daemon

        systemctl restart docker

