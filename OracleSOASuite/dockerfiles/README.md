SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for SOA 12.2.1.x based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle Fusion Middleware Infrastructure 12.2.1.x.

You will be able to build the SOA images based on the version which is required using the build scripts provided. 

## SOA 12.2.1.x Docker image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there. If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building a Docker Image for SOA".

>NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 12.2.1.4 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4` to `oracle/fmw-infrastructure:12.2.1.4.0`.

```
$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4.0
```

## How to build the Oracle Java image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleJava/README.md) under docker/OracleJava for details on how to build Oracle Database image.

## Building Oracle Fusion Middleware Infrastructure Docker Install Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleFMWInfrastructure/README.md) under docker/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.

## Building Docker Image for SOA

>IMPORTANT: To build the Oracle SOA image, you must first download the required version of the Oracle SOA Suite, Oracle Service Bus and Oracle B2B binaries. These binaries must be downloaded and copied into the folder with the same version for e.g. 12.2.1.4.0 binaries need to be dropped into `../OracleSOASuite/dockerfiles/12.2.1.4`. 

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle SOA Suite" and download the version which is required, for e.g. 12.2.1.4.0 is available under `Oracle Fusion Middleware 12c (12.2.1.4.0) SOA Suite and Business Process Management` software. Also search for 'Oracle Service Bus' and 'Oracle B2B'. Download the `Oracle Fusion Middleware 12c (12.2.1.4.0) Service Bus` and `Oracle Fusion Middleware 12c (12.2.1.4.0) B2B and Healthcare` binaries respectively. 

>NOTE: In this release, Oracle B2B is not supported to be configured, but the installer is required for completeness.

Extract the downloaded zip files and copy `fmw_12.2.1.4.0_soa.jar`, `fmw_12.2.1.4.0_osb.jar` and `fmw_12.2.1.4.0_b2bhealthcare.jar` files under `dockerfiles/12.2.1.4` for building Oracle SOA 12.2.1.4 image. 

The Dockerfile `dockerfiles/12.2.1.4/Dockerfile` expects the Oracle SOA Suite installation binaries names as mentioned above. In case if the downloaded jar(s) names does not match with the above, make sure to rename them to match the same. Also, if the checksum of these binaries does not match with the default values mentioned in the `dockerfiles/12.2.1.4/install/soasuite.download` file, then use '-s' option in the image build command, to skip the checksum validation.

To build the SOA image with patches, you need to download and drop the patch zip files (for e.g. `p29928100_122134_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for `12.2.1.4` the folder is `12.2.1.4/patches`. Similarly, to build the image by including the OPatch patch, download and drop the OPatch patch zip file (for e.g. `p28186730_139424_Generic.zip`) into the `opatch_patch/` folder. Then run the `buildDockerImage.sh` script as mentioned below:

Build the Oracle SOA 12.2.1.4 image using:

```
$ sh buildDockerImage.sh -v 12.2.1.4
```

   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle SOA Suite.


Verify you now have the image `oracle/soasuite:12.2.1.4` in place with 

```
$ docker images | grep "soa"
```

If you are building the SOA image with patches, you can verify the patches applied with:

```
$ docker run oracle/soasuite:12.2.1.4 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'
```

>IMPORTANT: The image created in above step will NOT have a domain pre-configured. But it has the scripts to create and configure a SOA domain.

# License

To download and run SOA 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under UPL 1.0 license.

# Copyright

Copyright (c) 2019, 2021, Oracle and/or its affiliates.
