# SOA on Containers

Sample Containerfile configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for SOA 12.2.1.x based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle Fusion Middleware Infrastructure 12.2.1.x.
This project also includes a setup for SOA 14.1.2.0 image build based on Oracle Linux 8, Oracle JDK 17, and Oracle Fusion Middleware Infrastructure 14.1.2.0 with an option to use Podman CLI as an alternative to docker.

You will be able to build the SOA images based on the version which is required using the build scripts provided.

**IMPORTANT**: We provide Containerfiles as samples to build SOA images but this is NOT a recommended practice for production environments. We recommend obtaining patched SOA Suite images with the latest security patches for production deployments. For more information, [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches](<https://docs.oracle.com/en/middleware/fusion-middleware/14.1.2/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html>).

The samples in this repository are for development purposes only. For production, we suggest obtaining base SOA Suite images from the [Oracle Container Registry](<https://container-registry.oracle.com/ords/ocr/ba/middleware/soasuite>).

Consider using the open source [WebLogic Kubernetes Operator](<https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/oracle-soa-suite.html>) to deploy and manage SOA Suite domains.

## SOA 12.2.1.x Containerfile image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there.
If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building a Container image for SOA".

>NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 12.2.1.4 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4` to `oracle/fmw-infrastructure:12.2.1.4.0`.

``` bash
`$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4.0`
```

### How to build the Oracle Java image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleJava/README.md) under docker-images/OracleJava for details on how to build the Oracle Database image.

### Building Oracle Fusion Middleware Infrastructure Docker Install image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleFMWInfrastructure/README.md) under docker-images/OracleFMWInfrastructure for details on how to build the Oracle Fusion Middleware Infrastructure image.

### Building a Container image for SOA

>IMPORTANT: To build the Oracle SOA image, you must first download the required version of the Oracle SOA Suite, Oracle Service Bus and Oracle B2B binaries. These binaries must be downloaded and copied into the folder with the same version for e.g. 12.2.1.4.0 binaries need to be dropped into `../OracleSOASuite/dockerfiles/12.2.1.4`.

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle SOA Suite" and download the version which is required, for e.g. 12.2.1.4.0 is available under `Oracle Fusion Middleware 12c (12.2.1.4.0) SOA Suite and Business Process Management` software.
Also search for 'Oracle Service Bus' and 'Oracle B2B'. Download the `Oracle Fusion Middleware 12c (12.2.1.4.0) Service Bus` and `Oracle Fusion Middleware 12c (12.2.1.4.0) B2B and Healthcare` binaries respectively.

>NOTE: In this release, Oracle B2B is not supported to be configured, but the installer is required for completeness.

Extract the downloaded zip files and copy `fmw_12.2.1.4.0_soa.jar`, `fmw_12.2.1.4.0_osb.jar` and `fmw_12.2.1.4.0_b2bhealthcare.jar` files under `dockerfiles/12.2.1.4` for building Oracle SOA 12.2.1.4 image.

The Containerfile `dockerfiles/12.2.1.4/Dockerfile` expects the Oracle SOA Suite installation binaries names as mentioned above. In case if the downloaded jar(s) names does not match with the above, make sure to rename them to match the same.
Also, if the checksum of these binaries does not match with the default values mentioned in the `dockerfiles/12.2.1.4/install/soasuite.download` file, then use '-s' option in the image build command, to skip the checksum validation.

To build the SOA image with patches, you need to download and drop the patch zip files (for e.g. `p29928100_122134_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for `12.2.1.4` the folder is `12.2.1.4/patches`.
Similarly, to build the image by including the OPatch patch, download and drop the OPatch patch zip file (for e.g. `p28186730_139424_Generic.zip`) into the `opatch_patch/` folder. Then run the `buildDockerImage.sh` script as mentioned below:

Build the Oracle SOA 12.2.1.4 image using:

``` bash
`$ sh buildDockerImage.sh -v 12.2.1.4`

   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle SOA Suite.

```

Verify you now have the image `oracle/soasuite:12.2.1.4` in place with

`$ docker images | grep "soa"`

If you are building the SOA image with patches, you can verify the patches applied with:

`$ docker run oracle/soasuite:12.2.1.4 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'`


>IMPORTANT: The image created in above step will NOT have a domain pre-configured. But it has the scripts to create and configure a SOA domain.

## SOA 14.1.2.0 Container image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there.
If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building a Container Image for SOA".

>NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 14.1.2.0 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:14.1.2.0` to `oracle/fmw-infrastructure:14.1.2.0.0`. <br>
Users can use Podman or Docker CLI to perform the build related Commands. The steps are provided using docker as well as podman for user reference.

``` bash
`$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:14.1.2.0 oracle/fmw-infrastructure:14.1.2.0.0`
```

``` bash
`$ podman tag container-registry.oracle.com/middleware/fmw-infrastructure:14.1.2.0 oracle/fmw-infrastructure:14.1.2.0.0`
```

### How to build the Oracle Java Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleJava/README.md) under docker-images/OracleJava for details on how to build Oracle Database image.

### Building Oracle Fusion Middleware Infrastructure Docker Install Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/main/OracleFMWInfrastructure/README.md) under docker-images/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.

### Building a Container Image for SOA

>IMPORTANT: To build the Oracle SOA image, you must first download the required version of the Oracle SOA Suite, Oracle Service Bus and Oracle B2B binaries. These binaries must be downloaded and copied into the folder with the same version for e.g. 14.1.2.0.0 binaries need to be dropped into `../OracleSOASuite/dockerfiles/14.1.2.0`.

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle SOA Suite" and download the version which is required, for e.g. 14.1.2.0.0 is available under `Oracle Fusion Middleware 14c (14.1.2.0.0) SOA Suite and Business Process Management` software.
Also search for 'Oracle Service Bus' and 'Oracle B2B'. Download the `Oracle Fusion Middleware 14c (14.1.2.0.0) Service Bus` and `Oracle Fusion Middleware 14c (14.1.2.0.0) B2B and Healthcare` binaries respectively.

>NOTE: In this release, Oracle B2B is not supported to be configured, but the installer is required for completeness.

Extract the downloaded zip files and copy `fmw_14.1.2.0.0_soa.jar`, `fmw_14.1.2.0.0_osb.jar` and `fmw_14.1.2.0.0_b2bhealthcare.jar` files under `dockerfiles/14.1.2.0` for building Oracle SOA 14.1.2.0 image.

The Containerfile `dockerfiles/14.1.2.0/Containerfile` expects the Oracle SOA Suite installation binaries names as mentioned above. In case if the downloaded jar(s) names does not match with the above, make sure to rename them to match the same.
Also, if the checksum of these binaries does not match with the default values mentioned in the `dockerfiles/14.1.2.0/install/soasuite.download` file, then use '-s' option in the image build command, to skip the checksum validation.

To build the SOA image with patches, you need to download and drop the patch zip files into the `patches/` folder under the version which is required, for e.g. for `14.1.2.0` the folder is `14.1.2.0/patches`.
Similarly, to build the image by including the OPatch patch, download and drop the OPatch patch zip file into the `opatch_patch/` folder. Then run the `buildDockerImage.sh` script as mentioned below:

Build the Oracle SOA 14.1.2.0 image using:

``` bash
$ sh buildDockerImage.sh -v 14.1.2.0

   Usage: buildDockerImage.sh -v [version]
   Parameters:
      -h: view usage
      -v: Release version to build. Required.
      -s: Skip checksum verification
      -p: Uses podman CLI to build the image. Option enabled only for 14.1.2.0
```

For the podman users:

`$ sh buildDockerImage.sh -v 14.1.2.0 -p`

>Note: -p ensures podman CLI is used for the image build.

Verify you now have the image `oracle/soasuite:14.1.2.0` in place with

`$ docker images | grep "soa"`

`$ podman images | grep "soa"`

If you are building the SOA image with patches, you can verify the patches applied with:

``` bash
`$ docker run oracle/soasuite:14.1.2.0 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'`
```

``` bash
`$ podman run oracle/soasuite:14.1.2.0 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'`
```

>IMPORTANT: The image created in above step will NOT have a domain pre-configured. But it has the scripts to create and configure a SOA domain.

## License

To download and run SOA 12c and 14c Distributions regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2019, 2025, Oracle and/or its affiliates.
