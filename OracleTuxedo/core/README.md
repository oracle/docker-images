# Oracle Tuxedo Core Container Image

This sample container image is provided to facilitate installation, configuration and environment setup of Tuxedo 22.1.0.0.0. The image is based on Oracle Linux 7 and Oracle JDK 8 (ServerJRE).

The certification of Tuxedo when run within a container does not require the use of any file presented in this repository. Customers and users are welcome to use them as references that can be customized, or choose to create new container images from scratch.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com/).

## Contents

This folder contains the information and examples of how to deploy [Tuxedo](http://oracle.com/tuxedo) in a container.

## How to build and run

This project offers Dockerfiles for Tuxedo 22.1.0.0.0. To assist in building the images, you can use the buildContainerImage.sh script. See below for instructions and usage.

To assist in building the images, the `buildContainerImage.sh` simplifies the process of ensuring the correct binary archive is available before starting the build process. More experienced users are welcome to build the image using their preferred container engine or CI/CD tool.

## Building Oracle JDK (Server JRE) base image

The Tuxedo image uses the Oracle JDK 8 (Server JRE) container image as its base. Please follow the [Oracle Java image](https://github.com/oracle/docker-images/blob/master/OracleJava) documentation to build that image before continuing.

## Building Tuxedo Container Image

1. Into an empty directory:
   * Download the [Tuxedo 22.1.0.0.0 Linux 64-bit installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html) from the Oracle Technology Network.
   * Clone or download this repository
   * Move the downloaded Tuxedo installer to the corresponding version directory
   * Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. Change to the `OracleTuxedo/core/dockerfiles` directory in your local copy of the repository
3. Run './buildContainerImage.sh' to see the available parameters for this script then follow [the documentation](./dockerfiles/README.md) to build the image.

This process builds a container image image named `oracle/tuxedo` tagged by version. For example, `oracle/tuxedo:22.1.0.0.0` and `oracle/tuxedo:latest`.

You can then start a container based on this image using the following command:
```shell
docker run -d -v "${LOCAL_DIR}:/u01/oracle/user_projects" oracle/tuxedo:22.1.0.0.0
```
Note: `${LOCAL_DIR}` must resolve to a local directory in which the container can store data.

## Tuxedo Distribution and Documentation

* For more information on Tuxedo 22.1.0.0.0, visit [Tuxedo Installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html).

## License

To download and run Tuxedo 22.1.0.0.0 regardless of inside or outside a Container container, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this repository required to build the container images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright

Copyright (c) 2022 Oracle and/or its affiliates.
