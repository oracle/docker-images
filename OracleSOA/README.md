SOA on Docker
=============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for both SOA 12.1.3 based on Oracle Linux and Oracle JDK 7 (Server).

## How to build and run
This project offers sample Dockerfiles for SOA 12c (12.1.3), and one Dockerfile for the 'quickstart' distribution, as well more if necessary. To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-7
        $ sh build.sh

### Building SOA Docker Install Images
**IMPORTANT:** you have to download the binary of SOA and put it in place (see `.download` files inside dockerfiles/<version>).

Before you build, choose which version and distribution you want to build an image of, then download the required packages (see .download files) and drop them in the folder of your distribution version of choice. Then go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root.

        $ sh buildDockerImage.sh -h
        Usage: buildDockerImage.sh -v [version] [-q | -i] [-s]
        Builds a Docker Image for Oracle SOA.

        Parameters:
           -v: version to build. Required.
           Choose one of: 12.1.3  
           -q: creates image based on 'quickstart' distribution
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        * select one distribution only: -q

        LICENSE CDDL 1.0 + GPL 2.0

        Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST. You might take a look at the use case samples as well below.
