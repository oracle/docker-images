Oracle Coherence Docker Image
===============
This section is about using [Oracle Coherence](http://www.oracle.com/technetwork/middleware/coherence/overview/index.html) in Docker. The purpose of the Docker images described here is to facilitate the setup of development and integration testing environments for developers. This project includes example [dockerfiles](dockerfiles/12.2.1) and documentation for Coherence 12.2.1 based on Oracle Linux and Oracle JDK 8.

The certification of Coherence on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## Oracle Linux Base Image
For more information and documentation, read the [Docker Images from Oracle Linux](https://registry.hub.docker.com/_/oraclelinux/) page.

### Standalone Distribution
For more information on the Coherence Standalone Distribution, visit [Coherence 12.2.1 Documentation](http://docs.oracle.com/middleware/1221/coherence/index.html).

## Building Oracle JDK (Server JRE) base image
Before you can build these Oracle Coherence images you must have built the required Oracle Java 8 base image (see [Oracle Java images](../OracleJava/))

## How to Build

Follow this procedure:

1. Checkout the GitHub Oracle Docker Images repository

	`$ git clone git@github.com:oracle/docker-images.git`

2. Go to the **OracleCoherence/dockerfiles/12.2.1** folder

        $ cd OracleCoherence/dockerfiles/12.2.1

3. [Download](http://www.oracle.com/technetwork/middleware/coherence/downloads/index.html) and drop the Coherence distribution file of your choice into this folder. The build script supports either building an image from either the Standalone Installer, **fmw_12.2.1.0.0_coherence_Disk1_1of1.zip** or the Quick Installer **fmw_12.2.1.0.0_coherence_quick_Disk1_1of1.zip**

4. Execute the build script `buildDockerImage.sh`.

        $ sh buildDockerImage.sh

    or if your Docker client requires commands to be run as root you can run

        $ sudo sh buildDockerImage.sh

    The script will determine which installer and image it is building from the installer file that is in the working directory. If both the Standalone and Quick installers are present then the default will be to use the Standalone installer. You can specify which installer to use with a script argument. To run the Standalone installer use:

        $ sh buildDockerImage.sh -s

    Or to run the Quick installer use:

        $ sh buildDockerImage.sh -q

    If you are using a later version of Coherence than 12.2.1.0.0 then you can use the `-v` parameter to specify a version. For example if you are using `12.2.1.1.0` you would run:

        $ sh buildDockerImage.sh -v 12.2.1.1.0

5. The resulting image file will be called oracle/coherence:${version}-${distribution}, for example if the Standalone installer is used the image will be `oracle/coherence:12.2.1.0.0-standalone`

6. The image is built with a shell script as its ENTRYPOINT that allows the image to be run using the normal Docker run command. See the [Image Usage](00.imageusage) documentation.

## Documentation
Documentation covering the different aspects of running Oracle Coherence in Docker containers is covered in the [docs](docs) section.

1. [Image Usage](docs/00.imageusage) - Usage instructions for running the Coherence image
2. [Setup](docs/0.setup) - Setting Up a Demo Docker Machine Environment
3. [Clustering](docs/1.clustering) - Running Coherence Clusters in Docker
4. [Coherence Extend](docs/2.extend) - Running Coherence Extend in Docker
5. [Federated Caching](docs/3.federation) - Federated Caching in Docker
6. [Disc Based Functionality](docs/4.disc_based) - Elastic Data and Persistence in Docker
7. [JMX Monitoring](docs/5.monitoring) - Using JMX in Docker

## Issues
If you find any issues with this Docker project, please report through the [GitHub Issues page](https://github.com/oracle/docker-images/issues).

## License
To download and run Coherence Distribution regardless of inside or outside a Docker container, and regardless of which distribution, you must agree and accept the [OTN Standard License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html).

To download and run Oracle JDK regardless of inside or outside a Docker container, you must agree and accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).

All scripts and files hosted in this project on GitHub [docker-images/OracleCoherence](https://github.com/oracle/docker-images/OracleCoherence) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses, except for the files listed above with their specific licenses.
