SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for SOA 12.2.1.x based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle Fusion Middleware Infrastructure 12.2.1.x.

You will be able to build the SOA images based on the version which is required using the build scripts provided. 

## SOA 12.2.1.x Docker image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there. If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building a Docker Image for SOA".

NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 12.2.1.3.0 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.3` to `oracle/fmw-infrastructure:12.2.1.3`.

$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.3 oracle/fmw-infrastructure:12.2.1.3

## How to build the Oracle Java image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) under docker/OracleJava for details on how to build Oracle Database image.

https://github.com/oracle/docker-images/tree/master/OracleJava/README.md

## Building Oracle Fusion Middleware Infrastructure Docker Install Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleFMWInfrastructure/README.md) under docker/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.

## Building Docker Image for SOA

IMPORTANT: To build the Oracle SOA image, you must first download the required version of the Oracle SOA Suite and Oracle Service Bus binaries. Both these install binaries are required to create the Oracle SOA image. These binaries must be downloaded and copied into the folder with the same version for e.g. 12.2.1.3.0 binaries need to be dropped into `../OracleSOASuite/dockerfiles/12.2.1.3`.

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle SOA Suite" and download the version which is required, for e.g. 12.2.1.3.0 is available under `Oracle Fusion Middleware 12c (12.2.1.3.0) SOA Suite and Business Process Management` software. Also search for 'Oracle Service Bus' and download the `Oracle Service Bus 12.2.1.3.0` version.

Extract the downloaded zip files and copy `fmw_12.2.1.3.0_soa.jar`, `fmw_12.2.1.3.0_osb.jar` files under `dockerfiles/12.2.1.3` for building Oracle SOA 12.2.1.3 image.

Build the Oracle SOA 12.2.1.3 image using:

$ sh buildDockerImage.sh -v 12.2.1.3

   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle SOA Suite.


Verify you now have the image `oracle/soa:12.2.1.3` in place with 

$ docker images | grep "soa"

# Building Docker Image with bundle patches for SOA
IMPORTANT: To build the SOA image with bundle patches, you must first download the required version of the Oracle SOA Suite binaries as explained in above step.

Download and drop the patch zip files (for e.g. `p29928100_122130_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for `12.2.1.3.0` the folder is `12.2.1.3/patches`

Build the image with the -p option which will copy and install the patches into the image. You can build the Oracle SOA 12.2.1.3 image using:

$ sh buildDockerImage.sh -v 12.2.1.3 -p

Alternatively you can also use `docker build` command with `Dockerfile.patch` file to build the patched image.

$ docker build -t oracle/soa:12.2.1.3 -f Dockerfile.patch . 

# License

To download and run SOA 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under UPL 1.0 license.

# Copyright

Copyright (c) 2019, 2020 Oracle and/or its affiliates.

