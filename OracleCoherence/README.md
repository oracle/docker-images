<!--
    Copyright (c) 2015, 2020, Oracle and/or its affiliates.
    Licensed under the Universal Permissive License v 1.0 as shown at
    https://oss.oracle.com/licenses/upl.
-->
Oracle Coherence Docker Image
===============
This section is about using [Oracle Coherence](https://www.oracle.com/technetwork/middleware/coherence/overview/index.html)
in Docker. The purpose of the Docker images described here is to facilitate the setup of development
and integration testing environments for developers. This project includes example Dockerfiles and
documentation for Coherence based on Oracle Linux and Oracle Java 8, 11 or Graal base images.

The certification of Coherence on Docker does not require the use of any file presented in this
repository. Customers and users are welcome to use them as starters, and customize/tweak, or create
from scratch new scripts and Dockerfiles.

## Oracle Linux Base Image
For more information and documentation, read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

## Oracle Coherence Standalone Distribution
For more information on the Coherence Standalone Distribution, visit the
[Coherence Documentation](https://docs.oracle.com/en/middleware/standalone/coherence/index.html).

## Building the Java Base Image(s)

Coherence Docker images use a Java base image. Before you can build a Coherence image
you must have built the required Java image or images.

### Coherence 14.1.1.0.0

Coherence 14.1.1.0.0 Docker images can use the following as base images:

1. Oracle Java 8 - see [Oracle Java images](../OracleJava/)
1. Oracle Java 11 - see [Oracle Java images](../OracleJava/)
3. GraalVM CE Java 8 or Java 11 images - see [GraalVM images](../GraalVM/CE/)

> Note: For building a Graal based Coherence image, the Oracle Java 8 image is also required for
>       the image build process.

### Coherence versions prior to 14.1.1.0.0

Before you can build these Oracle Coherence images you must have built the required Oracle
Java 8 (see [Oracle Java images](../OracleJava/)) image.

## How to Build

For Coherence 14.1.1.0.0 and 12.2.1.4.0, Maven is required to build the Docker image.
Maven is used to pull dependent libraries which are then bundled into the Docker image
to enable running the Coherence Management over REST and Coherence Metrics endpoints 
within the container.

### To build a Coherence 14.1.1.0.0 or 12.2.1.4.0 Docker image

#### Prerequisites for building with Maven

* Java 8 JDK
* Maven 3.6.1

#### Build steps

The following steps build a Coherence 14.1.1.0.0 Docker container as an example

1. Checkout the GitHub Oracle Docker Images repository

    ```shell
    git clone git@github.com:oracle/docker-images.git
    ````
   	
1. Go to the directory containing the Dockerfile

    ```shell
    cd OracleCoherence/dockerfiles/14.1.1.0.0/src/main/docker
    ```

1. [Download the Coherence distribution file](https://www.oracle.com/middleware/technologies/coherence-downloads.html)
   of your choice and save it to the current directory. The build script supports
   building an image from either the Quick Installer, `fmw_14.1.1.0.0_coherence_quick_Disk1_1of1.zip`,
   or the Standalone Installer, `fmw_14.1.1.0.0_coherence_Disk1_1of1.zip`.

    > **_NOTE:_** The `Dockerfile` is currently configured to use the Quick Installer.

1. Go to the maven project directory

    ```shell
    cd OracleCoherence/dockerfiles/14.1.1.0.0
    ```

1. Ensure that image `oracle/serverjre:8` or `oracle/jdk:11` is available

   Image `oracle/serverjre:8` is required for both the Coherence Java 8 based Docker image and the
   Graal based Docker image. For the Graal based Docker image `oracle/serverjre:8` is used in the
   first stage of the multipart Docker image build process.
   
   If building a Coherence Java 11 based Docker image (*Coherence 14.1.1.0.0 only), then only
   `oracle/jdk:11` is required.

1. Ensure that image `oracle/graalvm-ce` is available if building a Graal based Coherence
   image (*Coherence 14.1.1.0.0 only*)

1. Build the Docker image with Maven

    To build a Docker image which uses Oracle Java 8 as the base image:

    ```shell
    mvn install
    ```

    The resulting image file will be called `oracle/coherence:14.1.1.0.0`.

    To build a Docker image using Oracle Java 11 as the base image (*Coherence 14.1.1.0.0 only*):

    ```shell
    mvn install -Pjdk11
    ```

    The resulting image file will be called `oracle/coherence:14.1.1.0.0-jdk11`.

    To build a Docker image using GraalVM (CE) as the base image (*Coherence 14.1.1.0.0 only*):

    ```shell
    mvn install -Pgraal
    ```
   
   The resulting image file will be called `oracle/coherence:14.1.1.0.0-graal`.

### To build a Docker image for for Coherence 12.2.1.3.0 and earlier Coherence versions

1. Checkout the GitHub Oracle Docker Images repository

    ```shell
    git clone git@github.com:oracle/docker-images.git
    ````

1. Go to the `OracleCoherence/dockerfiles/12.2.1.3` folder

    ```shell
    cd OracleCoherence/dockerfiles/12.2.1.3.0
    ```

1. [Download the Coherence distribution file](https://www.oracle.com/middleware/technologies/coherence-downloads.html)
   of your choice and save it to the current directory. The build script supports
   either building an image from either the Standalone Installer,
   `fmw_12.2.1.3.0_coherence_Disk1_1of1.zip` or the Quick Installer
   `fmw_12.2.1.3.0_coherence_quick_Disk1_1of1.zip`

1. Ensure that image `oracle/serverjre:8` is available

1. Execute the build script `buildDockerImage.sh`.

    ```shell
    cd ..
    sh buildDockerImage.sh
    ```

    or if your Docker client requires commands to be run as root you can run

    ```shell
    sudo sh buildDockerImage.sh
    ```

    The script will determine which installer and image it is building from the installer
    file that is in the working directory. If both the Standalone and Quick installers are
    present then the default will be to use the Standalone installer. You can specify which
    installer to use with a script argument. To run the Standalone installer use:

    ```shell
    sh buildDockerImage.sh -s
    ```

    Or to run the Quick installer use:

    ```shell
    sh buildDockerImage.sh -q
    ```

    If you are using a different version of Coherence than 12.2.1.3.0 then you can use the `-v`
    parameter to specify a version. For example if you are using 12.2.1.2.0 you would run:

    ```shell
    sh buildDockerImage.sh -v 12.2.1.2.0
    ```

1. The resulting image file will be called `oracle/coherence:${version}-${distribution}`, for example
   if the Standalone installer is used the image will be `oracle/coherence:12.2.1.3.0-standalone`

1. The image is built with a shell as its ENTRYPOINT that allows the image to be run using
   the normal Docker run command. See the [Image Usage](00.imageusage) documentation.

### For Coherence 12.2.1.3.2 follow this process

> Note: This image can only be build by Oracle customers with an active support subscription.

1. Checkout the GitHub Oracle Docker Images repository

    ```shell
    git clone git@github.com:oracle/docker-images.git
    ```

1. Go to the `OracleCoherence/dockerfiles/12.2.1.3.2` folder

    ```shell
    cd OracleCoherence/dockerfiles/12.2.1.3.2
    ```

1. [Download the Coherence distribution file](https://www.oracle.com/middleware/technologies/coherence-downloads.html)
   of your choice and save it to the current directory. The build script supports either
   building an image from either the Standalone Installer, `fmw_12.2.1.3.0_coherence_Disk1_1of1.zip`
   or the Quick Installer `fmw_12.2.1.3.0_coherence_quick_Disk1_1of1.zip`

1. [Download the Coherence 12.2.1.3.2 cumulative patch file](https://updates.oracle.com/Orion/PatchDetails/process_form?patch_num=29204496)
   and save it to the current directory.

1. Ensure that image `oracle/serverjre:8` is available

1. Execute the build script `buildDockerImage.sh`.

    ```shell
    cd ..
    sh buildDockerImage.sh -v 12.2.1.3.2
    ```

    or if your Docker client requires commands to be run as root you can run

    ```shell
    sudo sh buildDockerImage.sh -v 12.2.1.3.2
    ```

1. The resulting image file will be called `oracle/coherence:${version}-${distribution}`, for example
   if the Standalone installer is used the image will be `oracle/coherence:12.2.1.3.2-standalone`

## Documentation
Documentation covering the different aspects of running Oracle Coherence in Docker containers is covered
in the [docs](docs) section.

1. [Image Usage](docs/00.imageusage) - Usage instructions for running the Coherence image
2. [Setup](docs/0.setup) - Setting Up a Demo Docker Machine Environment
3. [Clustering](docs/1.clustering) - Running Coherence Clusters in Docker
4. [Coherence Extend](docs/2.extend) - Running Coherence Extend in Docker
5. [Federated Caching](docs/3.federation) - Federated Caching in Docker
6. [Disc Based Functionality](docs/4.disc_based) - Elastic Data and Persistence in Docker
7. [JMX Monitoring](docs/5.monitoring) - Using JMX in Docker

## Issues
If you find any issues with this Docker project, please report through the
[GitHub Issues page](https://github.com/oracle/docker-images/issues).

## Licenses
To download and run Coherence Distribution regardless of inside or outside a Docker container,
and regardless of which distribution, you must agree and accept the
[OTN Standard License Terms](https://www.oracle.com/technetwork/licenses/standard-license-152015.html).

To download and run Oracle JDK regardless of inside or outside a Docker container, you must agree
and accept the [Oracle Binary Code License Agreement for Java SE](https://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project on GitHub
[docker-images/OracleCoherence](https://github.com/oracle/docker-images/OracleCoherence)
repository required to build the Docker images are, unless otherwise noted, released under
[UPL 1.0](https://oss.oracle.com/licenses/upl/), except for the files listed above with their
specific licenses.

Copyright (c) 2015, 2020, Oracle and/or its affiliates.
