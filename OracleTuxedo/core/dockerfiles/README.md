# Introduction

This file contains information on how to create the Oracle Tuxedo container image and provides details for some sample applications that demonstrate how to use it.

## Prerequisites

The Tuxedo image uses the Oracle JDK 8 (Server JRE) container image `oracle/serverjre:8` as its base. Please follow the [Oracle Java image](https://github.com/oracle/docker-images/blob/master/OracleJava) documentation to build that image before continuing.

## To build the Oracle Tuxedo container image

1. Download the latest Tuxedo Linux 64 bit installer (e.g. `tuxedo221000_64_Linux_01_x86.zip`) as instructed in [the documentation](../README.md).
2. Move the installer that you downloaded in the previous step to the appropriate version directory (e.g. 21.1.0.0.0) in your local copy of the repository.
3. Change to this directory `OracleTuxedo/core/dockerfiles` in your local copy of the repository.
4. Execute ``./buildContainerImage.sh -v 22.1.0.0.0 -i tuxedo221000_64_Linux_01_x86.zip -s`` to create a container image for Tuxedo 22.1.0.

You should now have a container image tagged `oracle/tuxedo:<version>` where version is the Tuxedo version number provided to `buildContainerImage.sh` above.

## Notes

1. Before you run `buildContainerImage.sh`, depending on your Tuxedo version, you may need to change the above command and installer name. For instance, `tuxedo122200_64_Linux_01_x86.zip` as the installer name for version 12.2.2 or `tuxedo221000_64_Linux_01_x86.zip` as the installer name for version 22.1.0.0.0.
2. If your container host requires a proxy to access internet locations, ensure the `https_proxy` environment variable is set before running `buildContainerImage.sh`.

## Sample applications

To run the following same applications, follow the instructions in the linked documentation for each:
* [Simpapp sample application](../samples/shm/README.md)
* [Workstation (WS) sample application](../samples/ws/README.md)
* [Workstation (WS) SSL server application](../samples/ws_ssl_svr/README.md)
