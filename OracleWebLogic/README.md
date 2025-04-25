# WebLogic on Docker

This repository contains sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [Dockerfiles](dockerfiles/) and [samples](samples/) for WebLogic Server 12.2.1.4, 14.1.1.0, and 14.1.2.0 based on Oracle Linux and Oracle JDK 8, 11, 17, and 21.

**IMPORTANT**: We provide Dockerfiles as samples to build WebLogic images but this is _NOT_ a recommended practice. We recommend obtaining patched WebLogic Server images; patched images have the latest security patches. For more information, see [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches](<https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html#GUID-4FB15429-C985-472F-BDC6-669CA1B678E8>).

The samples in this repository are for development purposes only. We recommend for production to use alternative methods, we suggest obtaining base WebLogic Server images from the [Oracle Container Registry](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/ocr-images/>).

Consider using the open source [WebLogic Image Tool](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/custom-images/>) to create custom images, and using the open source [WebLogic Kubernetes Operator](<https://oracle.github.io/weblogic-kubernetes-operator/>) to deploy and manage WebLogic domains.

The certification of WebLogic on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](<https://container-registry.oracle.com>).

## How to build and run
This project offers sample Dockerfiles for WebLogic Server 12c and 14c, it also provides at least one Dockerfile for the 'developer' distribution, a second for slim distribution, and third Dockerfile for the 'generic' distribution. In WebLogic Server 14.1.2 there is a single distribution.  

To assist in building the images, you can use the [`buildDockerImage.sh`](<https://github.com/oracle/docker-images/blob/master/OracleWebLogic/dockerfiles/buildDockerImage.sh>) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building the Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary to the folder `../OracleJava/java-8` and build that image. For more information, see the [`OracleJava`](../OracleJava) folder's [README](../OracleJava/README.md) file.

        `$ cd ../OracleJava/java-8`
        `$ sh build.sh`

### Building the WebLogic Docker install images
**IMPORTANT**: You must download the WebLogic binary and put it in its correct location (see `.download` files inside `dockerfiles/<version>`).

Before you build, select the version and distribution for which you want to build an image, then download the required packages (see `.download` files) and place them in the folder of your distribution version of choice. Then, from the `dockerfiles` folder, run the `buildDockerImage.sh` script as root.

        `$ sh buildDockerImage.sh -h`
        Usage: buildDockerImage.sh -v [version] [-d | -g | -i] [-s] [-j]
        Builds a Docker Image for Oracle WebLogic.

## Clustering WebLogic on Docker containers
WebLogic has a [Machine](<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/tasks/machines.html>) concept, which is an operational system with an agent, the Node Manager.
This resource allows the WebLogic Administration Server to create and assign [Managed Servers](<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/tutorial-create-configure-managed-servers/>) of an underlying domain.

In order to expand an environment of servers for different applications and resources, and also to define a [cluster](<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/tasks/clusters.html>). With some WLST magic, your cluster can scale in and out.

### Clustering WebLogic on Docker containers on a single host
You can deploy to a WebLogic cluster using Docker with the samples scripts defined in the folder [`samples/12214-domain`](samples/12214-domain). After you have an Administration Server running in a container, you can easily create a cluster by deploying new Docker containers of Managed Servers.

To start the containerized Administration Server, run:

        `$ docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -v <host directory>:/u01/oracle/user_projects 12214-domain`

To start a containerized Managed Server (MS1) to self-register with the Administration Server above, run:

        `$ docker run -d --name MS1 --link wlsadmin:wlsadmin -p 8001:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS1 --volumes-from wlsadmin 12214-domain createServer.sh`

To start a second Managed Server (MS2), run:

        `$ docker run -d --name MS2 --link wlsadmin:wlsadmin -p 8002:8001 --env-file ./container-scripts/domain.properties -e ADMIN_PASSWORD=<admin_password> -e MS_NAME=MS2 --volumes-from wlsadmin 12214-domain createServer.sh`

The above scenario from this sample will give you a WebLogic domain with a cluster set up on a single host environment.

## Choose your WebLogic distribution
This project hosts two configurations (depending on the WebLogic version) for building Docker images with WebLogic 12c.

* Quick Install Developer Distribution

- For more information on the WebLogic 122 Quick Install Developer Distribution, see [WLS Quick Install Distribution for Oracle WebLogic Server 12.2.1.4](<https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/wlsig/planning-oracle-weblogic-server-installation.html#GUID-0CC5BF6C-770F-4432-9EBA-393BC0A443E7>).

* Generic Distribution

- For more information on the WebLogic 12c Generic Full Distribution, see [WebLogic 12.2.1.4 Documentation](<https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/wlsig/planning-oracle-weblogic-server-installation.html#GUID-0CC5BF6C-770F-4432-9EBA-393BC0A443E7>)


## License
To download and run the WebLogic 12c distribution, regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

To download and run the Oracle JDK, regardless of inside or outside a Docker container, you must download the binary from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [`docker/OracleWebLogic`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](<https://oss.oracle.com/licenses/upl>/) license.

## Customer Support
We support WebLogic Server in certified Docker containers, please read our Support statement. For additional details on the most current WebLogic Server supported configurations, please refer to the [Oracle Fusion Middleware Certification Pages](http://www.oracle.com/technetwork/middleware/ias/oracleas-supported-virtualization-089265.html).

## Copyright
Copyright (c) 2014, 2025, Oracle and/or its affiliates.
