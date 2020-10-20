Oracle Access Management (OAM) on Docker
========================================

## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OAM on Docker](#prerequisites-for-oam-on-docker)
3. [Prerequisites for OAM on Kubernetes](#prerequisites-for-oam-on-kubernetes)
4. [Building the OAM Image](#building-the-oam-image)
5. [OAM Docker Container Configuration](#oam-docker-container-configuration)
6. [OAM Kubernetes Configuration](#oam-kubernetes-configuration)


## Introduction

This project offers Dockerfiles and scripts to build and configure an Oracle Access Management image based on 12cPS4 (12.2.1.4.0) release.
Use this image to facilitate installation, configuration, and environment setup for DevOps users. 

This Image includes binaries for OAM Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OAM specific Managed Servers.

## Prerequisites for OAM on Docker

The following prerequisites are necessary before building OAM Docker images:

* A working installation of Docker 18.03 or later

## Prerequisites for OAM on Kubernetes

Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oam/prerequisites) in the Oracle Access Management Kubernetes documentation.


## Building the OAM Image

An OAM image can be created and/or made available for deployment in the following ways:

1. Build your own OAM image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own OAM 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. see [Building an OAM Image using Image Tool](https://github.com/oracle/docker-images/tree/master/OracleAccessManagement/imagetool/12.2.1.4.0).

1. Build your own OAM image using the dockerfile samples. To customize the image for specific use-cases, Oracle provides dockerfile samples and build scripts. For more information, see [Building an Oracle Access Management Image using Dockerfile Samples](https://github.com/oracle/docker-images/tree/master/OracleAccessManagement/dockerfiles/12.2.1.4.0).


## OAM Docker Container Configuration
 
To configure the OAM Containers on Docker only, follow the tutorial [Creating Oracle Access Management Docker Containers](https://docs.oracle.com/en/middleware/idm/access-manager/12.2.1.4/tutorial-oam-docker/)

## OAM Kubernetes Configuration

To configure the OAM Containers with Kubernetes see the [Oracle Access Management on Kubernetes](https://oracle.github.io/fmw-kubernetes/oam/) documentation.
  
## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.