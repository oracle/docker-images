# Oracle Internet Directory

## Contents

1. [Introduction](#introduction)
2. [Building the Oracle Internet Directory Image](#building-the-oracle-internet-directory-image)
3. [Oracle Internet Directory Container Configuration](#oracle-internet-directory-container-configuration)
4. [Deploying Oracle Internet Directory on Kubernetes](#deploying-oracle-internet-directory-on-kubernetes)


## Introduction

This project offers Dockerfiles and scripts to build and configure an Oracle Internet Directory (OID) image based on the 12cPS4 (12.2.1.4.0) release.

Use this image to facilitate installation, configuration, and environment setup for DevOps users.

This image includes binaries for OID Release 12.2.1.4.0 and it has the capability to create a Fusion Middleware (FMW) Infrastructure domain and OID specific servers.

## Building the Oracle Internet Directory image

An Oracle Internet Directory image can be created and/or made available for deployment in the following ways:

1. Oracle's preferred and recommended approach is to use the WebLogic Image Tool to build the Oracle Internet Directory 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an Oracle Internet Directory image with WebLogic Image Tool](imagetool/12.2.1.4.0)
1. Build your own Oracle Internet Directory image using the `Dockerfile`, scripts and base image from Oracle Container Registry (OCR). To customize the image for specific use-cases, Oracle provides Dockerfile and build scripts. For more information, see [Building an Oracle Internet Directory Image with Dockerfile, Scripts and Base Image from OCR](dockerfiles/12.2.1.4.0/README.md).
1. Build your own Oracle Internet Directory image using the Dockerfile and scripts. To customize the image for specific use-cases, Oracle provides Dockerfile and build scripts. For more information, see [Building an Oracle Internet Directory Image with Dockerfiles and Scripts](dockerfiles/12.2.1.4.0/README.md).

## Oracle Internet Directory Container Configuration

To deploy the Oracle Internet Directory container as a standalone container, see the tutorial [Creating Oracle Internet Directory Docker containers](https://docs.oracle.com/en/middleware/idm/internet-directory/12.2.1.4/tutorial-oid-docker/).

## Deploying Oracle Internet Directory on Kubernetes

To deploy the Oracle Internet Directory containers with Kubernetes see the [Oracle Internet Directory on Kubernetes](https://oracle.github.io/fmw-kubernetes/oid/) documentation.

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleInternetDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

