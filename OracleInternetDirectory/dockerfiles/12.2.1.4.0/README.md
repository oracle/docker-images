Building an Oracle Internet Directory Image using Dockerfiles and Scripts
========================================================================

## Contents

1. [Introduction](#1-introduction)
2. [Prerequisites](#2-prerequisites)
3. [How to Build the Oracle Java Image](#3-how-to-build-the-oracle-java-image)
4. [How to Build the Oracle Fusion Middleware Infrastructure Image](#4-how-to-build-the-oracle-fusion-middleware-infrastructure-image)
5. [Building a Container Image for Oracle Internet Directory](#5-building-a-container-image-for-oracle-internet-directory)
6. [Building an Oracle Internet Directory Image with Dockerfiles, Scripts and Base Image from Oracle Container Registry (OCR)](#6-building-an-oracle-internet-directory-image-with-dockerfiles-scripts-base-image-from-oracle-container-registry-(ocr))

# 1. Introduction

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This Image includes binaries for Oracle Internet Directory (OID) Release 12.2.1.4.0 and has the capability to create the FMW Infrastructure domain and OID specific servers.

***Image***: oracle/oid:<version; example:12.2.1.4.0>

# 2. Prerequisites

The following prerequisites are necessary before building OID images:

* A working installation of Docker 18.03 or later

# 3. How to Build the Oracle Java Image

Please refer to [README.md](../../../OracleJava/README.md) under `docker-images/OracleJava` for details on how to build Oracle Java image.

# 4. How to Build the Oracle Fusion Middleware Infrastructure Image

Please refer to [README.md](../../../OracleFMWInfrastructure/README.md) under `docker-images/OracleFMWInfrastructure` for details on how to build Oracle Fusion Middleware Infrastructure image.

OID Dockerfile uses the 'oracle/fmw-infrastructure:12.2.1.4.0' tag to refer to the Oracle Fusion Middleware (FMW) Infrastructure image, hence you should use this tag for the same.

# 5. Building a Container Image for Oracle Internet Directory

## Downloading the OID Docker files

  1. Make a work directory to place the OID Docker files:

    mkdir <work directory>

  2. Download the OID Docker files from the OID [repository](https://github.com/oracle/docker-images) by running the following command:

    cd <work directory>
    git clone https://github.com/oracle/docker-images

## Downloading the 12.2.1.4.0 Identity Management shiphome

  1. Download the [Oracle Internet Directory 12cPS4 software](https://www.oracle.com/in/security/identity-management/technologies/downloads/) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_oid_linux64.bin` to `<work directory>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/`:

    unzip fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip
    cp fmw_12.2.1.4.0_oid_linux64.bin <work directory>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_oid_linux64.bin
  
  2. If you are creating the OID image with patches, create the following directories under the `12.2.1.4.0` directory, where patches directory will contain the patches and opatch_patch directory will contain the Opatch patch:

    mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/patches
    mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/opatch_patch

  3. If required run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>

  4. Run the following command to build the OID image:

    $ cd <work directory>/docker-images/OracleInternetDirectory/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

    If successful, one can see the following at the end:

    Successfully tagged oracle/oid:12.2.1.4.0
      Oracle Internet Directory Image for version: 12.2.1.4.0 is ready to be extended.
        --> oracle/oid:12.2.1.4.0
      Build completed in 1225 seconds.

   The OID Docker image is now built successfully.

# 6. Building an Oracle Internet Directory Image with Dockerfiles Scripts and Base Image from Oracle Container Registry (OCR)

## Contents

1. [Pulling Oracle FMW Infrastructure 12.2.1.4.x image](#1-pull-oracle-fmw-infrastructure-12214x-image)
2. [Downloading the 12.2.1.4.0 Identity Management Shiphome](#2-downloading-the-122140-identity-management-shiphome)
3. [Building Oracle Internet Directory Image](#3-building-oracle-internet-directory-image)
4. [Validate the Oracle Internet Directory Image](#4-validate-the-oracle-internet-directory-image)

## 1. Pull Oracle FMW Infrastructure 12.2.1.4.x image

You can pull the Oracle FMW Infrastructure 12.2.1.4.x image from the [Oracle Container Registry](https://container-registry.oracle.com). When pulling the FMW Infrastructure 12.2.1.4.x image, re-tag the image so that it works with the dependent dockerfile which refers to the FMW Infrastructure 12.2.1.4.x image through 'oracle/fmw-infrastructure:12.2.1.4.0'.

**IMPORTANT**: Before you pull the image from the registry, please make sure to log-in through your browser with your SSO credentials and ACCEPT "Terms and Restrictions". 'fmw-infrastructure' images can be found under Middleware section.

1. Sign in to [Oracle Container Registry](https://container-registry.oracle.com). Click the **Sign in** link which is on the top-right of the Web page.
2. Click **Middleware** and then click on **fmw-infrastructure**.
3. Click **Accept** to accept the license agreement.
4. Use following commands to pull Oracle Fusion Middleware infrastructure base image from repository :

```
docker login container-registry.oracle.com
docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407
docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210407 oracle/fmw-infrastructure:12.2.1.4.0
```

## 2. Downloading the 12.2.1.4.0 Identity Management Shiphome

You must download and save the Oracle Internet Directory 12.2.1.4.0 binary into the cloned/downloaded repository folder at location : `OracleInternetDirectory/dockerfiles/12.2.1.4.0/` (see **Checksum** for file name which is inside oid.download).

```
cp fmw_12.2.1.4.0_oid_linux64.bin <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/
```

If you are creating the OID image with patches create the following directories under the 12.2.1.4.0 directory, where the `patches` directory will contain the patches and the `opatch_patch` directory will contain the Opatch patch:

```
mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/patches
```

```
mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/opatch_patch
```

## 3. Building Oracle Internet Directory image

## Clone and download Oracle Internet Directory scripts and binary file

1. Clone the [GitHub repository](https://github.com/oracle/docker-images)
The repository contains dockerfiles and scripts to build images for Oracle products.

## Build Oracle Internet Directory image using cloned/downloaded docker-images repository

To assist in building the image, you can use the [`buildDockerImage.sh`](../buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their preferred set of parameters.

**IMPORTANT**: If you are building the Oracle Internet Directory image, you must first download the Oracle Internet Directory 12.2.1.x binary (`fmw_12.2.1.4.0_oid_linux64.bin`) and locate it in the folder, `OracleInternetDirectory/dockerfiles/12.2.1.4.0`.

**IMPORTANT**: To build the Oracle Internet Directory image with patches, you need to download and drop the patch zip files (for e.g. `p31400392_122140_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for 12.2.1.4.0 the folder is `12.2.1.4/patches/`.  Similarly, `OPatch` patches can be kept in the `opatch_patch/` folder (for 12.2.1.4.0 the folder is `12.2.1.4/opatch_patch`). Then run the `buildDockerImage.sh` script:

The build script `buildDockerImage.sh` is located at `OracleInternetDirectory/dockerfiles`

```
$ sh buildDockerImage.sh
Usage: buildDockerImage.sh -v [version]
Builds a Docker Image for Oracle Internet Directory

Parameters:
   -v: version to build. Required.
   Choose : 12.2.1.4.0
   -c: enables Docker image layer cache during build
   -s: skips the MD5 check of packages
```

Run the following command to build the Oracle Internet Directory image:

```
cd <work directory>/OracleInternetDirectory/dockerfiles/
sh buildDockerImage.sh -v 12.2.1.4.0
```

If the build is successful you will see a message similar to the following:

```
...
Successfully tagged oracle/oid:12.2.1.4.0

  Oracle Internet Directory Image for version: 12.2.1.4.0 is ready to be extended.

    --> oracle/oid:12.2.1.4.0

  Build completed in 1476 seconds.

$
```

## 4 Validate the Oracle Internet Directory Image

Run the following command to make sure the Oracle Internet Directory image is installed in the docker images repository:

```
docker images | grep oid
```

The output will look similar to the following:

```
$ docker images | grep oid
oracle/oid                                                    12.2.1.4.0          ef7252c9221c        18 hours ago        6.94GB
$
```

# Licensing & Copyright

## License

To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleInternetDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright

Copyright (c) 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at <https://oss.oracle.com/licenses/upl>
