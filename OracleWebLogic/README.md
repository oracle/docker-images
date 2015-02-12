WebLogic on Docker
===============
Docker configurations to facilitate installation, configuration, and environment setup for developers. This project includes [dockerfiles](dockerfiles/) and [samples](samples/) for both WebLogic 11g 10.3.6 with JDK 7, as well WebLogic 12c 12.1.3 with JDK 8.

## Based on Official Oracle Linux Docker images
For more information please read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

## How to build and run
This project offers Dockerfiles for both WebLogic 11g (10.3.6) and WebLogic 12c (12.1.3), and for each version it also provides one Dockerfile for the 'developer' distribution and a second Dockerfile for the 'generic' distribution. To assist in building the images, you can use the [buildDockerImage.sh](https://github.com/oracle/docker/blob/master/OracleWebLogic/dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

### Building WebLogic Images
First decide which version and distribution you want to use, then download the required packages and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sudo sh buildDockerImage.sh -h
    Usage: buildDockerImage.sh -v version [-d]
    Builds a Docker Image for WebLogic.
    
    Parameters:
      -v: version to build. Required.
          Choose one of: 10.3.6  12.1.3  
      -d: creates image based on 'developer' distribution, or 'generic' if ommitted	

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST.

## Samples for WebLogic Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the WebLogic image, we provide a few samples for both 11g and 12c versions for the Developer distribution. For the **12c** version, check the folder [samples/12c-domain](https://github.com/oracle/docker/tree/master/OracleWebLogic/samples/12c-domain). For an example on **11g**, you can use the sample inside [samples/11g-domain](https://github.com/oracle/docker/tree/master/OracleWebLogic/samples/11g-domain) folder.

### Sample Domain for WebLogic 12c
This [Dockerfile](https://github.com/oracle/docker/blob/master/OracleWebLogic/samples/12c-domain/Dockerfile) will create an image by extending **oracle/weblogic:12.1.3-dev** (from the Developer distribution). It will configure a **base_domain** with the following settings:

 * JPA 2.1 enabled
 * JAX-RS 2.0 shared library deployed
 * Admin Username: **weblogic**
 * Admin Password: **welcome1**
 * Oracle Linux Username: **oracle**
 * Oracle Linux Password: **welcome1**
 * WebLogic Domain Name: **base_domain**

### Sample Domain for WebLogic 11g
This second [Dockerfile](https://github.com/brunoborges/docker/blob/master/OracleWebLogic/samples/11g-domain/Dockerfile) shows how to extend **oracle/weblogic:10.3.6** and create a domain. 

### Write your own WebLogic domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](http://docs.oracle.com/cd/E57014_01/cross/wlsttasks.htm). The WLST script used to create domains in both Dockerfiles is [create-wls-domain.py](https://github.com/oracle/docker/blob/master/OracleWebLogic/samples/12c-domain/container-scripts/create-wls-domain.py) (for 12c). This script by default adds JMS resources and a few other settings. You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override the existing domain, or create a new one with WLST.

## Building a sample Docker Image of WebLogic Domain
To try a sample of a WebLogic image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/weblogic:12.1.3-dev** image built. If not go into **dockerfiles** and call 

        sudo sh buildDockerImage.sh -v 12.1.3 -d

  2. Go to folder **samples/12c-domain**
  3. Run the following command: 

        sudo docker build -t samplewls:12.1.3 .

  4. Make sure you now have this image in place with 

        sudo docker images

If you want to try 11g go to folder **samples/11g-domain**. The Dockerfile is pointing to **oracle/weblogic:10.3.6-dev**.
  
### Running WebLogic AdminServer
To start the WebLogic AdminServer, you can simply call **docker run -d samplewls:12.1.3** command. The samples Dockerfiles define **startWebLogic.sh** as the default CMD.

    $ sudo docker run -d --name=wlsadmin samplewls:12.1.3
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsadmin
    172.17.0.27

Now you can access the AdminServer Web Console at [http://172.17.0.27:7001/console](http://172.17.0.27:7001/console).

### Running WebLogic NodeManager
To start the WebLogic NodeManager, you can simply call **docker run -d samplewls:12.1.3 startNodeManager.sh** command. The samples Dockerfiles set PATH variable with domain's bin folder.

    $ sudo docker run -d --name=wlsnm0 samplewls:12.1.3 startNodeManager.sh
    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' wlsnm0
    172.17.0.28

Now you can go to the AdminServer Web Console and add a new Machine pointing to the NodeManager container's IP address (172.17.0.28) at port 5556.

## Clustering WebLogic on Docker Containers
WebLogic has a [Machine](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/machines/ConfigureMachines.html) concept, which is an operational system with an agent, the Node Manager. This resource allows WebLogic AdminServer to create and assign [Managed Servers](https://docs.oracle.com/middleware/1213/wls/WLACH/taskhelp/domainconfig/CreateManagedServers.html) of an underlying domain in order to expand an environment of servers for different applications and resources, and also to define a [Cluster](). By using **Machines** from containers, you can easily create a [Dynamic Cluster]() by simply firing new NodeManagers containers. With some WLST magic, your cluster can scale in and out.

### Clustering WebLogic on Docker Containers on Single Host
If you have an AdminServer and a NodeManager running on containers of the same host, you can easily create a cluster by managing the Machines and Clusters from the Admin Web Console. But the samples in this project provide a smart script called **createMachine.sh** that starts the NodeManager, and later calls a WLST script to add a new machine to the domain running on **wlsadmin** container. This saves you a lot of time. To do that, first make sure you have an AdminServer containerized with name **wlsadmin**. Then you can fire the following command:

       $ sudo docker run -d --link wlsadmin:wlsadmin samplewls:12.1.3 createMachine.sh

Wait 10 seconds, and then go into the AdminServer Web Console and check in the Machines page if the NodeManager was registered. You then can fire as many containers as you want to add more Machines to that domain. Later, you can create Clusters.

### Clustering WebLogic on Docker Containers Across Multiple Hosts
You can either do this manually, or using the **createMachine** helper script presented above, combined with the **add-machine.py** and **addMachine.sh** scripts inside the [samples/12c-domain/container-scripts](https://github.com/oracle/docker/tree/master/OracleWebLogic/samples/12c-domain/container-scripts) folder. The most important thing for this to work, is that both containers from different hosts, have their ports (AdminServer and NodeManager) reachable somehow. You can either make sure a virtual network for containers across multiple hosts is in place, or that ports are binded to hosts, and hosts' IP addresses are used for registering and communication between AdminServer and NodeManager. 

To better understand this, let's first see how to setup this topology manually with Docker commands.

#### Manually
In this example we will be using the sample for 12c-domain based on oracle/weblogic:12.1.3-dev image. Make sure you have the **samplewls:12.1.3** image in place, as documented above, and available on Docker local registry of both hosts (**host0** and **host1**). Start the AdminServer on one host and make sure port 7001 is binded to the host so the NodeManager is able to communicate with this AdminServer from another host. Then you must also start the NodeManager on second host also having its port binded to the host machine. This is the overall understanding. Let's see how this works:

 1. On **host0** start the AdminServer: 

        $ sudo docker run -d -p 7001:7001 samplewls:12.1.3 startWebLogic.sh

 2. On **host1** start the NodeManager:

        $ sudo docker run -d -p 5556:5556 samplewls:12.1.3 startNodeManager.sh

 3. Now access the AdminServer Console at http://host0:7001/console
 4. Go to **Environment > Machines** and add a new machine. Point to **host1:5556**
 5. Save changes, and test if NM is reachable by clicking on tab Monitoring

If you want to have more than one AdminServer and/or NodeManager containers per host, you can use other ports instead the default ones but when adding the new Machine, make sure to point to the external binded port.

#### Magically, Using **createMachine.sh**
This script accepts some variables to allow connecting a NodeManager to a remote AdminServer as long both are reachable bidirectionally. When properly executed with the correct parameters, will connect to the AdminServer and assign the NodeManager running on that container to the domain. This way, the container can be started and automagically added as a Machine into the AdminServer domain. Follow the steps below:

 1. On **host0** start the AdminServer: 

        $ sudo docker run -d -p 7001:7001 samplewls:12.1.3 startWebLogic.sh

 2. On **host1** start the NodeManager with **createMachine.sh** and ``ADMIN_URL`` variable

        $ sudo docker run -d -p 5556:5556 \
               -e ADMIN_URL="t3://host0:7001" \
               -e NM_HOST="host1" \
               samplewls:12.1.3 createMachine.sh

 3. Now access the AdminServer Console at http://host0:7001/console
 4. Go to **Environment > Machines** and you should now have a Machine registered

The **createMachine.sh** script will call the **add-machine.py** WLST script. This script has a list of variables that must be properly configured, though most have default values (for when running on Single Host mode):

 * **ADMIN_USERNAME** = username of the AdminServer 'weblogic' user. Default: weblogic
 * **ADMIN_PASSWORD** = password of ADMIN_USERNAME. Defaults to value passed during Dockerfile build. ('welcome1' in samples)
 * **ADMIN_URL**      = t3 URL of the AdminServer. Default: t3://wlsadmin:7001
 * **CONTAINER_NAME** = name of the Machine to be created. Default: nodemanager_ + hash of the container
 * **NM_HOST**        = IP address where NodeManager can be reached. Default: IP address of the container
 * **NM_PORT**        = Port of NodeManager. Default: 5556

## Choose your WebLogic Distribution
This project hosts two configurations for building Docker images with WebLogic 12c.

 * Developer Distribution
   For more information on the WebLogic 12c ZIP Developer Distribution, visit [WLS Zip Distribution for Oracle WebLogic Server 12.1.3.0](http://download.oracle.com/otn/nt/middleware/12c/wls/1213/README.txt).
 * Generic Full Distribution
   For more information on the WebLogic 12c Generic Full Distribution, visit [WebLogic 12.1.3 Documentation](http://docs.oracle.com/middleware/1213/wls/index.html).
 * For 11g versions, you can find on the WebLogic pages.

## License
To download and run WebLogic 12c Distribution regardless of inside or outside a Docker container, and regardless of Generic or Developer distribution, you must agree and accept the [OTN Free Developer License Terms](http://www.oracle.com/technetwork/licenses/wls-dev-license-1703567.html).

To download and run Oracle JDK regardless of inside or outside a DOcker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project and GitHub [docker/OracleWebLogic](https://github.com/oracle/docker/tree/master/OracleWebLogic/) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.
