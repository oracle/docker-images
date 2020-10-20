Building an Oracle Unified Directory Services Manager Image with Dockerfiles and Scripts
========================================================================================

## Contents

1. [Introduction](#1-introduction)
2. [Hardware and Software Requirements](#2-hardware-and-software-requirements)
3. [Build Oracle JDK/Oracle FMW Infrastructure image](#3-build-oracle-jdkoracle-fmw-infrastructure-image)
4. [Building OUDSM Docker image](#4-building-oudsm-docker-image)

# 1. Introduction
This project offers scripts to build an Oracle Unified Directory Service Manager image based on 12cPS4 (12.2.1.4.0) release. Use this image to facilitate installation, configuration, and environment setup for DevOps users. 

This image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create an FMW Infrastructure domain with the OUDSM application deployed in a container with OUDSM deployed which can be targeted for development and testing.

***Image***: `oracle/oudsm:12.2.1.4.0`

# 2. Hardware and Software Requirements
Oracle Unified Directory Service Managed Services image has been tested and is known to run on following hardware and software:

## 2.1 Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## 2.2 Software Requirements

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 18.03 or higher | docker version            |

# 3. Build Oracle JDK/Oracle FMW Infrastructure image

To build an OUDSM image either you can start from building the Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle JDK/Oracle Fusion Middleware Infrastructure image. The images are available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there. Steps to obtain the images from the [Oracle Container Registry](https://container-registry.oracle.com), or to build the images are provided in the steps below:

## 3.1 Pulling the Oracle JDK (Server JRE) base image
You can pull the Oracle Server JRE 8 image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the Server JRE 8 image, re-tag the image so that it works with the dependent Dockerfiles which refer to the JRE 8 image through oracle/serverjre:8.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions".

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Java** and then click on **serverjre**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/java/serverjre:8
        $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8

## 3.2 How to build the Oracle Java image

Please refer to [README.md](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) under docker/OracleJava for details on how to build Oracle Database image.

https://github.com/oracle/docker-images/tree/master/OracleJava/README.md

## 3.3 Pulling Oracle FMW Infrastructure 12.2.1.4.x image
You can pull Oracle FMW Infrastructure 12.2.1.4.x image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the FMW Infrastructure 12.2.1.4.x image, re-tag the image so that it works with the dependent Dockerfiles which refer to the FMW Infrastructure 12.2.1.4.x image through oracle/fmw-infrastructure:12.2.1.4.0.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions". fmw-infrastructure images can be found under Middleware section.

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Middleware** and then click on **fmw-infrastructure**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222
        $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222 oracle/fmw-infrastructure:12.2.1.4.0

## 3.4 Building Oracle Fusion Middleware Infrastructure Docker Install image

Please refer to [README.md](https://github.com/oracle/docker-images/blob/master/OracleFMWInfrastructure/README.md) under docker/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.

# 4. Building OUDSM Docker image

## Clone and download Oracle Unified Directory Service Manager docker scripts and binary file
1. Clone the [GitHub repository](https://github.com/oracle/docker-images) or download and extract the OUDSM Docker Repository TAR file (OracleUnifiedDirectorySM.tar.gz).
The repository contains Docker files and scripts to build Docker images for Oracle products.
2. You must download and save the Oracle Unified Directory 12.2.1.4.0 binary into the cloned/downloaded repository folder at location : `OracleUnifiedDirectorySM/dockerfiles/12.2.1.4.0/` (see **Checksum** for file name which is inside dockerfiles/12.2.1.4.0/oud.download).

## Build OUDSM Docker Image using cloned/downloaded docker-images repository
To assist in building the image, you can use the [`buildDockerImage.sh`](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

**IMPORTANT**: If you are building the Oracle Unified Directory Service Manager image, you must first download the Oracle Unified Directory 12.2.1.4.0 binary (fmw_12.2.1.4.0_oud.jar) and locate it in the folder, `./dockerfiles/12.2.1.4.0`.

Note: Copy the **fmw_12.2.1.4.0_oud.jar** under the directory "OracleUnifiedDirectorySM/dockerfiles/12.2.1.4.0"

    Build script "buildDockerImage.sh" is located at "OracleUnifiedDirectorySM/dockerfiles"

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version]
        Builds a Docker Image for Oracle Unified Directory Service Manager

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.4.0
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleUnifiedDirectorySM](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
