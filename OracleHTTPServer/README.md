# Oracle HTTP Server in containers
===================================
This project includes quick start dockerfiles and samples for standalone Oracle HTTP Server 12.2.1.4.0 and JDK 8 and 14.1.2.0.0 JDK 17 and 21 based on Oracle Linux 8 and 9.
The certification of OHS in containers does not require the use of any file presented in this repository.
Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

The samples in this repository are for trial use cases only. For alternative methods, we suggest obtaining base Oracle HTTP Server images from the [Oracle Container Registry](https://container-registry.oracle.com/), using the open source [WebLogic Image Tool](https://oracle.github.io/weblogic-image-tool) to create custom images.

## How to Build and Run
This project offers Dockerfile for Oracle HTTP Server in standalone mode. To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage

The **buildDockerImage.sh** script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        "$ cd ../OracleJava/java-8"
        "$ sh build.sh"

You can also pull the Oracle Server JRE 8 image from [Oracle Container Registry](https://container-registry.oracle.com).

### Building OHS Container Image
IMPORTANT: You have to download the OHS binary and put it in place (see .download files inside dockerfiles/).

Download the required package (see .download file) and drop them in the version folder (12.2.1.4.0). Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root providing the version name with -v option.

        "$ sh buildDockerImage.sh -v 12.2.1.4.0"

IMPORTANT: The resulting image will have a  pre-configured domain.

### Providing the Node Manager password
The user name and password must be supplied in a domain.properties file located in a HOST directory that you will map at runtime with the -v option to the image directory /u01/oracle/bootdir. The properties file enables the scripts to configure the correct authentication for the Node Manager.

The format of the domain.properties file is key=value pair:
username=mynodemanagerusername
password=mynodemanagerpassword

### How to run container
If you want to start the OHS container without specifying any configuration for mod_weblogic:
1. To start the OHS container with oracle/ohs:12.2.1.4.0 image, run the following command:

        "$ docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -it --name ohs -p 7777:7777 oracle/ohs:12.2.1.4.0"

If you want to start the OHS container with some pre-specified mod_weblogic configuration:
1. Depending on your weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](https://docs.oracle.com/en/middleware/fusion-middleware/web-tier/12.2.1.4/develop-plugin/oracle.html#GUID-A463B189-DF47-4932-8B96-FD4F5FEC8D56)

2. Place the custom_mod_wl_ohs.conf file in a directory in the host say,"/scratch/DockerVolume/OHSVolume" and then mount this directory into the container at the location "/config".
   By doing so, the contents of host directory /scratch/DockerVolume/OHSVolume(and hence custom_mod_wl_ohs.conf) will become available in the container at the mount point.
   This mounting can be done by using the -v option with the 'docker run' command as shown below. The following command will start the OHS container with oracle/ohs:12.2.1.4.0 image and the host   directory "/scratch/DockerVolume/OHSVolume" will get mounted at the location "/config" in the container:

        "$ docker run -v `HOST PATH where the domain.properties file is`:/u01/oracle/bootdir -v /scratch/DockerVolume/OHSVolume:/config -w /config -d --name ohs -p 7777:7777  oracle/ohs:12.2.1.4.0"

### Stopping the  OHS instance
To stop the OHS instance, execute the following command:

        "$ docker stop <Container name>"

To look at the Container logs run:

        "$ docker logs --details <Container-id>"

## Support
Oracle HTTP Server in containers  is supported by Oracle.

## License
To download and run Oracle HTTP Server 12c Distribution regardless of inside or outside a container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a container, you must download the binary from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleHTTPServer](./) repository required to build the images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2019, 2025, Oracle and/or its affiliates. All rights reserved.
