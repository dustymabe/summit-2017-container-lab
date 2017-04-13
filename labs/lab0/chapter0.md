## Introduction

In order to make this lab simple to work with, we are going to leverage
a product known as the Container Development Kit (CDK). The CDK leverages a tool called [minishift](https://github.com/minishift/minishift) to setup a RHEL VM with docker and OpenShift already installed. Optionally, you can register with your Red Hat Account and actually get updates to the VM as well. The CDK also includes documentation, getting started and howto guides, and a community of users to learn from.

The key feature of minishift is a reliable, reproducible environment to iterate on. If you are unfamiliar with minishift that is OK, as we will cover the basics here. 

Unfortunately, we are just briefly discussing the CDK here. You should definitely 
[dig in more](http://developers.redhat.com/products/cdk/) as you have time.
The CDK is a free download for registered users, and gives you access to
many tools in the Red Hat Container Ecosystem.

## Getting the CDK

**NOTE** If you are attending a lab in person, you can skip this step
         and move directly to [Get Lab Materials](#get-lab-materials) as 
         the steps have already been performed on the machine you are using.

In order to get the CDK, the easiest way is to head over to developers.redhat.com 
and follow the "[install the Container Development Kit](http://developers.redhat.com/products/cdk/get-started/)" 
instructions. The instructions cover installing the CDK on Windows, 
MacOS, and Linux. 

**NOTE** At the time of this writing, the CDK version we are using is CDK-3.0 
        which is still in beta so there are no installation docs as yet. 
        However, they should end up at the end of the URL above 

## Get Lab Materials

For the convience of users of the lab, we created a script and installed 
it on the Lab VM. If you are in the lab, please run the following:

```bash
$ cd ~/
$ /usr/local/bin/getlab 
Cloning into 'summit-2017-container-lab'...
remote: Counting objects: 727, done.
remote: Compressing objects: 100% (80/80), done.
remote: Total 727 (delta 21), reused 0 (delta 0), pack-reused 645
Receiving objects: 100% (727/727), 13.75 MiB | 2.08 MiB/s, done.
Resolving deltas: 100% (320/320), done.    
```

For those of you following along at home, just `git clone` the repo you 
found this file in:

```bash
$ cd ~/
$ git clone https://github.com/dustymabe/summit-2017-container-lab
```

## Minishift Walkthrough

Your major units of operation with minishift are `minishift start`, `minishift ssh`, 
`minishift docker-env`, and `minishift stop`. We will walk through these. 
Minishift has a number of other functions, some of which we will use later in the lab. However, these are the basics which warrant some examples to make sure you have enough context for the rest of the labs. We also need to get you access to the docker daemon running inside the minishift VM for the "docker Refresh" in Lab 1.  

First, `minishift start`: this command asks your hypervisor to launch the virtual 
machine minishift has prepared. The operation may be a "create and launch 
VM" or a "re-launch an existing VM" and it is largely transparent to the user. 
 
OK, so, let's move in to our project directory and then launch minishift:

```bash
$ cd ~/summit-2017-container-lab
$ minishift start --skip-registration
```

You should get a lot of feedback about the launch of the VM but, if you are 
using the lab VM or have run this before, you will get a lot less. As long 
as you don't get any errors you are in good shape.

OK, so now minishift is started which means docker and OpenShift are up and running. We can now ask for the status (it's succinct!):

```bash
$ minishift status
Running
```

Now we can actually step inside the machine with:

```bash
$ minishift ssh
Last login: Mon Feb 30 17:49:01 2017 from 192.168.??.??
[docker@minishift ~]$ 
```

You should very rarely need to jump inside the VM as most of the functions of docker and OpenShift can be done remotely. However, it can be really nice to know that you don't need to figure out the IP address or the username and password in case you have to get in there when something goes wrong. That said, most of the time the right answer is to just destroy the instance and recreate it.

Now exit out of the minishift VM by disconnecting from the SSH session:

```bash
$ exit
```

We have two more commands worth mentioning. First off, let's mention `minishift stop`. Stop does exactly what it sounds like and shuts down minishift. However, it does not destroy anything inside just "turns the machine off." If you do want to remove the VM, you can use `minishift delete`. You can spin it right back up again, fresh, with `minishift start`. Finally, we will use `minishift docker-env` in a few minutes to connect the host to the docker daemon in the VM.

## Container Development Kit (CDK) Walkthrough

When we started minishift, we launched the software tooling component of the CDK. As we said before, the CDK provides a lot of support for containerizing your applications. However, the major software tool is minishift.

However, what is minishift? Essentially, it is a simple to use and launch instance of the 
same OpenShift PaaS you would use at work. Why is a PaaS included in a tool, 
much less a lab, focused on Containers? Well, the latest version of OpenShift, 
actually runs docker Containers to host your "Platform" (in the PaaS sense) 
and your application.

If you would like to explore the OpenShift Console, you can see it running 
in your OpenShift instance, if you open a browser. However, before we do that, we need the IP address of the VM minishift created. Easy enough, just run

```bash
$ minishift ip
192.168.???.??? 
```
Ok, now we can check out the OpenShift console. Open Firefox from the Applications menu and navigate to `https://<ip>:8443/console/`(replace "<ip>" with the address from the last command). Once it loads (and you bypass the bad certificate error), you can log in to the console using the default `developer/developer` username/password.

## Setting Up For the Remaining Labs

Let's wrap up the walkthroughs by and set up for the next lab sections we'll go ahead and bring up another VM. In this case, we are launching an instance of Red Hat Enterprise Linux Atomic Host that will set up and run OpenShift during launch.
This box will be known as **atomic-host.example.com** for the purposes of
this lab and will have the IP address `192.168.124.100` but you should always be able to reference it by DNS name.

```bash
$ virsh start atomic-host
```

After you bring up this new machine you are then ready to move on to the
[next lab](https://github.com/dustymabe/summit-2017-container-lab/blob/master/labs/lab1/chapter1.md).
