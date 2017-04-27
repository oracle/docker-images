WebLogic on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) and [samples](samples/) for WebLogic 12.1.3, 12.2.1, 12.2.1.1 and 12.2.1.2 based on Oracle Linux and Oracle JDK 8 (Server).

The certification of WebLogic on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For more information on the certification, please check the [WebLogic on Docker Certification Whitepaper](http://www.oracle.com/technetwork/middleware/weblogic/overview/weblogic-server-docker-containers-2491959.pdf) and [WebLogic Blog](https://blogs.oracle.com/WebLogicServer/) for updates.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## How to build and run
This project offers sample Dockerfiles for WebLogic 12cR2 (12.2.1.x) and WebLogic 12c (12.1.3), and for each version it also provides at least one Dockerfile for the 'developer' distribution, a second Dockerfile for the 'generic' distribution, and a third Dockerfile for the 'infrastructure' distribution. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh

### Building WebLogic Docker Install Images
**IMPORTANT:** you have to download the binary of WebLogic and put it in place (see `.download` files inside dockerfiles/<version>).

Before you build, choose which version and distribution you want to build an image of, then download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

        $ sh buildDockerImage.sh -h
        Usage: buildDockerImage.sh -v [version] [-d | -g | -i] [-s]
        Builds a Docker Image for Oracle WebLogic.
          
        Parameters:
           -v: version to build. Required.
           Choose one of: 12.1.3  12.2.1  
           -d: creates image based on 'developer' distribution
           -g: creates image based on 'generic' distribution
           -i: creates image based on 'infrastructure' distribution
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages
        
        * select one distribution only: -d, -g, or -i
        
        LICENSE CDDL 1.0 + GPL 2.0
        
        Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST. You might take a look at the use case samples as well below.

## Samples for WebLogic Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the WebLogic image, we provide a few samples for 12c versions for the Developer distribution. For an example on **12.2.1**, you can use the sample inside [samples/1221-domain](samples/1221-domain) folder. For the **12.1.3** version, check the folder [samples/1213c-domain](samples/1213-domain). 

### Sample Domain for WebLogic 12.2.1
This [Dockerfile](samples/1221-domain/Dockerfile) will create an image by extending **oracle/weblogic:12.2.1-developer**. It will configure a **base_domain** with the following settings:

 * Admin Username: `weblogic`
 * Admin Password: provided by `ADMIN_PASSWORD` 
 * Oracle Linux Username: `oracle`
 * Oracle Linux Password: `welcome1`
 * WebLogic Domain Name: `base_domain`
 * Admin Server on port: `7001`
 * NodeManager on port: `5556`
 * Managed Server on port: `7002`

Make sure you first build the WebLogic 12.2.1 Image with **-d** to get the Developer Image.

### Write your own WebLogic domain with WLST
The best way to create your own, or extend domains is by using [WebLogic Scripting Tool](https://docs.oracle.com/middleware/1221/cross/wlsttasks.htm). You can find an example of a WLST script to create domains at [create-wls-domain.py](samples/1221-domain/container-scripts/create-wls-domain.py). You may want to tune this script with your own setup to create DataSources and Connection pools, Security Realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Building a sample Docker Image of a WebLogic Domain
To try a sample of a WebLogic image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/weblogic:12.2.1-developer** image built. If not go into **dockerfiles** and call 

        $ sh buildDockerImage.sh -v 12.2.1 -d

  2. Go to folder **samples/1221-domain**
  3. Run the following command: 

        $ docker build -t 1221-domain --build-arg ADMIN_PASSWORD=<define> .

  4. Verify you now have this image in place with 

        $ docker images

### Running WebLogic AdminServer
To start the WebLogic AdminServer, you can simply call **docker run -d 1221-domain** command. The sample Dockerfile defines **startWebLogic.sh** as the default CMD.

    $ docker run -d --name=wlsadmin -p 7001:7001 1221-domain

Now you can access the AdminServer Web Console at [http://localhost:7001/console](http://localhost:7001/console).

## Clustering WebLogic on Docker Containers
WebLogic has a [Machine](https://docs.oracle.com/middleware/1221/wls/WLACH/taskhelp/machines/ConfigureMachines.html) concept, which is an operational system with an agent, the Node Manager. This resource allows WebLogic AdminServer to create and assign [Managed Servers](https://docs.oracle.com/middleware/1221/wls/WLACH/taskhelp/domainconfig/CreateManagedServers.html) of an underlying domain in order to expand an environment of servers for different applications and resources, and also to define a [Cluster](). By using **Machines** from containers, you can easily create a [Dynamic Cluster]() by simply firing new NodeManagers containers. With some WLST magic, your cluster can scale in and out.

### Clustering WebLogic on Docker Containers on Single Host
You can deploy a cluster of WebLogic using Docker with the samples scripts defined in this repository. After you have an AdminServer running on a container as per above, you can easily create a cluster by deploying new Docker containers of Managed Servers. To do that, first make sure you have an AdminServer containerized with name **wlsadmin**. Then you can fire the following command:

       $ docker run -d --link wlsadmin:wlsadmin 1221-domain createServer.sh

Wait 5-10 seconds, and then go into the AdminServer Web Console and check in the Machines page if the NodeManager was registered. Then check if the Managed Server was also created and registered. The script **createServer.sh** starts a NodeManager inside the container and then it will also create a **Managed Server**, and register both on the Admin Server located at **wlsadmin** as per the alias indicated.

### Clustering WebLogic on Docker Containers Across Multiple Hosts
By using the sample [samples/1221-multihost](samples/1221-multihost), which contains a set of scripts that leverage [Docker Machine](https://docs.docker.com/machine/) and [Docker Swarm](https://docs.docker.com/swarm/), and by digging through the scripts that create the containers across multiple hosts combined with the scripts inside [1221-domain/container-scripts](samples/1221-domain/container-scripts), you can learn the necessary steps to deploy this with different Docker setups.

The basic idea behind this setup is that you must have all the containers across different hosts assigned to a specific [Docker Overlay Network](https://docs.docker.com/engine/userguide/networking/dockernetworks/#an-overlay-network), a feature of Docker 1.9+ that allows containers to join the same network, even though they are running at different host environments.

#### Create a WebLogic Server 12cR2 MedRec sample domain**
The Supplemental Quick Installer is a lightweight installer that contains all of the necessary artifacts to develop and test applications on Oracle WebLogic Server 12.2.1. You can extend the WebLogic developer install image **oracle/weblogic:12.2.1-developer** to create a domain image with the MedRec application deployed.

  1. Make sure you have `oracle/weblogic:12.2.1-developer` image built. If not go into [dockerfiles](dockerfiles/) and call 

        $ sh buildDockerImage.sh -v 12.2.1 -d

  2. Go to folder [samples/1221-medrec](samples/1221-medrec)
  3. Download into this folder the supplemental package for WebLogic 12R2
  4. Run the following command: 

        $ docker build -t 1221-medrec .

  5. Now run a container from this new sample domain image

        $ docker run -ti -p 7002:7002 1221-medrec

  6. Now access the AdminServer Console at 

        http://localhost:7002/medrec

## Choose your WebLogic Distribution
This project hosts two to three configurations (depending on WebLogic version) for building Docker images with WebLogic 12c.

 * Quick Install Developer Distribution

   - For more information on the WebLogic 12c ZIP Developer Distribution, visit [WLS Zip Distribution for Oracle WebLogic Server 12.1.3.0](http://download.oracle.com/otn/nt/middleware/12c/wls/1213/README.txt).

   - For more information on the WebLogic 12cR2 Quick Install Developer Distribution, visit [WLS Quick Install Distribution for Oracle WebLogic Server 12.2.1.0](http://download.oracle.com/otn/nt/middleware/12c/wls/1221/README.txt).

 * Generic Distribution

   - For more information on the WebLogic 12c Generic Full Distribution, visit [WebLogic 12.1.3 Documentation](http://docs.oracle.com/middleware/1213/wls/index.html).

   - For more information on the WebLogic 12cR2 Generic Full Distribution, visit [WebLogic 12.2.1 Documentation](http://docs.oracle.com/middleware/1221/wls/index.html).

 * Fusion Middleware Infrastructure Distribution

   - For more information on the WebLogic 12cR2 Infrastructure Full Distribution, visit [WebLogic 12.2.1 Infrastructure Documentation](https://docs.oracle.com/middleware/1221/core/INFIN/).

## License
To download and run WebLogic 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleWebLogic](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
