OCCAS on Docker
===============
Docker configurations to facilitate installation, configuration, and environment setup for developers. This project includes [dockerfiles](dockerfiles/) and [samples](samples/) for OCCAS 7.0 with JDK 8.

## Based on Official Oracle Linux Docker images
For more information please read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

## How to build and run
This project offers Dockerfiles for OCCAS 7.0. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

### Building WebLogic Images
First decide which version and distribution you want to use, then download the required packages and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sudo sh buildDockerImage.sh -h
    Usage: buildDockerImage.sh -v version [-d]
    Builds a Docker Image for OCCAS.
    
    Parameters:
      -v: version to build. Required.
          Choose one of: 7.0

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST.

## Samples for OCCAS Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the OCCAS image, we provide a few samples for 7.0 version. For the **7.0** version, check the folder [samples/70-domain](samples/70-domain). 

### Sample Domain for OCCAS 7.0
This [Dockerfile](samples/70-domain/Dockerfile) will create an image by extending **oracle/occas:7.0**. It will configure a **base_domain** with the following settings:

 * JPA 2.1 enabled
 * JAX-RS 2.0 shared library deployed
 * Admin Username: **weblogic**
 * Admin Password: **welcome1**
 * Oracle Linux Username: **oracle**
 * Oracle Linux Password: **welcome1**
 * WebLogic Domain Name: **base_domain**
 * Admin Server on port: **8001**

### Write your own WebLogic domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](http://docs.oracle.com/cd/E57014_01/cross/wlsttasks.htm). The WLST script used to create domains in both Dockerfiles is [create-wls-domain.py](samples/70-domain/container-scripts/create-wls-domain.py) (for 7.0). This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override the existing domain, or create a new one with WLST.

## Building a sample Docker Image of OCCAS Domain
To try a sample of a WebLogic image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/occas:7.0** image built. If not go into **dockerfiles** and call 

        sudo sh buildDockerImage.sh -v 7.0

  2. Go to folder **samples/70-domain**
  3. Run the following command: 

        sudo docker build -t simpleoccas:7.0 .

  4. Make sure you now have this image in place with 

        sudo docker images

### Running WebLogic AdminServer
To start the WebLogic AdminServer, you can simply call **docker run -d simpleoccas:7.0** command. The samples Dockerfiles define **startWebLogic.sh** as the default CMD.

    $ sudo docker run -d --name=wlsadmin simpleoccas:7.0
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsadmin
    172.17.0.27

