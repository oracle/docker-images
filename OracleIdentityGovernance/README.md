Oracle Identity Governance (OIG) on Docker
==========================================


## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OIG on Docker](#prerequisites-for-oig-on-docker)
3. [Prerequisites for OIG on Kubernetes](#prerequisites-for-oig-on-kubernetes)
4. [Installing the OIG Docker Image](#installing-the-oig-docker-image)
5. [OIG Docker Container Configuration](#oig-docker-container-configuration)
6. [OIG Kubernetes Configuration](#oig-kubernetes-configuration)

## Introduction

This project offers Dockerfiles and scripts to build and configure an Oracle Identity Governance image based on 12cPS4 (12.2.1.4.0) release.
Use this image to facilitate installation, configuration, and environment setup for DevOps users. 

## Prerequisites for OIG on Docker

The following prerequisites are required for building OIG Docker images:

* A working installation of Docker 18.03 or later

### Hardware Requirements

| Hardware  | Size                                                      |
| :-------- | :---------------------------------------------------------|
| RAM       | Min 16GB                                                  |
| Disk Space| Min 50GB (ensure 10G+ available in the Docker Root Dir)   |

## Prerequisites for OIG on Kubernetes

Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oig/prerequisites) in the Oracle Identity Governance Kubernetes documentation.

## Installing the OIG Image

An OIG image can be created and/or made available for deployment in the following ways:

1. Build your own OIG image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own OIG 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an OIG Image using Image Tool](https://github.com/oracle/docker-images/tree/master/OracleIdentityGovernance/imagetool/12.2.1.4.0).

1. Build your own OIG image using the dockerfile samples. To customize the docker image for specific use-cases, Oracle provides dockerfile samples and build scripts. For more information, see [Building an Oracle Identity Governance Image using Dockerfile Samples](https://github.com/oracle/docker-images/tree/master/OracleIdentityGovernance/dockerfiles/12.2.1.4.0).


## OIG Docker Container Configuration
 
To configure the OIG Containers on Docker only, follow the tutorial [Creating Oracle Identity Governance Docker Containers](https://docs.oracle.com/en/middleware/idm/identity-governance/12.2.1.4/tutorial-oig-docker/)

## OIG Kubernetes Configuration

To configure the OIG Containers with Kubernetes see the [Oracle Identity Governance on Kubernetes](https://oracle.github.io/fmw-kubernetes/oig/) documentation.
  
## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
	
	
