Tuxedo using Container Image
===============================
Sample Container Image configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes Dockerfiles for Tuxedo 22.1.0.0.0 based on Oracle Linux and Oracle JDK 8 (Server).

The certification of Tuxedo on Container Image does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com/).

## Contents
This folder contains the information and examples of how to use [Tuxedo](http://oracle.com/tuxedo) with Container Image

How to build and run

This project offers Dockerfiles for Tuxedo 22.1.0.0.0. To assist in building the images, you can use the buildContainerImage.sh script. See below for instructions and usage.

The buildContainerImage.sh script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call container image build with their prefered set of parameters.

Building Oracle JDK (Server JRE) base image

You must first download the Oracle Server JRE binary and drop in folder ../../OracleJava/java-8 and build that image. For more information, visit the [OracleJava](https://github.com/oracle/docker-images/blob/master/OracleJava) folder's [README](https://github.com/oracle/docker-images/blob/master/OracleJava/README.md) file.

    $ cd ../../OracleJava/java-8
    $ sh build.sh

Building Tuxedo Container Image Install Images
## To use
1. Into an empty directory:
  1. Download the Tuxedo 22.1.0.0.0 Linux 64bit installer from [OTN](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html)
  2. Download all the files from this GitHub repository
  3. Drop the downloaded Tuxedo installer to the corresponding version directory
  4. Optionally download the latest Tuxedo rolling patch from My Oracle Support
2. cd dockerfiles
3. Execute './buildContainerImage.sh' to show the usage of the command. Follow [the guide](./dockerfiles/README.md) to create a Container image.

You should end up with a Container image tagged oracle/tuxedo:version, for instance, oracle/tuxedo:22.1.0.0.0 and oracle/tuxedo:latest

You can then start the image in a new container with: ``docker run -d -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedo:<VERSION>``.
Note: \${LOCAL_DIR} is a local dir which used in Container image as external storage, it can be any dir.


 * Tuxedo Distribution and Documentation
   - For more information on the Tuxedo 22.1.0.0.0 Distribution, visit [Tuxedo Installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html).



## License
To download and run Tuxedo 22.1.0.0.0 regardless of inside or outside a Container container, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleTuxedo](./) repository required to build the Container images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2022 Oracle and/or its affiliates.

