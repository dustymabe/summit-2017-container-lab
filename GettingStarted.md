## Introduction

In order to make this lab as simple to work with as possible, we are leveraging a tool called [Vagrant](https://www.vagrantup.com/) which simplifies the creation and management of virtual machines (VM), particularly during development. We also hope that implementing the lab in Vagrant means that people will be able to follow the lab in a self-paced fashion after [Red Hat Summit](https://www.redhat.com/en/summit) (but, it would be more fun to see you at the conference :) ).

If you are unfamiliar with Vagrant, that is OK, as we will cover the basics here. However, if you get the time you should really look in to it more deeply as it is very powerful and we are just scratching the surface.

Ok, to get started, on Enterprise Linux systems like Red Hat Enterprise Linux and CentOS, Vagrant is delivered as a [software collection](https://www.softwarecollections.org/en/docs/) which is a alternate packaging technique that allows for independent versions of components. Specifically, this collection allows Vagrant to choose the version of Ruby and Ruby libraries that it prefers even if they are not the versions provided by the distribution. Again, we will be covering the basics of how to use a software collection (often referred to as an "scl" for short) for the purposes of this lab but you should definitely investigate them more as software collections are also quite powerful.

Finally, one last thing to introduce, the Container Development Kit (CDK). The CDK is a prebuilt Vagrant VM with RHEL installed and some tools for working with containers, namely, docker, kubernetes, and openshift. Again, we will briefly discuss the CDK here, but you should definitely [dig in more](http://developers.redhat.com/products/cdk/) as you have time.

## Getting Vagrant and the CDK

If you are attending the lab, you can skip this step and move directly to [Get Lab Materials](#get-materials) as the steps have already been performed on the machine you are using.

You will probably find it easiest to head over to developers.redhat.com and follow the "[install the Container Development Kit](http://developers.redhat.com/products/cdk/get-started/)" instructions. The instructions cover installing Vagrant and the Container Development Kit on Windows, MacOS, and Linux. 

## <a name="#get-materials"></a>Get Lab Materials

For the convience of users of the lab, we created a script and installed it on the Lab VM. If you are in the lab, please run the following:

```bash
$ /usr/local/bin/getlab 
Cloning into 'summit-2016-container-lab'...
remote: Counting objects: 478, done.
remote: Total 478 (delta 0), reused 0 (delta 0), pack-reused 478
Receiving objects: 100% (478/478), 13.66 MiB | 11.76 MiB/s, done.
Resolving deltas: 100% (214/214), done.
```

For those of you following along at home, just git clone the repo you found this file in:

```bash
$ git clone https://github.com/dustymabe/summit-2016-container-lab
```

Now change into that directory:

```bash
$ cd summit-2016-container-lab
```

## <a name="#vagrant-walkthrough"></a>Vagrant Walkthrough

First off, enable the Vagrant Software Collection:

```bash
$ scl enable sclo-vagrant1 bash
```

Ok, so now you have Vagrant. Make sure by asking for the version (1.8.1 at time of writing):

```bash
$ vagrant --version
Vagrant 1.8.1
```

Your major units of operation with Vagrant are `vagrant up`, `vagrant ssh`, `vagrant halt`, and, to a lesser extent, `vagrant destroy`. We will, quickly, walk through these. All of these operations and almost every other Vagrant command, use a "per project configuration file" called a Vagrantfile to define the details of one or more virtual machines that you are using in your project. A detailed explanation of a Vagrantfile and all the magic you can do with it is well beyond the scope of this lab, but you can find out more details in the [documentation](https://www.vagrantup.com/docs/vagrantfile/).


First up, `vagrant up`: this command asks your hypervisor to launch the virtual machine described in the Vagrantfile. The operation may be a "create and launch VM" or a "re-launch an existing VM" and it is largely transparent to the user. 
 
OK, so, let's move in to a directory with a Vagrantfile and then launch the VM:

```bash
$ cd vagrantcdk
$ vagrant up
-- results removed for brevity --
```

You should get a lot of feedback about the launch of the VM but, if you are using the lab VM or have run this before, you will get a lot less feedback. As long as you don't get errors (delineated, normally, by red font) you are in good shape.

OK, so now you have a running VM, in our case, we are using integration with libvirt to provide our hypervisor to Vagrant. As a result, we can query `virsh` to prove it.

```bash
$ sudo virsh list
 Id    Name                           State
----------------------------------------------------
 2     vagrantRepoHost_default        running
 3     vagrantcdk_default             running

```

Now we can actually step inside the machine (ignoring the vagrantRepoHost_default which is just a helper VM for the lab) with:

```bash
$ vagrant ssh
[vagrant@rhel-cdk ~]$ 
```

Now take a look at `ip addr` and see we are on our own subnet `192.168.121.0/24` with an IP of, probably, `192.168.121.36`. 

```bash
[vagrant@rhel-cdk ~]$ ip addr
<snip />
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:67:ac:df brd ff:ff:ff:ff:ff:ff
    inet 192.168.121.36/24 brd 192.168.121.255 scope global dynamic eth0
       valid_lft 3452sec preferred_lft 3452sec
    inet6 fe80::5054:ff:fe67:acdf/64 scope link 
       valid_lft forever preferred_lft forever
<snip />
```

We can further verify if we `exit` the VM and do the same thing locally. Mostly we are just verifying that it is not only not the same IP but also not even the same subnet:

```bash
[vagrant@rhel-cdk ~]$ exit
logout
Connection to 192.168.121.36 closed.
$ ip addr
<snip />
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:46:90:e2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.124.23/24 brd 192.168.124.255 scope global dynamic eth0
       valid_lft 2025sec preferred_lft 2025sec
    inet6 fe80::5054:ff:fe46:90e2/64 scope link 
       valid_lft forever preferred_lft forever
<snip />
```

## Container Development Kit (CDK) Walkthrough

The cool thing is, we actually launched the CDK VM by launching the above Vagrantfile. The CDK gives a couple options (through the use of [different Vagrantfiles](https://developers.redhat.com/download-manager/file/cdk-2.0.0.zip)) but in this case, we launched the "OpenShift in a Box" VM (aka rhel-ose in the cdk.zip). The CDK provides a simple to use and launch instance of the same OpenShift PaaS you would use at work. Why is a PaaS included in a product, much less a lab, focused on Containers? Well, the latest version of OpenShift, actually runs Docker Containers to host your "Platform" (in the PaaS sense) and your application.

If you would like to explore the OpenShift Console, you can see it running in your OpenShift instance, if you open a browser. Let's go ahead and try it. Open Firefox from the Applications menu and navigate to `https://10.1.2.2:8443/console/`. Once it loads (and you bypass the bad certificate error), you can log in to the console using the default `admin/admin` or to see the less privileged experience, use `openshift-dev/devel` for the `username/password`.

## Back to Vagrant Walkthrough

Now let's wrap this up by shutting down the VM. However, we don't want to completely remove the VM just "turn it off." In order to do this we execute `vagrant halt` which will shut the machine down and have it stop using our resources. One more note, you can also use `vagrant destroy` when you are completely done with a Vagrant VM which will not only shut it down but completely wipe out the VM. So, useful when a project is getting mothballed or, in this case, useful if you get in to a bad state in the lab and want to just give up and start again.

OK, so, let's get ready for the rest of the lab by halting and moving back to our home directory:

```bash
$ vagrant halt
==> default: Halting domain...
Connection to 192.168.121.36 closed by remote host.
$ cd ~/
[student@labvm ~]$
```

 
