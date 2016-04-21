#Containerizing applications, existing and new: Lab Guide

|   | Containerizing applications, existing and new: Information |
|---|---|
| Technology/Product | Red Hat Enterprise Linux & Containers |
| Difficulty |  2 |
| Time  |  120 minutes  |
| Prerequisites  |   |

## Table of Contents

1. Slides
1. **[LAB 1](labs/chapter1.md)** Docker refresh
1. **[LAB 2](labs/chapter2.md)** Analyzing a monolithic application
1. **[LAB 3](labs/chapter3.md)** Deconstructing an application into microservices
1. **[LAB 4](labs/chapter4.md)** Orchestrated deployment of a decomposed application
1. **[LAB 5](labs/chapter5.md)** Packaging an orchestrated application

## Abstract (Langdon)

* TODO: change the abstract to remove cdk

## Slides (Langdon)

* Intro to the lab (likely content below)
* Intro to the people
* What will we be doing today?

###In this lab you will...
Containerization has been a hot button topic for quite a while now, with no signs of letting up on the buzz train. However, what is less clear is how one should move an existing application to a containerized model. In this lab, we will take you through the steps that most people go through when attempting to containerize an application. 

We will show you the "end state" but we will also show you the states you (may) pass through when working through the containerization of an application. Why not just jump to the "end state?" Well, because it is often both instructive and acceptable to deploy an "improperly" containerized application. As a result, it is worthwhile to experience the change by doing it, with the support of our instructors.

We will also cover how you might start a containerized application. However, that is the much simpler case, so we will cover it, albeit breifly, after we work through the "existing container" example.

##Before you begin...
We will be providing computers for this lab, to ensure we don't lose time on "setup." However, if you have experience with Vagrant and RHEL Atomic Host, you should be able to follow along pretty easily with your own computer. If you do choose to use your own, please come in to the lab with a vagrant deployed instance of RHEL Atomic Host that has Docker running.


### Application as single service containers

1. Download binaries and Dockerfiles from http://****
1. Attempt to run the Dockerfile using:
  * cd service1-app
  * docker build -t $USER/service1-app -f docker-artifacts/Dockerfile .
  * cd ..
1. Fix Dockerfile
  * fix 1 here
  * fix 2 here
  * docker run -dt --rm $USER/service1-app --name "service1-app"
1. work on the next service
  * cd service2-app 
  * docker build -t $USER/service2-app -f docker-artifacts/Dockerfile .
  * cd ..
  * docker run -it --rm $USER/service2-app /bin/bash
1. Fix Dockerfile
  * fix 1 here
  * fix 2 here
  * docker run -it --rm --link="service1-app" $USER/service2-app /bin/bash
1. play around in the container
  * step 1
  * step 2

