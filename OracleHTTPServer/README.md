Oracle HTTP Server on Docker
===============
This project includes quick start dockerfiles and samples for standalone Oracle HTTP Server based on Oracle Linux and Oracle JDK 8 (Server).
The certification of OHS on Docker does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## How to Build and Run
This project offers Dockerfile for Oracle HTTP Server in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh
You can also pull the Oracle Server JRE 8 image from [Oracle Container Registry](https://container-registry.oracle.com) or the [Docker Store](https://store.docker.com/images/oracle-serverjre-8).

### Building OHS Docker Image
IMPORTANT: You have to download the OHS binary and put it in place (see .download files inside dockerfiles/).

Download the required package (see .download file) and drop them in the version folder (12.2.1.2.0 or 12.2.1.3.0). Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root providing the version name with -v option.

    $ sh buildDockerImage.sh -v 12.2.1.3.0

IMPORTANT: The resulting image will have a  pre-configured domain. 

### Providing the Node Manager password
The user name and password must be supplied in a domain.properties file located in a HOST directory that you will map at Docker runtime with the -v option to the image directory /u01/oracle/bootdir. The properties file enables the scripts to configure the correct authentication for the Node Manager.

The format of the domain.properties file is key=value pair:
username=mynodemanagerusername
password=mynodemanagerpassword

### How to run container



If you want to start the OHS container without specifying any configuration for mod_weblogic:
1. To start the OHS container with oracle/ohs:12.2.1.3.0 image, run the following command:


         docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -it --name ohs -p 7777:7777 oracle/ohs:12.2.1.3.0


If you want to start the OHS container with some pre-specified mod_weblogic configuration:
1. Depending on your weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](http://docs.oracle.com/middleware/12213/webtier/develop-plugin/oracle.htm#PLGWL553)

2. Place the custom_mod_wl_ohs.conf file in a directory in the host say,"/scratch/DockerVolume/OHSVolume" and then mount this directory into the container at the location "/config".
   By doing so, the contents of host directory /scratch/DockerVolume/OHSVolume(and hence custom_mod_wl_ohs.conf) will become available in the container at the mount point.  
   This mounting can be done by using the -v option with the 'docker run' command as shown below. The following command will start the OHS container with oracle/ohs:12.2.1.3.0 image and the host   directory "/scratch/DockerVolume/OHSVolume" will get mounted at the location "/config" in the container:

         $ docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -v /scratch/DockerVolume/OHSVolume:/config -w /config -d --name ohs -p 7777:7777  oracle/ohs:12.2.1.3.0

### Stopping the  OHS instance
To stop the OHS instance, execute the following command:

      docker stop ohs (Assuming the name of conatiner is 'ohs')


To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


## Support
Oracle HTTP Server on Docker is supported by Oracle.


## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
