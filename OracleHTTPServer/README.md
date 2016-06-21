Oracle HTTP Server on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start dockerfiles and samples for Oracle HTTP Server Standalone 12.2.1 based on Oracle Linux and Oracle JDK 8 (Server).
The certification of OHS on Docker does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

### Building Oracle JDK (Server JRE) base image
Before you can build these WebLogic images, you must download the Oracle Server JRE binary and drop in folder `OracleJDK/java-8` and build that image.

        $ cd OracleJDK/java-8
        $ sh build.sh

## How to Build and Run
This project offers sample Dockerfiles for Oracle HTTP Server 12cR2 (12.2.1) in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their prefered set of parameters.

### Building OHS Docker Install Images
IMPORTANT: You have to download the binaries of OHS and Oracle JDK and put them in place (see .download files inside dockerfiles/).

Download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

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

Make sure you have oracle/ohs:12.2.1-sa image built. If not go into **dockerfiles/12.2.1** and call:

        $ sh buildDockerImage.sh -v 12.2.1

### How to Build Image
Go to folder **samples/1221-OHS-domain**

Run the following command:

        $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

Verify you now have this image in place with

        $ docker images

### How to run container
1. Edit the env.list file with relevant data from Weblogic container like host, port, cluster info etc.

        For example:

        WEBLOGIC_HOST=myhost
        WEBLOGIC_PORT=7001
        WEBLOGIC_CLUSTER=myhost:9001,myhost:9002


The values of WEBLOGIC_HOST, WEBLOGIC_PORT and WEBLOGIC_CLUSTER must be valid, existing containers running WebLogic servers.

2. Run this image by calling

        $ docker run -d --env-file ./env.list -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh


   The **configureWLSProxyPlugin.sh** script will be the first script to be run inside the OHS container .
   This script will perform the following actions:
   - Starts the Node Manager and OHS server
   - Edits the mod_wl_ohs.conf.sample with values passed via env.list
   - Copies the mod_wl_ohs.conf file under INSTANCE home
   - Restarts OHS server

3. Sanity URLs check for OHS server
   - Now you can access the OHS index page @ http://localhost:7777/index.html
   - Static html page @ URL http://localhost:7777/helloWorld.html

4. Weblogic Cluster : Now you will be able to access all URLS via the OHS Listen Port 7777 (instead of using port 7001, 9001 and 9002)
    - http://myhost:7777/console
    - http://myhost:7777/$application_url_endpoint

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.

## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
