Oracle HTTP Server on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start dockerfiles and samples for Oracle HTTP Server Standalone 12.2.1 based on Oracle Linux and Oracle JDK 8 (Server).
The certification of OHS on Docker does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## Building Oracle JDK (Server JRE) base image
Before you can build these WebLogic images, you must download the Oracle Server JRE binary and drop in folder `OracleJava/java-8` and build that image.

        $ cd ../OracleJava/java-8
        $ sh build.sh

## How to Build and Run
This project offers sample Dockerfiles for Oracle HTTP Server 12cR2 (12.2.1) in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

### Building OHS Docker Install Images
IMPORTANT: You have to download the binaries of OHS and Oracle JDK and put them in place (see .download files inside dockerfiles/).

Download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sh buildDockerImage.sh -v 12.2.1

IMPORTANT: the resulting images will NOT have a domain pre-configured.
You must extend the image with your own Dockerfile, and create your domain using WLST. You might take a look at the use case samples as well below.

## Samples for OHS Domain Creation
To give users an idea on how to create a domain from a custom Dockerfile to extend the OHS image, we provide a few samples. For an example on 12.2.1, you can use the sample inside **samples/1221-OHS-domain** folder for creating standalone OHS domain

### Sample Domain for OHS 12.2.1
This Dockerfile will create an image by extending **oracle/ohs:12.2.1-sa** . It will configure a ohsDomain with the following settings:

 - Oracle Linux Username: oracle
 - Oracle Linux Password: welcome1
 - OHS Domain Name: ohsDomain
 - OHS Component name : ohs_sa1
 - NodeManager on port: 5556
 - OHS on port: 7777

### Write your own OHS domain with WLST
The best way to create your own, or extend domains is by using WebLogic Scripting Tool. You can find an example of a WLST script to create domains at create-sa-ohs-domain.py. You may want to tune this script with your own setup . You can also extend images and override an existing domain, or create a new one with WLST.

## Building a sample Docker Image of a OHS Domain
To try a sample of a OHS standalone image with a domain configured, follow the steps below:

Make sure you have **oracle/ohs:12.2.1-sa** image built. If not go into **dockerfiles/12.2.1** and call:

        $ sh buildDockerImage.sh -v 12.2.1

### How to Build OHS domain Image
Go to folder **samples/1221-OHS-domain**

Run the following command:

        $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 .

Verify you now have this image in place with

        $ docker images

### How to run container

**Prerequisite** : Create a docker data volume which will contain the Oracle Weblogic Proxy Plugin file

         Eg:$ docker volume create --name volume

_This volume will be created in "/var/lib/docker" directory or the location where "/var/lib/docker" points to._


1. Depending on your weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](http://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553)

2. Place the custom_mod_wl_ohs.conf file in docker data volume directory . e.g /var/lib/docker/volume

3. To start the OHS Container with above sampleohs:12.2.1 image , run command from docker voume directory

         For e.g
         $ cd /var/lib/docker/volume
         $ docker run -v `pwd`:/volume -w /volume -d --name ohs -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh


   The **configureWLSProxyPlugin.sh** script will be the first script to be run inside the OHS container .
   This script will perform the following actions:
   - Fetch the custom_mod_wl_ohs.conf file from mounted shared data volume
   - Place the custom_mod_wl_ohs.conf file under OHS INSTANCE home
   - Start Node manager and OHS server

4. Sanity URLs check for OHS server
   - Now you can access the OHS index page @ http://localhost:7777/index.html
   - Static html page @ URL http://localhost:7777/helloWorld.html

5. All applications should now be routed via the OHS port 7777.

######NOTE: If custom_mod_wl_ohs.conf is not provided or not found under mounted shared data volume, then configureWLSProxyPlugin.sh will still start OHS server which will be accessible @ http://localhost:7777/index.html.

######Later you can login to running container and configure Weblogic Server proxy plugin file and run *restartOHS.sh* script.

## Node Manager Password

On the first startup of the container a random password will be generated for the Node Manager in the OHS domain. You can find this password in the container logs generated during the startup of the container.  Look for the string:

        ----> 'OHS' Node Manager password:

To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


## Support
Currently Oracle HTTP Server on Docker is NOT supported by Oracle. Use these files at your own discretion.


## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
