Oracle Unified Directory Service Manager on Containers
======================================================

## Contents

1. [Introduction](#introduction)
1. [Installing the Oracle Unified Directory Services Manager Image](#installing-the-oracle-unified-directory-services-manager-image)
1. [Oracle Unified Directory Services Manager container configuration](#oracle-unified-directory-services-manager-container-configuration)
1. [Oracle Unified Directory Services Manager Kubernetes Configuration](#oracle-unified-directory-services-manager-kubernetes-configuration)

## Introduction

Oracle Unified Directory Services Manager is an interface for managing instances of Oracle Unified Directory. Oracle Unified Directory Services Manager enables you to configure the structure of the directory, define objects in the directory, add and configure users, groups, and other entries. Oracle Unified Directory Services Manager is also the interface you use to manage entries, schema, security, and other directory features.

This project offers dockerfile and scripts to build and configure an Oracle Unified Directory Services Manager image based on 12cPS4 (12.2.1.4.0) release. Use this Image to facilitate installation, configuration, and environment setup for DevOps users. 

This image refers to binaries for Oracle Unified Directory Services Manager Release 12.2.1.4.0.

***Image***: `oracle/oudsm:12.2.1.4.0`

## Installing the Oracle Unified Directory Services Manager Image

An Oracle Unified Directory Services Manager image can be created and/or made available for deployment in the following ways:

1. Build your own Oracle Unified Directory Services Manager image using the WebLogic Image Tool. Oracle recommends using the Weblogic Image Tool to build your own Oracle Unified Directory Services Manager 12.2.1.4.0 image along with the latest Bundle Patch and any additional patches that you require. For more information, see [Building an Oracle Unified Directory Services Manager Image with Weblogic Image Tool](OracleUnifiedDirectorySM/imagetool/12.2.1.4.0).)
1. Build your own Oracle Unified Directory Services Manager image using the dockerfile and scripts. To customize the image for specific use-cases, Oracle provides dockerfile and build scripts. For more information, see [Building an Oracle Unified Directory Services Manager Image with Dockerfiles and Scripts](OracleUnifiedDirectorySM/dockerfiles/12.2.1.4.0).

## Oracle Unified Directory Services Manager container configuration

To configure the Oracle Unified Directory Services Manager containers on Docker only, see the tutorial [Creating Oracle Unified Directory Services Manager Docker containers](https://docs.oracle.com/en/middleware/idm/unified-directory/12.2.1.4/tutorial-oudsm-docker/).

## Oracle Unified Directory Services Manager Kubernetes Configuration

To configure Oracle Unified Directory Services Manager with Kubernetes see the [Oracle Unified Directory Services Manager on Kubernetes](https://oracle.github.io/fmw-kubernetes/oudsm/) documentation.

# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleUnifiedDirectory](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
