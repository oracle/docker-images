Oracle Unified Directory Service Manager (OUDSM) on Docker
==========================================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Hardware and Software Requirements](#2-hardware-and-software-requirements)
3. [Prerequisites](#3-prerequisites)
4. [Building OUDSM Docker Image](#4-loading-or-building-oudsm-docker-image)
5. [Preparing to Run OUDSM Docker Image](#5-preparing-to-run-oudsm-docker-image)
6. [Running OUDSM Docker Container](#6-running-oudsm-docker-container)

# 1. Introduction
This project offers Dockerfile and scripts to build an Oracle Unified Directory Service Manager image based on 12cPS4 (12.2.1.4.0) release. Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

This Image refers to binaries for OUD Release 12.2.1.4.0 and it has the capability to create FMW Infrastructure domain with OUDSM application deployed in container with OUDSM deployed which can be targeted for development and testing.

***Image***: oracle/oudsm:12.2.1.4.0

# 2. Hardware and Software Requirements
Oracle Unified Directory Service Managedr Docker Image has been tested and is known to run on following hardware and software:

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

# 3. Prerequisites

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

## 3.2 Pulling Oracle FMW Infrastructure 12.2.1.4.x image
You can pull Oracle FMW Infrastructure 12.2.1.4.x image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the FMW Infrastructure 12.2.1.4.x image, re-tag the image so that it works with the dependent Dockerfiles which refer to the FMW Infrastructure 12.2.1.4.x image through oracle/fmw-infrastructure:12.2.1.4.0.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions". fmw-infrastructure images can be found under Middleware section.

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Middleware** and then click on **fmw-infrastructure**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

        
        $ docker login container-registry.oracle.com
        $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222
        $ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-191222 oracle/fmw-infrastructure:12.2.1.4.0

# 4. Loading or Building OUDSM Docker Image

## 4.1 Loading OUDSM Docker Image
If OUDSM Docker Image is to be loaded into a Docker environment through a TAR file (oracle_oud_122140.tar.gz), the following command can be invoked to load the image.

        
        $ docker load < oracle_oudsm_122140.tar.gz

If the TAR file (oracle_oudsm_122140.tar.gz) containing the OUDSM Docker Image is accessible via an HTTP URL, the following command can be invoked to load the image.
        
        $ wget -O - http://<URL to access oracle_oudsm_122140.tar.gz> | docker load
        
You should see output similar to that below:

        12a9cd7d069e: Loading layer [==================================================>]  124.4MB/124.4MB
        876692f4cd07: Loading layer [==================================================>]  11.03MB/11.03MB
        53213312d4cf: Loading layer [==================================================>]  20.99kB/20.99kB
        0b7966b618c2: Loading layer [==================================================>]  152.2MB/152.2MB
        76f98c800bc0: Loading layer [==================================================>]  2.048GB/2.048GB
        ee450dbee59a: Loading layer [==================================================>]  27.65kB/27.65kB
        4ffc56e3f0b1: Loading layer [==================================================>]  8.518MB/8.518MB
        05b62dc31409: Loading layer [==================================================>]  117.9MB/117.9MB
        Loaded image: oracle/oudsm:12.2.1.4.0

If you run the 'docker images' command, loaded image should be displayed similar to the output below:

       $ docker images
       REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
       oracle/oudsm                                   12.2.1.4.0          a2d106db1f67        2 hours ago         2.44GB
       ....

## 4.2 Building OUDSM Docker Image

### Clone and download Oracle Unified Directory Service Manager docker scripts and binary file
1. Clone the [GitHub repository](https://github.com/oracle/docker-images) or download and extract the OUDSM Docker Repository TAR file (OracleUnifiedDirectorySM.tar.gz).
The repository contains Docker files and scripts to build Docker images for Oracle products.
2. You must download and save the Oracle Unified Directory 12.2.1.4.0 binary into the cloned/downloaded repository folder at location : `OracleUnifiedDirectorySM/dockerfiles/12.2.1.4.0/` (see **Checksum** for file name which is inside dockerfiles/12.2.1.4.0/oud.download).

### Build OUDSM Docker Image using cloned/downloaded docker-images repository
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

# 5. Preparing to Run OUDSM Docker Image

## 5.1. Mount a host directory as a data volume
You need to mount volume(s), which are directories stored outside a container's file system, to store OUDSM domain files and any other configuration. The default location of the `user_projects` volume in the container is `/u01/oracle/user_projects` (under this directory, the OUDSM domain directory is created). 

This option lets you mount a directory from your host to a container as volume. This volume is used to store OUDSM domain files. 

To prepare a host directory (for example: /scratch/test/oudsm_user_projects) for mounting as a data volume, execute the command below:

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.
> This ensures 'oracle' user has access to shared volume.

```
sudo su - root
mkdir -p /scratch/test/oudsm_user_projects
chown 1000:1000 /scratch/test/oudsm_user_projects
exit
```

All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

## 5.2 Bridged Network for running containers with OUD Instances/Components
In Docker, a bridged network is a software bridge which allows containers connected to the bridge to communicate, while isolating containers that are not connected to the bridge. You will be running OUD 12c containers on a single Docker daemon host so require a bridged network.

Create the Docker network for the Infra servers to run:

	$ docker network create -d bridge InfraNET

When creating different containers with OUD components, the same network can be specified for connectivity across containers.

# 6. Running OUDSM Docker Container

  1. Start/Create a container with Administration Server and OUDSM application from the image created through steps mentioned in previous section.

  Following are the parameters which can be passed to `docker run` through either env-file or command line parameters.

* ADMIN_USER=weblogic
* ADMIN_PASS=Oracle123
* ADMIN_PORT=7001
* ADMIN_SSL_PORT=7002


	  $ docker run -d -p 7001:7001 -p 7002:7002 --name <container-name> --network=InfraNET \
	  --volume /scratch/test/oudsm_user_projects:/u01/oracle/user_projects oracle/oudsm:12.2.1.4.0

  2. Access interfaces exposed by OUDSM container:


	 $ docker inspect --format '{{.NetworkSettings.Networks.InfraNET.IPAddress}}' <container-name>

> This returns the IP address of the container (for example, `xxx.xx.x.x`).

  Because the container ports are mapped to the host port (through -p parameter for `docker run`), you can access it using the `hostname` as well.

  Go to your browser and enter `http://xxx.xx.x.x:7001/console` to access WLS Console.

  Go to your browser and enter `http://xxx.xx.x.x:7001/oudsm` to access OUDSM Console.


# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [docker-images/OracleUnifiedDirectorySM](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>
