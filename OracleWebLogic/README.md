WebLogic on Docker
===============
This repository contains sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [Dockerfiles](dockerfiles/) and [samples](samples/) for WebLogic Server 12.1.3, 12.2.1, 12.2.1.1, 12.2.1.2, and 12.2.1.3 based on Oracle Linux and Oracle JDK 8 (Server).

The certification of WebLogic on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

For more information on the certification, please see the [WebLogic on Docker certification whitepaper](http://www.oracle.com/technetwork/middleware/weblogic/overview/weblogic-server-docker-containers-2491959.pdf) and [The WebLogic Server Blog](https://blogs.oracle.com/WebLogicServer/) for updates.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## How to build and run
This project offers sample Dockerfiles for WebLogic Server 12cR2 (12.2.1.x) and WebLogic Server 12c (12.1.3), and for each version, it also provides at least one Dockerfile for the 'developer' distribution and a second Dockerfile for the 'generic' distribution. To assist in building the images, you can use the [`buildDockerImage.sh`](https://github.com/oracle/docker-images/blob/master/OracleWebLogic/dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building the Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary to the folder `../OracleJava/java-8` and build that image. For more information, see the [`OracleJava`](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh

### Building the WebLogic Docker install images
**IMPORTANT:** You must download the WebLogic binary and put it in place (see `.download` files inside dockerfiles/<version>).

Before you build, select the version and distribution for which you want to build an image, then download the required packages (see `.download` files) and place them in the folder of your distribution version of choice. Then, from the `dockerfiles` folder, run the `buildDockerImage.sh` script as root.

        $ sh buildDockerImage.sh -h
        Usage: buildDockerImage.sh -v [version] [-d | -g | -i] [-s]
        Builds a Docker Image for Oracle WebLogic.

        Parameters:
           -v: version to build. Required.
           Choose one of: 12.1.3  12.2.1, 12.2.1.1, 12.2.1.2, 12.2.1.3  
           -d: creates image based on 'developer' distribution
           -g: creates image based on 'generic' distribution
           -i: creates image based on 'infrastructure' distribution
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        * select one distribution only: -d, -g, or -i

        LICENSE UPL 1.0

        Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will NOT have a domain pre-configured. You must extend the image with your own Dockerfile, and create your domain using WLST. You might want to take a look at the use case samples below.

## Samples for WebLogic domain creation
To give users an idea of how to create a domain from a custom Dockerfile that extends the WebLogic image, we provide a few samples for the 12c versions of the developer distribution. There are two types of domain samples:
  * Where the domain home is built inside a Docker image.  For an example on **12.2.1**, use the sample inside the [`samples/1221-domain`](samples/1221-domain) folder.
  * Where the domain home is mapped into a host volume.  For the **12.2.1.3** version, see the [`samples/12213-domain`](samples/12213-domain) folder.

## Clustering WebLogic on Docker containers
WebLogic has a [Machine](https://docs.oracle.com/middleware/12213/wls/WLACH/taskhelp/machines/ConfigureMachines.html) concept, which is an operational system with an agent, the Node Manager. This resource allows the WebLogic Administration Server to create and assign [Managed Servers](https://docs.oracle.com/middleware/12213/wls/WLACH/taskhelp/domainconfig/CreateManagedServers.html) of an underlying domain, in order to expand an environment of servers for different applications and resources, and also to define a [cluster](). With some WLST magic, your cluster can scale in and out.

### Clustering WebLogic on Docker containers on a single host
You can deploy to a WebLogic cluster using Docker with the samples scripts defined in the folder [`samples/12213-domain`](samples/12213-domain). After you have an Administration Server running in a container, you can easily create a cluster by deploying new Docker containers of Managed Servers.

To start the containerized Administration Server, run:

	$ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -v <host directory>:/u01/oracle/user_projects 12213-domain

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

	$ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS1 --volumes-from wlsadmin 12213-domain createServer.sh

To start a second Managed Server (MS2), run:

	$ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS2 --volumes-from wlsadmin 12213-domain createServer.sh

The above scenario from this sample will give you a WebLogic domain with a cluster set up on a single host environment.

### Clustering WebLogic on Docker containers across multiple hosts
By using the sample, [`samples/1221-multihost`](samples/1221-multihost), which contains a set of scripts that leverage the [Docker Machine](https://docs.docker.com/machine/) and [Docker Swarm](https://docs.docker.com/swarm/), and by digging through the scripts that create the containers across multiple hosts, combined with the scripts inside [`1221-domain/container-scripts`](samples/1221-domain/container-scripts), you can learn the necessary steps to deploy this with different Docker setups.

The basic idea behind this setup is that you must have all the containers across different hosts assigned to a specific [Docker Overlay Network](https://docs.docker.com/engine/userguide/networking/dockernetworks/#an-overlay-network), a feature of Docker 1.9 and later, that allows containers to join the same network even though they are running in different host environments.

### Create a WebLogic Server 12cR2 MedRec sample domain
The Supplemental Quick Installer is a lightweight installer that contains all of the necessary artifacts to develop and test applications on Oracle WebLogic Server 12.2.1.3. You can extend the WebLogic developer install image, `oracle/weblogic:12.2.1.3-developer`. to create a domain image with the MedRec application deployed.

  1. Make sure you have the `oracle/weblogic:12.2.1.3-developer` image built. If not, go into the [`dockerfiles`](dockerfiles/) and call:

        `$ sh buildDockerImage.sh -v 12.2.1.3 -d`

  2. Go to the folder [`samples/1221-medrec`](samples/1221-medrec).
  3. Download the supplemental package for WebLogic 12cR2 into this folder.

  4. Edit the Dockerfile to extend the 12.2.1.3 image.
  5. Run the following command:

        `$ docker build -t 12213-medrec .`

  5. Now run a container from this new sample domain image:

        `$ docker run -ti -p 7002:7002 12213-medrec`

  6. Access the Administration Server Console at:

        `http://localhost:7002/medrec`

## Choose your WebLogic distribution
This project hosts two configurations (depending on the WebLogic version) for building Docker images with WebLogic 12c.

 * Quick Install Developer Distribution

   - For more information on the WebLogic 12cR2 Quick Install Developer Distribution, visit [WLS Quick Install Distribution for Oracle WebLogic Server 12.2.1.3](http://download.oracle.com/otn/nt/middleware/12c/12213/README_12213.txt).

 * Generic Distribution

   - For more information on the WebLogic 12cR2 Generic Full Distribution, visit [WebLogic 12.2.1.3 Documentation](http://docs.oracle.com/middleware/12213/lcm/WLSIG/GUID-E4241C14-42D3-4053-8F83-C748E059607A.htm#WLSIG197)


## License
To download and run WebLogic 12c distribution, regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

To download and run the Oracle JDK, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleWebLogic`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
We support WebLogic Server in certified Docker containers, please read our Support statement. For additional details on the most current WebLogic Server supported configurations, please refer to the [Oracle Fusion Middleware Certification Pages] (http://www.oracle.com/technetwork/middleware/ias/oracleas-supported-virtualization-089265.html)

## Copyright
Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