Now you can access the AdminServer Web Console at [http://172.17.0.27:7001/console](http://172.17.0.27:7001/console). You can also access it locally if you bind port **8001** to your host, with **-p 8001:8001**.

### Running WebLogic NodeManager 
To start the WebLogic NodeManager, you can simply call **docker run -d simpleoccas:7.0 startNodeManager.sh** command. The samples Dockerfiles set PATH variable with domain's bin folder.

    $ sudo docker run -d --name=wlsnm0 simpleoccas:7.0 startNodeManager.sh
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsnm0
    172.17.0.28

Now you can go to the AdminServer Web Console and add a new Machine pointing to the NodeManager container's IP address (172.17.0.28) at port 5556.

**IMPORTANT**: this only works with WebLogic 12c because of the new per-domain NodeManager, which doesn't require users to call ``nmEnroll``. 

## Clustering WebLogic on Docker Containers
WebLogic has a [Machine](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/machines/ConfigureMachines.html) concept, which is an operational system with an agent, the Node Manager. This resource allows WebLogic AdminServer to create and assign [Managed Servers](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/domainconfig/CreateManagedServers.html) of an underlying domain in order to expand an environment of servers for different applications and resources, and also to define a [Cluster](). By using **Machines** from containers, you can easily create a [Dynamic Cluster]() by simply firing new NodeManagers containers. With some WLST magic, your cluster can scale in and out.

### Clustering WebLogic on Docker Containers on Single Host
If you have an AdminServer and a NodeManager running on containers of the same host, you can easily create a cluster by managing the Machines and Clusters from the Admin Web Console. But the samples in this project provide a smart script called **createMachine.sh** that starts the NodeManager, and later calls a WLST script to add a new machine to the domain running on **wlsadmin** container. This saves you a lot of time. To do that, first make sure you have an AdminServer containerized with name **wlsadmin**. Then you can fire the following command:

       $ sudo docker run -d --link wlsadmin:wlsadmin simpleoccas:7.0 createMachine.sh

Wait 10 seconds, and then go into the AdminServer Web Console and check in the Machines page if the NodeManager was registered. You then can fire as many containers as you want to add more Machines to that domain. Later, you can create Clusters.

You can also use the **createServer.sh** script that works similar to **createMachine.sh**. It starts a NodeManager associated to the newly created container and then it will also create a **ManagedServer** associated to it. To start the ManagedServer, you must go to Admin Console.

### Clustering WebLogic on Docker Containers Across Multiple Hosts
You can either do this manually, or using the **createMachine** helper script presented above, combined with the **add-machine.py**, **add-server.sh**, and **createServer.sh** scripts inside the [samples/70-domain/container-scripts](samples/70-domain/container-scripts) folder. The most important thing for this to work, is that both containers from different hosts, have their ports (AdminServer and NodeManager) reachable somehow. You can either make sure a virtual network for containers across multiple hosts is in place, or that ports are binded to hosts, and hosts' IP addresses are used for registering and communication between AdminServer and NodeManager. 

To better understand this, let's first see how to setup this topology manually with Docker commands.

#### Manually
In this example we will be using the sample for 12c-domain based on oracle/occas:7.0 image. Make sure you have the **simpleoccas:7.0** image in place, as documented above, and available on Docker local registry of both hosts (**$HOST0** and **$HOST1**). Start the AdminServer on one host and make sure port 7001 is binded to the host so the NodeManager is able to communicate with this AdminServer from another host. Then you must also start the NodeManager on second host also having its port binded to the host machine. This is the overall understanding. Let's see how this works:

 1. On **$HOST0** start the AdminServer: 

        $ sudo docker run -d --net=host simpleoccas:7.0 startWebLogic.sh

 2. On **$HOST1** start the NodeManager (we bind port 7001 for the still-to-be-created ManagedServer):

        $ sudo docker run -d --net=host simpleoccas:7.0 startNodeManager.sh

 3. Now access the AdminServer Console at http://$HOST0:7001/console
 4. Go to **Environment > Machines** and add a new machine. Point to **$HOST1:5556**
 5. Save changes, and test if NM is reachable by clicking on tab Monitoring

If you want to have more than one AdminServer and/or NodeManager containers per host, you can use other ports instead the default ones but when adding the new Machine, make sure to point to the external binded port.

#### Magically, Using **createMachine.sh**
This script accepts some variables to allow connecting a NodeManager to a remote AdminServer as long both are reachable bidirectionally. When properly executed with the correct parameters, will connect to the AdminServer and assign the NodeManager running on that container to the domain. This way, the container can be started and automagically added as a Machine into the AdminServer domain. Follow the steps below:

 1. On **$HOST0** start the AdminServer: 

        $ sudo docker run -d -p 7001:7001 simpleoccas:7.0 startWebLogic.sh

 2. On **$HOST1** start the NodeManager with **createMachine.sh** and defining hostname **wlsadmin** to the actual reachable address of AdminServer:

        $ sudo docker run -d -p 5556:5556 \
               --add-host wlsadmin:$HOST0 \
               -e NM_HOST="$HOST1" \
               simpleoccas:7.0 createMachine.sh

 3. Now access the AdminServer Console at http://$HOST0:7001/console
 4. Go to **Environment > Machines** and you should now have a Machine registered

The **createMachine.sh** script will call the **add-machine.py** WLST script. This script has a list of variables that must be properly configured, though most have default values (for when running on Single Host mode):

 * **ADMIN_USERNAME** = username of the AdminServer 'weblogic' user. Default: weblogic
 * **ADMIN_PASSWORD** = password of ADMIN_USERNAME. Defaults to value passed during Dockerfile build. ('welcome1' in samples)
 * **ADMIN_URL**      = t3 URL of the AdminServer. Default: t3://wlsadmin:7001
 * **CONTAINER_NAME** = name of the Machine to be created. Default: nodemanager_ + hash of the container
 * **NM_HOST**        = IP address where NodeManager can be reached. Default: IP address of the container
 * **NM_PORT**        = Port of NodeManager. Default: 5556

## License
To download and run OCCAS Distribution regardless of inside or outside a Docker container, you must agree and accept the [OCCAS License Terms](http://docs.oracle.com/cd/E49461_01/doc.70/occas_70_licensing_information.pdf).

To download and run Oracle JDK regardless of inside or outside a Docker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project and GitHub [docker/OCCAS](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.
