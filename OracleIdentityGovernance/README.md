Oracle Identity Governance (OIG) on Docker
==========================================


## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OIG on Docker](#prerequisites-for-oig-on-docker)
3. [Prerequisites for OIG on Kubernetes](#prerequisites-for-oig-on-kubernetes)
4. [Installing the OIG Docker Image](#installing-the-oig-docker-image)
5. [OIG Docker Container Configuration](#oig-docker-container-configuration)
6. [OIG Kubernetes Configuration](#oig-kubernetes-configuration)
7. [Appendix A: Using an Oracle Database Docker Image for OIG](#appendix-a-using-an-oracle-database-docker-image-for-oig)

## Introduction

This project offers Dockerfiles and scripts to build and configure an Oracle Identity Governance image based on 12cPS4 (12.2.1.4.0) release.
Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

## Prerequisites for OIG on Docker

The following prerequisites are required for building OIG Docker images:

* A working installation of Docker 18.03 or later
* Docker-compose 1.25.4 or higher
* A running Oracle Database 12.2.0.1 or later. This database can be installed anywhere. The database must be a supported version for OIG as outlined in [Oracle Fusion Middleware 12c certifications](https://www.oracle.com/technetwork/middleware/fmw-122140-certmatrix-5763476.xlsx), and must meet the requirements as outlined in [About Database Requirements for an Oracle Fusion Middleware Installation](http://www.oracle.com/pls/topic/lookup?ctx=fmw122140&id=GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A).  If you require a test database, an Oracle Database Docker image can be used. For instructions on installing and running an Oracle Database Docker image refer to section [Appendix A: Using an Oracle Database Docker Image for OIG](#appendix-a-using-an-oracle-database-docker-image-for-oig) at the end of this README.

### Hardware Requirements

| Hardware  | Size                                              |
| :-------- | :-------------------------------------------------|
| RAM       | Min 16GB                                          |
| Disk Space| Min 50GB (ensure 10G+ available in Docker Home)   |

## Prerequisites for OIG on Kubernetes

Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oig/prerequisites) in the Oracle Identity Governance Kubernetes documentation.

## Installing the OIG Docker Image

An OIG Docker image can be created and/or made available for deployment in a Docker environment in the following ways:

1. Download a pre-built OIG Docker image from [My Oracle Support](https://support.oracle.com) (Patch 31979475).  This image contains the latest bundle patch and one-off patches for Oracle Identity Governance 12.2.1.4.0.

1. Build your own OIG Docker image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own OIG 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an OIG Docker Image using Image Tool](https://github.com/oracle/docker-images/tree/master/OracleIdentityGovernance/imagetool/12.2.1.4.0).


## OIG Docker Container Configuration
 
To configure the OIG Containers on Docker only, follow the tutorial [Creating Oracle Identity Governance Docker Containers](https://docs.oracle.com/en/middleware/idm/identity-governance/12.2.1.4/tutorial-oig-docker/)

## OIG Kubernetes Configuration

To configure the OIG Containers with Kubernetes see the [Oracle Identity Governance on Kubernetes](https://oracle.github.io/fmw-kubernetes/oig/) documentation.

## Appendix A: Using an Oracle Database Docker Image for OIG

OIG requires a database to store the configuration information and RCU schema information. If you do not have a database available and require one for testing, then you can use an Oracle Database Docker image. The instructions below show how to install the database image and start the container.
 
### Pulling the Oracle Database Image

1. Launch a browser and access the [Oracle Container Registry](https://container-registry.oracle.com/).
1. Click **Sign In** and login with your username and password.
1. In the **Search** field enter **enterprise** and press **Enter**.
1. Click **enterprise** Oracle Database Enterprise Edition.
1. In the **Terms and Conditions** box, select Language as **English**. Click **Continue** and ACCEPT "**Terms and Restrictions**".
1. On your Docker environment login to the Oracle Container Registry and enter your Oracle SSO username and password when prompted:

   ```
   $ docker login container-registry.oracle.com
   Username: <username>
   Password: <password>
   ```
   
   For example:
   
   ```
   $ docker login container-registry.oracle.com
   Username: joe.bloggs@example.com
   Password:
   Login Succeeded 
   ```
   
1. Pull the Oracle Database image:
  
   ```
   $ docker pull container-registry.oracle.com/database/enterprise:19.3.0.0
   ```
   
   The output will look similar to the following:	
   
   ```
   Trying to pull repository container-registry.oracle.com/database/enterprise ...
   19.3.0.0: Pulling from container-registry.oracle.com/database/enterprise
   35defbf6c365: Pull complete
   ...
   b7fe2df9722e: Pull complete
   Digest: sha256:9b28cbc568bc58fb085516664369930efbd943d22fa24299c68651586e3ef668
   Status: Downloaded newer image for container-registry.oracle.com/database/enterprise:19.3.0.0
   ```
	
1. Run the `docker tag` to tag the image as follows:

   ```
   [dockeruser@mydockerhost]$ docker tag container-registry.oracle.com/database/enterprise:19.3.0.0 localhost/oracle/database:19.3.0.0-ee
   ```
	
1. Run the `docker images` command to show the image is installed into the repository. The output should look similar to this:	
	
   ```
   $ docker images
   REPOSITORY                                        TAG           IMAGE ID      CREATED       SIZE
   container-registry.oracle.com/database/enterprise 19.3.0.0      2e375ab66980  2 months ago   6.66GB
   localhost/oracle/database                         19.3.0.0-ee   2e375ab66980  2 months ago   6.66GB
   ```

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
