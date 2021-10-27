Building an Oracle Internet Directory Image using Dockerfiles and Scripts
========================================================================

## Contents

1. [Introduction](#1-introduction)
2. [Prerequisites](#2-prerequisites)
3. [How to Build the Oracle Java Image](#3-how-to-build-the-oracle-java-image)
4. [How to Build the Oracle Fusion Middleware Infrastructure Image](#4-how-to-build-the-oracle-fusion-middleware-infrastructure-image)
5. [Building a Container Image for Oracle Internet Directory](#5-building-a-container-image-for-oracle-internet-directory)

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

    $ mkdir <work directory>


  2. Download the OID Docker files from the OID [repository](https://github.com/oracle/docker-images) by running the following command:

    $ cd <work directory>
    $ git clone https://github.com/oracle/docker-images

## Downloading the 12.2.1.4.0 Identity Management shiphome.

  1. Download the [Oracle Internet Directory 12cPS4 software](https://www.oracle.com/in/security/identity-management/technologies/downloads/) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_oid_linux64.bin` to `<work directory>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/`:

    $ unzip fmw_12.2.1.4.0_oid_linux64_Disk1_1of1.zip
    $ cp fmw_12.2.1.4.0_oid_linux64.bin <work directory>/docker-images/OracleInternetDirectory/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_oid_linux64.bin
  

  2. If you are creating the OID image with patches, create the following directories under the `12.2.1.4.0` directory, where patches directory will contain the patches and opatch_patch directory will contain the Opatch patch:

    $ mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/patches
    $ mkdir -p <work directory>/OracleInternetDirectory/dockerfiles/12.2.1.4.0/opatch_patch

  3. If required run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    $ export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    $ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>

  4. Run the following command to build the OID image:

    $ cd <work directory>/docker-images/OracleInternetDirectory/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

    If successful, one can see the following at the end:

    Successfully tagged oracle/oid:12.2.1.4.0
      Oracle Internet Directory Image for version: 12.2.1.4.0 is ready to be extended.
        --> oracle/oid:12.2.1.4.0
      Build completed in 1225 seconds.

   The OID Docker image is now built successfully.


# Licensing & Copyright

## License
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleInternetDirectory](./) repository required to build the images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2021, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
