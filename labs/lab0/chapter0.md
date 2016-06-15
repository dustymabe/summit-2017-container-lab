## Introduction

In order to make this lab simple to work with, we are going to leverage
a tool known as the Container Development Kit (CDK). The CDK is a prebuilt 
Vagrant VM with RHEL installed. The VM also has all the tools you need for
building and developing software with containers. The included
software includes docker, kubernetes and, optionally, OpenShift. 

By leveraging [Vagrant](https://www.vagrantup.com/) the CDK gives us a reliable, 
reproducible environment to iterate on. If you are unfamiliar with Vagrant, 
that is OK, as we will cover the basics here. However, if you get the time you 
should really look in to it more deeply as it is very powerful and we are just 
scratching the surface.

Unfortunately, we are just briefly discussing the CDK here. You should definitely 
[dig in more](http://developers.redhat.com/products/cdk/) as you have time.
The CDK is a free download for registered users, and gives you access to
many tools in the Red Hat container ecosystem.

## Getting Vagrant and the CDK

**NOTE** If you are attending a lab in person, you can skip this step
         and move directly to [Get Lab Materials](#get-lab-materials) as 
         the steps have already been performed on the machine you are using.

In order to get the CDK, the easiest way is to head over to developers.redhat.com 
and follow the "[install the Container Development Kit](http://developers.redhat.com/products/cdk/get-started/)" 
instructions. The instructions cover installing Vagrant and the CDK on Windows, 
MacOS, and Linux. 

## Get Lab Materials

For the convience of users of the lab, we created a script and installed it on the Lab VM. If you are in the lab, please run the following:

```bash
$ cd ~/
$ /usr/local/bin/getlab 
Cloning into 'summit-2016-container-lab'...
remote: Counting objects: 478, done.
remote: Total 478 (delta 0), reused 0 (delta 0), pack-reused 478
Receiving objects: 100% (478/478), 13.66 MiB | 11.76 MiB/s, done.
Resolving deltas: 100% (214/214), done.
```

For those of you following along at home, just `git clone` the repo you 
found this file in:

```bash
$ cd ~/
$ git clone https://github.com/dustymabe/summit-2016-container-lab
```

## Vagrant Walkthrough

First off, only if you are on a CentOS or RHEL host, enable the Vagrant Software Collection:

```bash
$ scl enable sclo-vagrant1 bash
```

Ok, so now you have Vagrant. Make sure by asking for the version (1.8.1 at time of writing):

```bash
$ vagrant --version
Vagrant 1.8.1
```

Your major units of operation with Vagrant are `vagrant up`, `vagrant ssh`, 
`vagrant halt`, and `vagrant destroy`. We will, quickly, walk through these. 
All of these operations, and almost every other Vagrant command, use a "per 
project configuration file" called a `Vagrantfile` to define the details of 
one or more virtual machines that you are using in your project. A detailed 
explanation of a Vagrantfile and all the magic you can do with it is well 
beyond the scope of this lab, but you can find out more details in the 
[documentation](https://www.vagrantup.com/docs/vagrantfile/).


First, `vagrant up`: this command asks your hypervisor to launch the virtual 
machine described in the Vagrantfile. The operation may be a "create and launch 
VM" or a "re-launch an existing VM" and it is largely transparent to the user. 
 
OK, so, let's move in to a directory with a Vagrantfile and then launch the VM:

```bash
$ cd ~/summit-2016-container-lab/vagrantcdk
$ vagrant up
```

You should get a lot of feedback about the launch of the VM but, if you are using the lab VM or have run this before, you will get a lot less. As long as you don't get errors (delineated, normally, by red font) you are in good shape.

OK, so now you have a running VM. Ask vagrant to tell us the status:

```bash
$ vagrant status
Current machine states:

default                   running (libvirt)

The Libvirt domain is running. To stop this machine, you can run
`vagrant halt`. To destroy the machine, you can run `vagrant destroy`.
```

Now we can actually step inside the machine with:

```bash
$ vagrant ssh
[vagrant@rhel-cdk ~]$ 
```

Now take a look at `ip -4 -o addr` and see what IPs we have: 

```bash
[vagrant@rhel-cdk ~]$ ip -4 -o addr
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
2: eth0    inet 192.168.121.170/24 brd 192.168.121.255 scope global dynamic eth0\       valid_lft 3430sec preferred_lft 3430sec
3: eth1    inet 10.1.2.2/24 brd 10.1.2.255 scope global eth1\       valid_lft forever preferred_lft forever
4: docker0    inet 172.17.0.1/16 scope global docker0\       valid_lft forever preferred_lft forever
```

The `10.1.2.2` address is the one we set in the `Vagrantfile`. If you
peak in the file you'll see it set at the top in a variable: 
`PUBLIC_ADDRESS="10.1.2.2"`. We'll use the `10.1.2.2` address to
access the CDK in the next section.

Now exit out of the CDK VM by disconnecting from the SSH session:

```bash
$ exit
```

## Container Development Kit (CDK) Walkthrough

The cool thing is, we actually launched the CDK VM by executing `vagrant up` on
the Vagrantfile in the previous section. The CDK gives a couple options (through the use of 
[different Vagrantfiles](https://developers.redhat.com/download-manager/file/cdk-2.0.0.zip)) 
but in this case, we launched the "OpenShift in a Box" VM (aka rhel-ose in 
the cdk.zip). The CDK provides a simple to use and launch instance of the 
same OpenShift PaaS you would use at work. Why is a PaaS included in a product, 
much less a lab, focused on Containers? Well, the latest version of OpenShift, 
actually runs Docker Containers to host your "Platform" (in the PaaS sense) 
and your application.

If you would like to explore the OpenShift Console, you can see it running in your OpenShift instance, if you open a browser. Let's go ahead and try it. 

Open Firefox from the Applications menu and navigate to `https://10.1.2.2:8443/console/`. Once it loads (and you bypass the bad certificate error), you can log in to the console using the default `admin/admin` or to see the less privileged experience, use `openshift-dev/devel` for the `username/password`.

## Setting Up For the Remaining Labs

Let's wrap up the walkthroughs by getting rid of the VM we just
started. We can do this with a `vagrant destroy` command, which will
not only shut down a VM, but also remove it completely. Any contents
of the VM disk images will be lost:

```bash
$ cd ~/summit-2016-container-lab/vagrantcdk
$ vagrant destroy
==> default: Removing domain...
```

And to set up for the next lab sections we'll go ahead and bring up
two Vagrant VMs. One of them is still the CDK, but with a customized
`Vagrantfile` for this lab. This box will be known as **rhel-cdk.example.com** 
for the purposes of this lab and will have the IP address `10.1.2.2`.

```bash
$ cd ~/summit-2016-container-lab/vagrantcdklab
$ vagrant up
```

The other one is a Red Hat Enterprise Linux Atomic Host Vagrant box, 
that has a Vagrantfile that will set up and run OpenShift during bringup.
This box will be known as **deploy.example.com** for the purposes of
this lab and will have the IP address `10.1.2.3`.

```bash
$ cd ~/summit-2016-container-lab/vagrantAtomicCluster
$ vagrant up
```

After you bring up each machine you are then ready to move on to lab 1.
