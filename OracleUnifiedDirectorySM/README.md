Oracle Unified Directory Service Manager (OUDSM) on Docker
==========================================================

## Contents

1. [Introduction](#introduction)
2. [Prerequisites for OUDSM on Docker](#prerequisites-for-oudsm-on-docker)
3. [Prerequisites for OUDSM on Kubernetes](#prerequisites-for-oudsm-on-kubernetes)
4. [Installing the OUDSM Docker Image](#installing-the-oudsm-docker-image)
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

## Installing the OUDSM Docker Image

An OUDSM Docker image can be created and/or made available for deployment in a Docker environment in the following ways:

1. Download a pre-built OUDSM Docker image from [My Oracle Support](https://support.oracle.com) (Patch 31979410).  This image contains the latest bundle patch and one-off patches for Oracle Unified Directory Services Manager 12.2.1.4.0.
2. Build your own OUDSM Docker image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own OUDSM 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an OUDSM Docker Image using Image Tool](https://github.com/oracle/docker-images/OracleUnifiedDirectorySM/imagetool/12.2.1.4.0).)

## OUDSM Docker Container Configuration

To configure the OUD Containers on Docker only, see the tutorial [Creating Oracle Unified Directory Docker Containers](https://docs-uat.us.oracle.com/en/middleware/idm/unified-directory/12.2.1.4/tutorial-oudsm-docker/).

## OUDSM Kubernetes Configuration

To configure the OUD Containers with Kubernetes see the [Oracle Unified Directory on Kubernetes](https://oracle.github.io/fmw-kubernetes/oudsm/prerequisites) documentation.
