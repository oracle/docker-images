Oracle Unified Directory Service Manager (OUDSM) on Docker
==========================================================

## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OUDSM on Docker](#prerequisites-for-oudsm-on-docker)
3. [Prerequisites for OUDSM on Kubernetes](#prerequisites-for-oudsm-on-kubernetes)
4. [Installing the OUDSM Pre-built Docker Image](#installing-the-oudsm-pre-built-docker-image)
5. [OUDSM Docker Container Configuration](#oudsm-docker-container-configuration)
6. [OUDSM Kubernetes Configuration](#oudsm-kubernetes-configuration)

## Introduction

Oracle Unified Directory Services Manager (OUDSM) is an interface for managing instances of Oracle Unified Directory. OUDSM enables you to configure the structure of the directory, define objects in the directory, add and configure users, groups, and other entries. OUDSM is also the interface you use to manage entries, schema, security, and other directory features.

This project offers Dockerfiles and scripts to build and configure an Oracle Unified Directory Services Manager image based on 12cPS4 (12.2.1.4.0) release. Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

This Image refers to binaries for OUDSM Release 12.2.1.4.0.

***Image***: oracle/oudsm:12.2.1.4.0

## Prerequisites for OUDSM on Docker

The following prerequisites are applicable when using the OUD Docker image on Docker only:

* A working installation of Docker 18.03 or later

## Prerequisites for OUDSM on Kubernetes

Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oudsm/prerequisites) in the Oracle Unified Directory Kubernetes documentation.

## Installing the OUDSM Pre-built Docker Image

To pull the image:

1. Launch a browser and access the [Oracle Container Registry](https://container-registry.oracle.com/).
2. Click **Sign** In and login with your username and password.
3. In the **Search** field enter **Oracle Unified Directory Services Manager** and press **Enter**.
4. Click **Oracle Unified Director Services Manager**.
5. In the **Terms and Conditions** box, select Language as **English**. Click Continue and ACCEPT "**Terms and Restrictions**".
6. On your Docker environment login to the Oracle Container Registry and enter your Oracle SSO username and password when prompted:

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
ORACLE CONFIDENTIAL. For authorized use only. Do not distribute to third parties.
```

Pull the OUDSM image:

```
$ docker pull container-registry.oracle.com/middleware/oudsmxxxxxxxxxx
The output should look similar to the following:
Trying to pull repository container-registry.oracle.com/middleware/oudsmxxxx ...
12.2.1.4.0: Pulling from container-registry.oracle.com/middleware/oudsmxxxx
cd17e56c322c: Pull complete
f3b42f865a07: Pull complete
29803e13bfe3: Pull complete
18d8ee659547: Pull complete
f66a1b7a89d0: Pull complete
ff031b2e3d8e: Pull complete
Digest: sha256:202ae2cf91109ae7492875924a705e0893c9d34ba89819dc064dd67e8da181eb
Status: Downloaded newer image for container-registry.oracle.com/middleware/oamxxxx
container-registry.oracle.com/middleware/oudsm:12.2.1.4.0
```

Run the docker images command to show the image is installed into the repository:

```
$ docker images
The output should look similar to this for docker only users:
REPOSITORY        TAG             IMAGE ID        CREATED          SIZE
oracle/oudsm      12.2.1.4.0      4896be1e0f6b    6 minutes ago    3.07GB
```

The OUDSM docker image is now installed successfully and ready for configuration.

## OUDSM Docker Container Configuration

To configure the OUD Containers on Docker only, see the tutorial [Creating Oracle Unified Directory Docker Containers](https://docs-uat.us.oracle.com/en/middleware/idm/unified-directory/12.2.1.4/tutorial-oudsm-docker/).

## OUDSM Kubernetes Configuration

To configure the OUD Containers with Kubernetes see the [Oracle Unified Directory on Kubernetes](https://oracle.github.io/fmw-kubernetes/oudsm/prerequisites) documentation.
