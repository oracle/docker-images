# Introduction

This file contains the information on how to create the Oracle Tuxedo container image and two sample applications to use it.

## Prerequisites

The Tuxedo image uses the Oracle JDK 8 (Server JRE) container image oracle/serverjre:8 as its base. Please follow the [Oracle Java image](https://github.com/oracle/docker-images/blob/master/OracleJava) documentation to build that image before continuing.

## To build the Oracle Tuxedo container image

1. Download the latest Tuxedo Linux 64 bit installer (e.g. tuxedo221000_64_Linux_01_x86.zip) as instructed in [the documentation](../README.md).
2. Move the installer that you downloaded in the previous step to the appropriate version directory (e.g. 21.1.0.0.0) in your local copy of the repository.
3. Change to this directory `OracleTuxedo/core/dockerfiles` in your local copy of the repository.
4. Execute ``./buildContainerImage.sh -v 22.1.0.0.0 -i tuxedo221000_64_Linux_01_x86.zip -s`` to create a container image for Tuxedo 22.1.0.

You should now have a container image tagged oracle/tuxedo:`<version>` where version is the Tuxedo version number provided to buildContainerImage.sh above.

## Notes

1. Before you run buildContainerImage.sh, depending on your Tuxedo version, you may need to change the above command and installer name. For instance, `tuxedo122200_64_Linux_01_x86.zip` as the installer name for version 12.2.2 or `tuxedo221000_64_Linux_01_x86.zip` as the installer name for version 22.1.0.0.0.
2. Before you run buildContainerImage.sh, if a proxy is needed to access network, you need to set the following environment variables: http_proxy, https_proxy, ftp_proxy, no_proxy.


## To run the two sample applications

1. shm sample - Follow the instructions in [shm sample README](../samples/shm/README.md)
2. ws sample - Follow the instructions in [ws sample README](../samples/ws/README.md)

