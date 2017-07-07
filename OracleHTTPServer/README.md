Oracle HTTP Server on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start dockerfiles and samples for Oracle HTTP Server Standalone 12.2.1.2.0 based on Oracle Linux and Oracle JDK 8 (Server).
The certification of OHS on Docker does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## How to Build and Run
This project offers Dockerfile for Oracle HTTP Server 12.2.1.2.0 in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh
You can also pull the Oracle Server JRE 8 image from Oracle Container Registry or the Docker Store.

### Building OHS Docker Image
IMPORTANT: You have to download the OHS binary and put it in place (see .download files inside dockerfiles/).

Download the required package (see .download file) and drop them in the folder 12.2.1.2.0. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

    $ sh buildDockerImage.sh -v 12.2.1.2.0

IMPORTANT: The resulting image will have a  pre-configured domain. 

### How to run container

If we want to start the OHS container without specifying any configuration for mod_weblogic:
1. To start the OHS container with above oracle/ohs:12.2.1.2.0-sa image, run the following command:

         docker run -it --name ohs -p 7777:7777 oracle/ohs:12.2.1.2.0-sa


If we want to start the OHS container with some pre-specified mod_weblogic configuration:
1. Depending on your weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](http://docs.oracle.com/middleware/12212/webtier/develop-plugin/oracle.htm#PLGWL553)

2. Place the custom_mod_wl_ohs.conf file in a directory in the host say,"/scratch/DockerVoulme/OHSVolume" and then mount this directory into the container as a volume.

3. To start the OHS Container with above oracle/ohs:12.2.1.2.0-sa image, run command from the directory which has been mounted as a volume.

         For e.g
         $ cd /scratch/DockerVolume/OHSVolume
         $ docker run -v `pwd`:/u01/oracle/ohssa/user_projects -w /u01/oracle/ohssa/user_projects -d --name ohs -p 7777:7777  oracle/ohs:12.2.1.2.0-sa configureWLSProxyPlugin.sh


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

### Stopping and re-starting OHS instance
To stop the OHS instance, execute the following steps:
1. Exec into the container and execute /bin/bash (Assuming the name of container is 'ohs')

      docker exec -it ohs /bin/bash

2. Navigate to /u01/oracle/ohssa/oracle_common/common/bin

      cd /u01/oracle/ohssa/oracle_common/common/bin

3. Execute stop-ohs.py 
 
      ./wlst.sh /u01/oracle/container-scripts/stop-ohs.py


To re-start the OHS instance, execute the following steps:
1.Exec into the container and execute /bin/bash (Assuming the name of container is 'ohs')

      docker exec -it ohs /bin/bash

2. Invoke restartOHS.sh

      ./u01/oracle/container-scripts/restartOHS.sh


## Node Manager Password

On the first startup of the container a random password will be generated for the Node Manager in the OHS domain. You can find this password in the container logs generated during the startup of the container.  Look for the string:

        ----> 'OHS' Node Manager password:

To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


## Support
Oracle HTTP Server on Docker is supported by Oracle.


## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
