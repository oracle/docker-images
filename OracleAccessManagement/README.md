Oracle Access Management (OAM) on Docker
========================================

## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OAM on Docker](#prerequisites-for-oam-on-docker)
3. [Prerequisites for OAM on Kubernetes](#prerequisites-for-oam-on-kubernetes)
4. [Installing the OAM Docker Image](#installing-the-oam-docker-image)
5. [OAM Docker Container Configuration](#oam-docker-container-configuration)
6. [OAM Kubernetes Configuration](#oam-kubernetes-configuration)
7. [Appendix A: Using an Oracle Database Docker Image for OAM](#appendix-a-using-an-oracle-database-docker-image-for-oam)


## Introduction

This project offers Dockerfiles and scripts to build and configure an Oracle Access Management image based on 12cPS4 (12.2.1.4.0) release.
Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

This Image includes binaries for OAM Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OAM specific Managed Servers.

## Prerequisites for OAM on Docker

The following prerequisites are necessary before building OAM Docker images:

* A working installation of Docker 18.03 or later
* A running Oracle Database 12.2.0.1 or later. This database can be installed anywhere. The database must be a supported version for OAM as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx). If you require a test database, an Oracle Database Docker image can be used. For instructions on installing and running an Oracle Database Docker image refer to section [Appendix A: Using an Oracle Database Docker Image for OAM](#appendix-a-using-an-oracle-database-docker-image-for-oam) at the end of this README.

## Prerequisites for OAM on Kubernetes
Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oam/prerequisites) in the Oracle Access Management Kubernetes documentation.


## Installing the OAM Docker Image

An OAM Docker image can be created and/or made available for deployment in a Docker environment in the following ways:

1. Download a pre-built OAM Docker image from [My Oracle Support](https://support.oracle.com) (Patch 31979421).  This image contains the latest bundle patch and one-off patches for Oracle Access Management 12.2.1.4.0.

2. Build your own OAM Docker image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own OAM 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. see [Building an OAM Docker Image using Image Tool](https://github.com/oracle/docker-images/tree/master/OracleAccessManagement/imagetool/12.2.1.4.0).


## OAM Docker Container Configuration
 
To configure the OAM Containers on Docker only, follow the tutorial [Creating Oracle Access Management Docker Containers](https://docs.oracle.com/en/middleware/idm/access-manager/12.2.1.4/tutorial-oam-docker/)

## OAM Kubernetes Configuration

To configure the OAM Containers with Kubernetes see the [Oracle Access Management on Kubernetes](https://oracle.github.io/fmw-kubernetes/oam/) documentation.


**Note**: Database docker images are not supported in production and should only be used for testing with Docker only configurations and not Kubernetes.

OAM requires a database to store the configuration information and RCU schema information. If you do not have a database available and require one for testing, then you can use an Oracle Database Docker image. 
 

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
