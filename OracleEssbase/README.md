Oracle Essbase Container Images
=============
Sample containers to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for Oracle Essbase 21c based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle FMW Infrastructure 12.2.1.4.0.

For more information about Oracle Essbase please see the [Oracle Essbase 21c Online Documentation](https://docs.oracle.com/en/database/other-databases/essbase/21/index.html).

The certification of Oracle Essbase on containers does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## Oracle Essbase Container Image Creation

To build the Essbase image either you can start from building Oracle JDK and Oracle Fusion Middleware Infrastrucure image or use the already available Oracle Fusion Middleware Infrastructure image. The Fusion Middleware Infrastructure image is available in the [Oracle Container Registry](https://container-registry.oracle.com), and can be pulled from there. If you plan to use the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com), you can skip the next two steps and continue with "Building the Oracle Essbase Image".

NOTE: If you download the Oracle Fusion Middleware Infrastructure image from the [Oracle Container Registry](https://container-registry.oracle.com) then you need to retag the image with appropriate version. e.g. for the 12.2.1.4.0 version, retag from `container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4` to `oracle/fmw-infrastructure:12.2.1.4`.

$ docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4

### Building the Oracle Java (Server JRE) Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) under docker/OracleJava for details on how to build Oracle Database image.

https://github.com/oracle/docker-images/tree/master/OracleJava/README.md

### Building the Oracle FMW Infrastructure Image

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleFMWInfrastructure/README.md) under docker/OracleFMWInfrastructure for details on how to build Oracle Fusion Middleware Infrastructure image.
 
### Building the Oracle Essbase Image

IMPORTANT: To build the Oracle Essbase image, you must first download the required version of the Oracle Essbase installer. This installer must be downloaded and copied into the folder with the same version for e.g. 21.1.0.0.0 binaries need to be dropped into `../OracleEssbase/dockerfiles/21.1.0`. 

The binaries can be downloaded from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com). Search for "Oracle Essbase" and download the version which is required, e.g. 21.1.0.0.0.

Extract the downloaded zip files and copy the `essbase_211_installer/essbase-21.1.0.0.0-171-linux64.jar` file to `dockerfiles/21.1.0` for building Oracle Essbase 21.1.0 image.

>IMPORTANT: To build the Essbase image with patches, you need to download and drop the patch zip files (for e.g. `p29928100_122134_Generic.zip`) into the `patches/` folder under the version which is required, for e.g. for `21.1.0.0.0` the folder is `21.1.0/patches`. Then run the `buildDockerImage.sh` script as mentioned below:

If a proxy is needed for the host to access yum.oracle.com during build, then first set up the appropriate environment, e.g.:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80
        $ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

Build the Oracle Essbase 21.1.0 image using:

$ sh buildDockerImage.sh -v 21.1.0

   Usage: buildDockerImage.sh -v [version]
   Builds a Container Image for Oracle Essbase.

Verify you now have the image `oracle/essbase:21.1.0` in place with 

$ docker images | grep "essbase"

If you are building the Essbase image with patches, you can verify the patches applied with:

$ docker run oracle/essbase:21.1.0 sh -c '$ORACLE_HOME/OPatch/opatch lspatches'

>IMPORTANT: The image created in above step will NOT have a domain pre-configured. But it has the scripts to create and configure a Essbase domain.

## Known Issues

1. If the container is restarted, it requires the same set of environment variables passed in again, even though the domain has already been created.

## License

To download and run Oracle Essbase 21c regardless of inside or outside a container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [docker/OracleEssbase](./) repository required to build the container images are, unless otherwise noted, released under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## Copyright

Copyright (c) 2021, Oracle and/or its affiliates.

