# LAB 4: Orchestrated deployment of a decomposed application

In this lab we introduce how to orchestrate a multi-container application in Kubernetes.

This lab should be performed on dev.example.com unless otherwise instructed.

Username: root; Password: redhat

Expected completion: 40-60 minutes

Let's start with a little experimentation. I am sure you are all excited about your new blog site! And, now that it is getting super popular with 1,000s of views per day, you are starting to worry about uptime.

So, let's see what will happen. Launch the site:

```bash
docker run -d -p 3306:3306 -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb --name mariadb mariadb
docker run -d -p 80:80 --link mariadb:db --name wordpress wordpress
```

Take a look at the site in your web browser on your machine using [http://dev.example.com](http://dev.example.com). As you learned before, you can confirm the port that your server is running on by running:

```bash
docker ps
docker port wordpress
```

and taking look at the "PORTS" column for the wordpress site. You can also get your ip address by looking at the address for the eth0 interface after you execute:

```bash
ip addr
```

However, we have some nice DNS set up and chose port 80, so you can just use [http://dev.example.com](http://dev.example.com).

Now, let's see what happens when we kick over the database. However, for a later experiment, let's grab the container-id right before you do it. 

```bash
OLD_CONTAINER_ID=$(docker inspect --format '{{ .Id }}' mariadb)
docker stop mariadb
```

Take a look at the site in your web browser or using curl now. And, imagine, explosions! *making sound effects will be much appreciated by your lab mates.*

```bash
web browser -> http://dev.example.com OR curl -L http://dev.example.com
```

Now, what is neat about a container system, assuming your web application can handle it, is we can bring it right back up, with no loss of data.

```bash
docker start mariadb
```

OK, now, let's compare the old container id and the new one.

```bash
NEW_CONTAINER_ID=$(docker inspect --format '{{ .Id }}' mariadb)
echo -e "$OLD_CONTAINER_ID\n$NEW_CONTAINER_ID"
```

Hmmm. Well, that is cool, they are exactly the same. OK, so all in all, about what you would expect for a web server and a database running on VMs, but a whole lot faster. Let's take a look at the site now.

```bash
web browser -> http://dev.example.com OR curl -L http://dev.example.com
```

Hmmm. Well, that is disappointing. Unfortunately, because most applications are designed to be deployed on "perfect environments" WordPress doesn't tolerate the destruction of its database without a restart of httpd (there may be plugins or the like to solve this problem, but that is beyond the scope of this lab).

Well, let's go ahead and restart the web server, and we will be right back to where we were. 

```bash
docker stop wordpress
web browser -> http://dev.example.com OR curl -L http://dev.example.com #should fail, 404
docker start wordpress
web browser -> http://dev.example.com OR curl -L http://dev.example.com #site should load
```

**Note** if your page load doesn't work immediately, give wordpress another second or two to come up

Finally, let's kill off these containers to prepare for the next
section.

```bash
docker rm -f wordpress mariadb
```

Starting and stopping is definitely easy, and fast. However, it is still pretty manual. What if we could automate the recovery? Or, in buzzword terms, "ensure the service remains up"? Enter Kubernetes. And, so you are up on the lingo, sometimes "kube" or "k8s".

## Pod Creation

Let's get started by talking about a pod. A pod is a set of containers that provide one "service." How do you know what to put in a particular pod? Well, pod's containers need to be co-located on a host and need to be spawned and re-spawned together. So, if the containers always need to be running on the same docker host, well, then they should be a pod.

**Note:** We will be putting this file together in steps to make it easier to explain what the different parts do. We will be identifying the part of the file to modify by looking for an "empty element" that we inserted earlier and then replacing that with a populated element.

Let's make a pod for mariadb. Open a file called mariadb-pod.yaml.

```bash
mkdir -p ~/workspace/mariadb/kubernetes
vi ~/workspace/mariadb/kubernetes/mariadb-pod.yaml
```

In that file, let's put in the pod identification information:

```
kind: Pod
apiVersion: v1beta3
metadata:
  labels:
    name: mariadb
  name: mariadb
spec:
  containers:
```

We specified the version of the Kubernetes API, the name of this pod (aka ```name```), the ```kind``` of Kubernetes thing this is, and a ```label``` which lets other Kubernetes things find this one.

Generally speaking, this is the content you can copy and paste between pods, aside from the names and labels.

Now, let's add the custom information regarding this particular container. To start, we will add the most basic information. Please replace the ```containers:``` line with:

```
  containers:
  - capabilities: {}
    env:
    image: dev.example.com:5000/mariadb
    name: mariadb
    ports:
    - containerPort: 3306
      protocol: TCP
    resources:
      limits:
        cpu: 100m
```

Here we set the ```name``` of the container; remember we can have more than one in a pod. We also set the ```image``` to pull, in other words, the container image that should be used and the registry to get it from. We can also set limitations here like cpu cap and exposed ports.

Lastly, we need to configure the environment variables that need to be fed from the host environment to the container. Replace ```env:``` with:

```bash
    env:
    - name: DBUSER
      value: user
    - name: DBPASS
      value: mypassword
    - name: DBNAME
      value: mydb
```

OK, now we are all done, and should have a file that looks like:

```
kind: Pod
apiVersion: v1beta3
metadata:
  labels:
    name: mariadb
  name: mariadb
spec:
  containers:
  - capabilities: {}
    env:
    - name: DBUSER
      value: user
    - name: DBPASS
      value: mypassword
    - name: DBNAME
      value: mydb
    image: dev.example.com:5000/mariadb
    name: mariadb
    ports:
    - containerPort: 3306
      protocol: TCP
    resources:
      limits:
        cpu: 100m
```

Our wordpress container is much less complex, so let's do that pod next.

```bash
mkdir -p ~/workspace/wordpress/kubernetes
vi ~/workspace/wordpress/kubernetes/wordpress-pod.yaml
```

```
kind: Pod
apiVersion: v1beta3
metadata:
  labels:
    name: wpfrontend
  name: wordpress
spec:
  containers:
  - env:
    - name: DB_ENV_DBUSER
      value: user
    - name: DB_ENV_DBPASS
      value: mypassword
    - name: DB_ENV_DBNAME
      value: mydb
    image: dev.example.com:5000/wordpress
    name: wordpress
    ports:
    - containerPort: 80
      protocol: TCP
```

A couple things to notice about this file. Obviously, we change all the
appropriate names to reflect "wordpress" but, largely, it is the same as
the mariadb pod file. We also use the environment variables that are specified
by the wordpress container, although they need to get the same values as the
ones in the mariadb pod. Lastly, just to show you aren't bound to the image or
pod names, we also changed the ```labels``` value to "wpfronted".

Ok, so, lets launch our pods and make sure they come up correctly. In
order to do this, we need to introduce the ```kubectl``` command which is
what drives Kubernetes. Generally, speaking, the format of ```kubectl```
commands is ```kubetctl <operation> <kind>```. Where ```<operation>``` is
something like ```create```, ```get```, ```remove```, etc. and ```kind```
is the ```kind``` from the pod files.

```bash
kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-pod.yaml
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-pod.yaml
```

Now, I know i just said, ```kind``` is a parameter, but, as this is a create statement, it looks in the ```-f``` file for the ```kind```.

Ok, let's see if they came up:

```bash
kubectl get pods
```

Which should output two pods, one called ```mariadb``` and one called ```wordpress```.

If you have any issues with the pods transistioning from a "Pending" state, you can check out the logs for each service.

```bash
journalctl -fl -u kube-apiserver -u kube-controller-manager -u kube-proxy -u kube-scheduler -u kubelet -u etcd -u docker
```

Ok, now let's kill them off so we can introduce the services that will let them more dynamically find each other.

```bash
kubectl delete pod mariadb
kubectl delete pod wordpress
```

**Note** you used the "singular" form here on the ```kind```, which, for delete, is required and requires a "name". However, you can, usually, use them interchangeably depending on the kind of information you want.

## Service Creation
Now we want to create Kubernetes Services for our pods so that Kubernetes can introduce a layer of indirection between the pods. 

Let's start with mariadb. Open up a service file:

```bash
vi ~/workspace/mariadb/kubernetes/mariadb-service.yaml
```

and insert the following content:

```
kind: Service
apiVersion: v1beta3
metadata:
  labels:
    name: mariadb
  name: mariadb
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  selector:
    name: mariadb
```

As you can probably tell, there isn't really anything new here. However, you need to make sure the ```kind``` is of type ```Service``` and that the ```selector``` matches at least one of the ```labels``` from the pod file. The ```selector``` is how the service finds the pod that provides its functionality.

OK, now let's move on to the wordpress service. Open up a new service file:

```bash
vi ~/workspace/wordpress/kubernetes/wordpress-service.yaml
```

and insert:

```
kind: Service
apiVersion: v1beta3
id: wpfrontend
metadata:
  labels:
    name: wpfrontend
  name: wpfrontend
spec:
  ports:
  - port: 80
  protocol: TCP
  targetPort: 80
  selector:
    name: wpfrontend
  publicIPs:
  - 192.168.135.2
  containerPort: 80
```

So, here you may notice, there is no reference to wordpress at all. In fact, we might even want to name the file wpfrontend-service.yaml to make it clearer that, in fact, we could have any pod that provides "wordpress capabilities". However, for a lab like this, I thought it would be confusing. 

An even better example might have been if we had made the mariadb-service just a "db" service and then, the pod could be mariadb, mysql, sqlite, anything really, that can support SQL the way wordpress expects it to. In order to do that, we would just have to add a ```label``` to the ```mariadb-pod.yaml``` called "db" and a ```selector``` in the ```mariadb-service.yaml``` (although, an even better name might be ```db-service.yaml```) called ```db```. Feel free to experiment with that at the end of this lab if you have time.

Now let's get things going. Start mariadb:

```bash
kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-pod.yaml
kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-service.yaml
```

Now let's start wordpress.

```bash
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-pod.yaml
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-service.yaml
```

OK, now let's make sure everything came up correctly:

```bash
kubectl get pods
kubectl get services
```

**Note** these may take a while to get to a ```RUNNING``` state as it pulls the image from the registry, spin up the containers, do the kubernetes magic, etc. 

Eventually, you should see:

```bash
# kubectl get pods
POD         IP           CONTAINER(S)   IMAGE(S)                         HOST                  LABELS            STATUS    CREATED
mariadb     172.17.0.1   mariadb        dev.example.com:5000/mariadb     127.0.0.1/127.0.0.1   name=mariadb      Running   2 hours
wordpress   172.17.0.2   wordpress      dev.example.com:5000/wordpress   127.0.0.1/127.0.0.1   name=wpfrontend   Running   2 hours
```

```bash
# kubectl get services
NAME            LABELS                                    SELECTOR          IP               PORT(S)
kubernetes      component=apiserver,provider=kubernetes   <none>            10.254.0.2       443/TCP
kubernetes-ro   component=apiserver,provider=kubernetes   <none>            10.254.0.1       80/TCP
mariadb         name=mariadb                              name=mariadb      10.254.200.116   3306/TCP
wpfrontend      name=wpfrontend                           name=wpfrontend   10.254.177.85    80/TCP
                                                                            192.168.135.2
```

Check and make sure you can access the wordpress frontend service that we created.

curl -L http://dev.example.com


Seemed awfully manual and ordered up there, didn't it? Just wait til Lab5 where we make it a lot less painful!

## Remote Deployment

Now that we are satisfied that our containers and Kubernetes definitions work, let's try deploying it to a remote server.

First, we have to add the remote cluster to our local configuration. However,
before we do that, let's take a look at what we have already. Also, notice that
the ```kubectl config``` follows the `<noun>` `<verb>` model. In other words,
```kubectl``` `<noun>` = ```config``` `<verb>` = ```view```

```bash
kubectl config view
``` 

Not much right? If you notice, we don't even have any information about the current context. In order to avoid losing our local connection, why don't we set up the local machine as a cluster first, before we add the remote. However, in order for the configuration to work correctly, we need to touch the config file first.

```bash
mkdir ~/.kube
touch ~/.kube/.kubeconfig
```

First we create the cluster (after each step, I recommend you take a look at the current config with a ```view```):

```bash
kubectl config set-cluster local --server=http://localhost:8080
kubectl config view
```

Then we add it to a context:

```bash
kubectl config set-context local-context --cluster=local
kubectl config view
```

Now we switch to that context:

```bash
kubectl config use-context local-context
kubectl config view
```

Strictly speaking, a lot of the above is not necessary, however, it is good to get in to the habit of using "contexts" then when you are using ```kubectl``` with properly configured security and the like, you will run in to less "mysterious" headaches trying to figure out why you can't deploy.

Now, lets test it out.

```bash
kubectl get pods
kubectl get services
```

Did you get your pods and services back? If not, you should check your config. Your ```config view``` result should look like this:

```bash
kubectl config view
```
Result:

```
apiVersion: v1
clusters:
- cluster:
    server: http://localhost:8080
  name: local
contexts:
- context:
    cluster: local
    user: ""
  name: local-context
current-context: local-context
kind: Config
preferences: {}
users: []
```

All right, let's switch to the remote.

```bash
kubectl config set-cluster remote --server=http://192.168.135.3:8080
kubectl config set-context remote-context --cluster=remote
kubectl config use-context remote-context
kubectl config view
```

You should now have ```current-context: remote-context```. Now, let's prove we are talking to the remote:

```bash
kubectl get pods
kubectl get services
```

Nothing there, right? Ok, so let's start the bits up on the remote deployment
server.  Before we do that, we need to change the ```publicIP``` address in the service
file so that it uses the IP address on the remote host that we are going to deploy
the pod onto.

Open the new service file and put the following definition in it. 

```bash
vi ~/workspace/wordpress/kubernetes/wordpress-service-remote.yaml
```

```
kind: Service
apiVersion: v1beta3
id: wpfrontend
metadata:
  labels:
    name: wpfrontend
  name: wpfrontend
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    name: wpfrontend
  publicIPs:
  - 192.168.135.3
containerPort: 80
```

```bash
kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-pod.yaml
kubectl create -f ~/workspace/mariadb/kubernetes/mariadb-service.yaml
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-pod.yaml
kubectl create -f ~/workspace/wordpress/kubernetes/wordpress-service-remote.yaml
```

Now we should see similar results as our local machine from:

```bash
kubectl get pods
kubectl get services
```

Now we can check to make sure the site is running. However, first we need the IP for it.

```bash
kubectl get endpoints
```

Which should give you a result like:

```bash
NAME            ENDPOINTS
kubernetes      192.168.135.3:6443
kubernetes-ro   192.168.135.3:7080
mariadb         172.17.0.1:3306
wpfrontend      172.17.0.2:80
```

Now to test it all you need to do is access the IP address and port of the service that is running.  You can either use a browser or curl:

```bash
curl -L http://deploy.example.com
```

Ok, now you can move on to lab5, where Aaron will show you how to create an application much more easily.
