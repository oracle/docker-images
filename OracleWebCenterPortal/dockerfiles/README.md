# Oracle WebCenter Portal 12.2.1.4.0 on Docker


# 1. Introduction
This project offers scripts to build an Oracle WebCenter Portal docker image based on 12.2.1.4.0 release. Use this Docker configuration to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle WebCenter Portal, see the [Oracle WebCenter Portal 12.2.1.4.0 Online Documentation](https://docs.oracle.com/en/middleware/webcenter/portal/12.2.1.4/index.html).

This project creates Oracle WebCenter Portal Docker image with a single node targeted for development and testing.

# 2. Hardware and Software Requirements
Oracle WebCenter Portal has been tested and is known to run on the following hardware and software:

## 2.1 Hardware Requirements

| Hardware  | Size  |
| :-------: | :---: |
| RAM       | 16GB  |
| Disk Space| 200GB+|

## 2.2 Software Requirements

You must install and configure [Oracle Container Runtime for Docker](https://docs.oracle.com/cd/E52668_01/E87205/html/index.html) on Oracle Linux 7 to run Oracle WebCenter Portal on Docker.

|       | Version                        | Command to verify version |
| :---: | :----------------------------: | :-----------------------: |
| OS    | Oracle Linux 7.3 or higher     | more /etc/oracle-release  |
| Docker| Docker version 17.03 or higher | docker version           |

# 3. Prerequisites
## 3.1. Mount a host directory as a data volume

You need to mount volumes, which are directories stored outside a container’s file system, to store WebLogic domain files and any other configuration files.

To mount a host directory `/scratch/wcpdocker/volumes/wcpportal`(`DATA_VOLUME`) as a data volume, execute the below command.

> The userid can be anything but it must belong to uid:guid as 1000:1000, which is same as 'oracle' user running in the container.

> This ensures 'oracle' user has access to shared volume.

```
$ sudo mkdir -p /scratch/wcpdocker/volumes/wcpportal
$ sudo chown 1000:1000 /scratch/wcpdocker/volumes/wcpportal
```

All container operations are performed as **'oracle'** user.

**Note**: If a user already exist with **'-u 1000 -g 1000'** then use the same user. Or modify any existing user to have uid-gid as **'-u 1000 -g 1000'**

## 3.2. Database
You need to have a running database container or a database running on any machine. 
The database connection details are required for creating WebCenter Portal specific RCU schemas while configuring WebCenter Portal domain. 

## 3.3 Oracle Fusion Middleware Infrastructure image
>1. Sign in to Oracle Container Registry. Click the Sign in link which is on the top-right of the Web page.
> 2. Click Middleware and then click Continue for the fmw-infrastructure repository.
> 3. Click Accept to accept the license agreement.
> 4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :
```
$ docker login container-registry.oracle.com
$ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4.0
```


The Oracle Database image can be pulled from the  [Oracle Container Registry](https://container-registry.oracle.com) or you can build your own using the Dockerfiles and scripts from the [Oracle Database section of this repo](https://github.com/oracle/docker-images/tree/master/OracleDatabase).

# 4. Building Oracle WebCenter Portal Docker Images
IMPORTANT: To build the Oracle WebCenter Portal image, you must first download the required version of the Oracle WebCenter Portal  binaries these install binaries are required to create the Oracle WebCenter Portal image. These binaries must be downloaded and copied into the folder with the same version for e.g. 12.2.1.4.0 binaries need to be dropped into `../OracleWebCenterPortal/dockerfiles/12.2.1.4`. 

The binaries can be downloaded from the [Here](https://www.oracle.com/middleware/technologies/webcenter-portal-download.html#).

Extract the downloaded zip files and copy `fmw_12.2.1.4.0_wcportal.jar` files under `dockerfiles/12.2.1.4` for building Oracle WebCenter Portal 12.2.1.4 image.

To build Oracle WebCenter Portal Docker image, go to folder located at OracleWebCenterPortal/dockerfiles/ and run the following command:
- Use the resulting image name to create containers 

```
$ sh buildDockerImage.sh -v 12.2.1.4
```


**IMPORTANT**: The resulting image has automated scripts to:
-  Create WebCenter Portal Database Schema
-  Create and configure a WebLogic domain
-  Run WebCenter Portal Configuration Process while creating the Admin Container

#  FAQs

##### 1. What is the usage of buildDockerImage.sh file?
```   
   $ sh buildDockerImage.sh
   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle WebCenter Portal.
   Parameters:
      -v: version to build. Required.
   Choose: 12.2.1.x
      -c: enables Docker image layer cache during build
      -s: skips the MD5 check of packages
      
   LICENSE UPL 1.0
 Copyright (c) 2017, 2020, Oracle and/or its affiliates. All rights reserved.
```
##### 2. How do I build an Oracle Fusion Middleware Infrastructure 12.2.1.x base image?
If you want to build your own Oracle Fusion Middleware Infrastructure image, use the Docker files and scripts in the [Oracle FMW Infrastructure](https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure) GitHub repository.
##### 3. How to fix yum.oracle.com connectivity error?
The errors mean that the host is not able to connect to external registries for update. To access external registries and build a Docker image, set up environment variables for proxy server as below:

```
$ export http_proxy=http://www-yourcompany.com:80 
$ export https_proxy=http://www-yourcompany.com:80 
$ export HTTP_PROXY=http://www-yourcompany.com:80 
$ export HTTPS_PROXY=http://www-yourcompany.com:80 
$ export NO_PROXY=localhost,.yourcompany.com 
```

## Copyright
 Copyright (c) 2020,2021 Oracle and/or its affiliates. All rights reserved.
