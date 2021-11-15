# Building an Oracle Internet Directory Image

## Contents

1. [Introduction](#1-introduction)
2. [Options](#2-options)
3. [Prerequisites](#3-prerequisites)

   [Oracle Java Image](#oracle-java-image)

   [Oracle Fusion Middleware Infrastructure Image](#oracle-fusion-middleware-infrastructure-image)

4. [Building the Container Image for Oracle Internet Directory](#4-building-the-container-image-for-oracle-internet-directory)

## 1. Introduction

These sample configurations are designed to enable the installation, configuration and environmental setup of a container-based Oracle Internet Directory 12.2.1.4.0 deployment, including the creation of both an Oracle Fusion Middleware (FMW) Infrastructure domain as well as OID specific servers.

## 2. Options

The OID container image extends the Oracle Fusion Middleware Infrastructure container image, which extends the Oracle Java container image.
Before you can build the OID container image, you must either build the prerequisite images using the resources provided in this repository or pull the pre-built version(s) from [Oracle Container Registry](https://container-registry.oracle.com).
If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with [building the Oracle Internet Directory container image](#4-building-the-container-image-for-oracle-internet-directory).

>NOTE: If you pull the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you must retag the image to replace `container-registry.oracle.com/middleware/` with `oracle/` which is image name and tag that would have been created by a manual build.

```bash
$ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4.0
```

## 3. Prerequisites

The following prerequisites are necessary to build OID images:

* A working installation of Docker 18.03 or later
* Oracle Internet Directory installation binaries
* Oracle Java container image
* Oracle FMW Infrastructure container image
* A `git` client is required to clone this directory

### Oracle Java Image

Please review the [Oracle Java container image documentation](../../../OracleJava/README.md) for details on how to build or pull the image.

### Oracle Fusion Middleware Infrastructure Image

Please review the [Oracle FMW Infrastructure container image documentation](../../../OracleFMWInfrastructure/README.md) for details on how to build or pull the image.

> NOTE: Ensure that the FMW Infrastructure image is tagged as `oracle/fmw-infrastructure:12.2.1.4.0` before building the OID image.

## 4. Building the Container Image for Oracle Internet Directory

### Download the OID Docker files

  1. Create a working directory to store the installation binaries, scripts and other files required by the build process:

```bash
$ mkdir ~/workdir
$ export WORK_DIR="~/workdir"
```

  2. Clone the [Oracle Docker Images GitHub repository](https://github.com/oracle/docker-images):

```bash
$ cd "$WORK_DIR" 
$ git clone https://github.com/oracle/docker-images
```

### Download the 12.2.1.4.0 Oracle Internet Directory binaries

  1. From the [Oracle Identity & Access Management Downloads](https://www.oracle.com/in/security/identity-management/technologies/downloads/) page, download the Oracle Internet Directory 12cPS4 installer for Linux x86-64 (`fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip`).

```bash
$ unzip fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip
$ cp fmw_12.2.1.4.0_oid_linux64.bin "$WORK_DIR/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_oid_linux64.bin"
```

  2. The build process will automatically apply any patches placed in the `12.2.1.4.0/patches` directory and any OPatch patches in `12.2.1.4.0/opatch_patch` directory:

```bash
$ mkdir -p "$WORK_DIR/OracleInternetDirectory/dockerfiles/12.2.1.4.0/patches"
$ mkdir -p "$WORK_DIR/OracleInternetDirectory/dockerfiles/12.2.1.4.0/opatch_patch"
```

  3. Configure any proxies that are required to provide internet access::

```bash
$ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>
```

  4. Run the following command to build the OID image:

```bash
$ cd <work directory>/docker-images/OracleInternetDirectory/dockerfiles
$ sh buildDockerImage.sh -v 12.2.1.4.0
```

    If successful, one can see the following at the end:

    Successfully tagged oracle/oid:12.2.1.4.0
      Oracle Internet Directory Image for version: 12.2.1.4.0 is ready to be extended.
        --> oracle/oid:12.2.1.4.0
      Build completed in 1225 seconds.

   The OID Docker image is now built successfully.

  5. One can also use the following `docker build` command to build the OID image:

```bash
$ docker build --pull -t oracle/oid:12.2.1.4.0 .
```

## 4 Validate the Oracle Internet Directory Image

Run the following command to make sure the Oracle Internet Directory image is installed in the docker images repository:

```bash
$ docker images | grep oid
```

The output will look similar to the following:

```bash
$ docker images | grep oid
oracle/oid                                                    12.2.1.4.0          ef7252c9221c        18 hours ago        6.94GB
```

## License

To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleInternetDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright

Copyright (c) 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at <https://oss.oracle.com/licenses/upl>
