# Oracle Globally Distributed Database in Linux Containers

Learn about container deployment options for Oracle Globally Distributed Database in Linux Containers.

## Overview of Oracle Globally Distributed Database in Linux Containers

Oracle Globally Distributed Database is a scalability and availability feature for custom-designed OLTP applications that enables the distribution and replication of data across a pool of Oracle Databases that do not share hardware or software. The pool of databases is presented to the application as a single logical database.

This project provides sample container files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database, see: [Oracle Globally Distributed Database Management Documentation](http://docs.oracle.com/en/database/).

Review each of the sections of this README in the order given. After reviewing each section of the README, you can skip the image or container creation sections that do not apply to you.

This project offers example container files for the following:

- Oracle Global Service Manager (GSM/GDS) for Oracle AI Database 26ai for Linux x86-64
- Oracle Global Service Manager (GSM/GDS) for Oracle 21c (21.3) for Linux x86-64
- Oracle Global Service Manager (GSM/GDS) for Oracle 19c (19.3) for Linux x86-64

## Using this Documentation

To create an Oracle Globally Distributed Database Container environment, follow these steps:

- [Oracle Globally Distributed Database in Linux Containers](#oracle-globally-distributed-database-in-linux-containers)
  - [Overview of Oracle Globally Distributed Database in Linux Containers](#overview-of-oracle-globally-distributed-database-in-linux-containers)
  - [Using this Documentation](#using-this-documentation)
  - [Preparation Steps for running Oracle Globally Distributed Database in Linux Containers](#preparation-steps-for-running-oracle-globally-distributed-database-in-linux-containers)
  - [QuickStart](#quickstart)
  - [Building Oracle Globally Distributed Database Container Images](#building-oracle-globally-distributed-database-container-images)
    - [Getting Oracle Global Service Manager Image from Oracle Container Registry](#getting-oracle-global-service-manager-image-from-oracle-container-registry)  
    - [Building Oracle Global Service Manager Image](#building-oracle-global-service-manager-image)
    - [Building Oracle Single Instance Database Image](#building-oracle-single-instance-database-image)
    - [Building Extended Oracle Single Instance Database Image with Oracle Globally Distributed Database Feature](#building-extended-oracle-single-instance-database-image-with-oracle-globally-distributed-database-feature)
    - [Building Oracle RAC Database Container Image](#building-oracle-rac-database-container-image)
    - [Building Extended Oracle RAC Database Container Image with Oracle Globally Distributed Database Feature](#building-extended-oracle-rac-database-container-image-with-oracle-globally-distributed-database-feature)
  - [Oracle Globally Distributed Database in Containers Deployment Scenarios](#oracle-globally-distributed-database-in-containers-deployment-scenarios)
    - [Deploy Oracle Globally Distributed Database Containers](#deploy-oracle-globally-distributed-database-containers)
      - [Deploy Oracle Globally Distributed Database Containers on Podman using Oracle AI Database 26ai Free Image](#deploy-oracle-globally-distributed-database-containers-on-podman-using-oracle-ai-database-26ai-free-image)
      - [Deploy Oracle Globally Distributed Database using Single Instance Database in Podman Containers](#deploy-oracle-globally-distributed-database-using-single-instance-database-in-podman-containers)
      - [Deploy Oracle Globally Distributed Database using Oracle Restart in Podman Containers](#deploy-oracle-globally-distributed-database-using-oracle-restart-in-podman-containers)
      - [Deploy Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers](#deploy-oracle-globally-distributed-database-using-oracle-rac-database-in-podman-containers)
      - [Deploy Oracle Globally Distributed Database Containers on earlier OS Release](#deploy-oracle-globally-distributed-database-containers-on-earlier-os-release)
  - [Oracle Globally Distributed Database in Containers Deployment using podman-compose](#oracle-globally-distributed-database-in-containers-deployment-using-podman-compose)
  - [Oracle Globally Distributed Database in Containers Deployment using docker-compose](#oracle-globally-distributed-database-in-containers-deployment-using-docker-compose)  
  - [Oracle Container Registry Images for Oracle Globally Distributed Database Deployment](#oracle-container-registry-images-for-oracle-globally-distributed-database-deployment)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)
  
## Preparation Steps for running Oracle Globally Distributed Database in Linux Containers

**Note:** All Steps or Commands in this guide must be run as `root` or with a `sudo` user.

- Before you proceed, complete the following prerequisites for your platform:
  - If you are using Oracle Linux 8 or higher, then Install Podman.
    - You must install and configure [Podman release 4.9.4](https://docs.oracle.com/en/learn/intro_podman/index.html#introduction) or later on Oracle Linux 8.10 or later to run Oracle Globally Distributed Database on Podman.
    - You need to install `podman-docker` utility using dnf command.

      ```bash
      # Enable the Oracle Linux 8 AppStream repository
      dnf config-manager --enable ol8_appstream

      # Install Podman and Podman-docker
      dnf install -y podman podman-docker
      ```

    - If SELinux is enabled on podman host, then install the following package as well:

      ```bash
      dnf install -y selinux-policy-devel
      ```

  - If you are using `Older` Oracle Linux 7, then install Docker.
    - If you are using an older Oracle Linux 7 system, then you must install [Docker Engine](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/).
    - Install `docker-engine` and `docker-cli` using yum command.

      ```bash
      yum-config-manager --enable ol7_addons
      yum install docker-engine docker-cli
      yum start docker
      systemctl enable --now docker               
      ```

## QuickStart

Oracle recommends that you start with the Quickstart to become familiar with Oracle Globally Distributed Database in Linux Containers. See: [QuickStart documentation](./docs/QUICKSTART.md).

After you become familiar with Oracle Globally Distributed Database in Linux Containers, you can explore more advanced setups, deployments, features, and so on, as explained in detail in [Oracle Globally Distributed Database in Containers Deployment Scenarios](#oracle-globally-distributed-database-in-containers-deployment-scenarios).

**Note:** Ensure that you have enough space in `/var/lib/containers` while building the Oracle Globally Distributed Database images. Also, if required use `export TMPDIR=</path/to/tmpdir>` for Podman to refer to any other folder as the temporary podman cache location instead of the default `/tmp` location.

## Building Oracle Globally Distributed Database Container Images

**IMPORTANT:** Oracle Global Service Manager (GDS) container is useful when you want to configure the Global Data Service Framework. A Global Data Services framework consists of at least one global service manager, a Global Data Services catalog, and the GDS configuration databases.

### Getting Oracle Global Service Manager Image from Oracle Container Registry

**IMPORTANT:** If you want to use the Global Service Manager image (GSM image) of Oracle 26ai version, you can download that directly from `container-registry.oracle.com` using the link `container-registry.oracle.com/database/gsm:latest`. To use with this GSM image, you can use the link `container-registry.oracle.com/database/enterprise:latest` to download the compatible database container image for Oracle AI Database 26ai.

Example of pulling these images from the Oracle Container Registry for Oracle AI Database 26ai:

```bash
# For Oracle AI Database 26ai Container Image
podman pull container-registry.oracle.com/database/enterprise:latest

# For Oracle GSM Container Image of Oracle 26ai version
podman pull container-registry.oracle.com/database/gsm:latest
```

**NOTE** Currently, latest tag in Oracle Container registry represents `23.26.1.0` tag. If you are pulling any other version of container image, then retag approriately as per your environment to use in `podman create` commands later.

Example of pulling these images from the Oracle Container Registry for another version:

```bash
# For Oracle Database 19.28 RU Container Image
podman pull container-registry.oracle.com/database/enterprise_ru:19.28.0.0

# For Oracle GSM Container Image of Oracle 19.28 RU version
podman pull container-registry.oracle.com/database/gsm_ru:19.28.0.0
```

**IMPORTANT:** If you want to use pre-built images available on Oracle Container Registry for Oracle Database and Oracle GSM, make sure the version of `openssl` in those images is compatible with the `openssl` version on the machine where you will run the openssl commands to generated the encrypted password file during the deployment. Please refer to the section [Oracle Container Registry Images for Oracle Globally Distributed Database Deployment](#oracle-container-registry-images-for-oracle-globally-distributed-database-deployment).

### Building Oracle Global Service Manager Image

To create an Oracle Global Service Manager image (GSM image) of another version, you must provide the installation binaries of `Oracle Global Service Manager (GSM/GDS) for Oracle Database for Linux x86-64` for that version and put them into the `containerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html). You must ensure that you have internet connectivity for the DNF package manager.

**Note:** Do not uncompress the binaries.

To assist with building the images, you can use the [buildContainerImage.sh](containerfiles/buildContainerImage.sh) script.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks. This script provides an easy way for beginners to get started. Expert users can directly call `podman build` with their preferred set of parameters. Before you build the image, ensure that you have provided the installation binaries and put them into the right folder. In the below example, GSM Image of version `21.3.0` will be built. Go into the **containerfiles** folder and run the **buildContainerImage.sh**  script as `root` or with `sudo` privileges:

```bash
./buildContainerImage.sh -v (Software Version)
./buildContainerImage.sh -v 26.0.0
```

For detailed usage information for `buildContainerImage.sh`, run the following command:

```bash
./buildContainerImage.sh -h
Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s] [-i] [-o] [container build option]
It builds a container image for a DNS server

Parameters:
   -v: version to build
   -i: ignores the MD5 checksums
   -t: user defined image name and tag (e.g., image_name:ta
   -o: passes on container build option (e.g., --build-arg SLIMMIMG=true for slim)

LICENSE UPL 1.0

Copyright (c) 2014,2024 Oracle and/or its affiliates.
```

### Building Oracle Single Instance Database Image

To build Oracle Globally Distributed Database using Single Instance Database containers, download the project files and build an Oracle Single Instance Database Image. See the Oracle Database Single Instance [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md), which is available on the Oracle GitHub repository.

**Note:** Use the [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md) to create the image, and do not use the container instructions.  

For the container, use the steps given in this document under the [Oracle Globally Distributed Database in Containers Deployment Scenarios](#oracle-globally-distributed-database-in-containers-deployment-scenarios) section.

### Building Extended Oracle Single Instance Database Image with Oracle Globally Distributed Database Feature

**IMPORTANT:** If you want to use the Extended Oracle Single Instance Database Image with Oracle Globally Distributed Database Feature of Oracle 26ai FREE version, you can download that directly from `container-registry.oracle.com` using the link `container-registry.oracle.com/database/free:latest`

After creating the base image using `buildContainerImage.sh` in the previous step, use the `buildExtensions.sh` script that is under the `extensions` folder to build an extended image. This extended image will include the Oracle Globally Distributed Database Feature. For more information, refer to the [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/extensions/README.md) in the `extensions` folder for the Oracle Single Instance Database, which is available on the Oracle GitHub repository.

For example:

```bash
./buildExtensions.sh -x sharding -b oracle/database:26.0.0-ee  -t oracle/database-ext-sharding:26.0.0-ee -o "--build-arg BASE_IMAGE_VERSION=26.0.0"

Where:
"-x sharding"                                   is to specify to have sharding feature in the extended image
"-b oracle/database:26.0.0-ee"                  is to specify the Base image created in previous step
"oracle/database-ext-sharding:26.0.0-ee"        is to specify the name:tag for the extended image with Sharding Feature
-o "--build-arg BASE_IMAGE_VERSION=26.0.0"      is to specify the BASE_IMAGE_VERSION to clone from git repo
```

To see more usage instructions for the `buildExtensions.sh` script, run the following command:

```bash
./buildExtensions.sh -h

Usage: buildExtensions.sh -a -x [extensions] -b [base image] -t [image name] -v [version] [-o] [container build option]
Builds one of more Container Image Extensions.

Parameters:
   -a: Build all extensions
   -x: Space separated extensions to build. Defaults to all
       Choose from : k8s  patching  prebuiltdb  sharding  truecache
   -b: Base image to use
   -v: Base version to extend (example 21.3.0)
   -t: name:tag for the extended image
   -o: passes on Container build option

LICENSE UPL 1.0

Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.
```

### Building Oracle RAC Database Container Image

**NOTE:** Oracle RAC Database Container Image Feature is NOT Available for Oracle AI Database 26ai Free version.

Oracle Globally Distributed Database on a container can also be deployed using Oracle Restart and Oracle RAC. To use Oracle Restart or Oracle RAC and build Oracle Globally Distributed Database using containers, download the project files and build an Oracle RAC Database Container Image. See the Oracle Real Application Clusters in Linux Containers [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/RAC/OracleRealApplicationClusters/README.md), which is available on the Oracle GitHub repository.

**Note**: Use the [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/RAC/OracleRealApplicationClusters/README.md) to create the image, and do not use the container instructions. For the container, use the steps given in this document under the [Oracle Globally Distributed Database in Containers Deployment Scenarios](#oracle-globally-distributed-database-in-containers-deployment-scenarios) section.

### Building Extended Oracle RAC Database Container Image with Oracle Globally Distributed Database Feature

After creating the base image using `buildContainerImage.sh` in the previous step, use the `buildExtensions.sh` script that is under the `extensions` folder to build an extended image. This extended image will include the Oracle Globally Distributed Database Feature. For more information, refer to the [README.MD](https://github.com/oracle/docker-images/blob/main/OracleDatabase/RAC/OracleRealApplicationClusters/extensions/README.md) in the `extensions` folder for the Oracle Real Application Clusters in Linux Containers, which is available on the Oracle GitHub repository.

For example:

```bash
./buildExtensions.sh -x sharding -b oracle/database-rac:26.0.0 -t oracle/database-rac-ext-sharding:26.0.0-ee -o "--build-arg BASE_IMAGE_VERSION=26.0.0"

Where:
"-x sharding"                                   is to specify to have sharding feature in the extended image
"-b oracle/database-rac:26.0.0"                 is to specify the Base image created in previous step
"oracle/database-rac-ext-sharding:26.0.0-ee"    is to specify the name:tag for the extended image with Oracle Globally Distributed Database Feature
-o "--build-arg BASE_IMAGE_VERSION=26.0.0"      is to specify the BASE_IMAGE_VERSION to clone from git repo
```

To see usage instructions for the `buildExtensions.sh` script, run the following command:

```bash
./buildExtensions.sh -h

Usage: buildExtensions.sh -a -x [extensions] -b [base image] -t [image name] -v [version] [-o] [container build option]
Builds one of more Container Image Extensions.

Parameters:
   -a: Build all extensions
   -x: Space separated extensions to build. Defaults to all
       Choose from : sharding
   -b: Base image to use
   -v: Base version to extend (example 21.3.0)
   -t: name:tag for the extended image
   -o: passes on Container build option

LICENSE UPL 1.0

Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.
```

## Oracle Globally Distributed Database in Containers Deployment Scenarios

### Deploy Oracle Globally Distributed Database Containers

If you want to manually deploy the Oracle Globally Distributed Database using Docker or Podman containers, then use the sections that follow to see the step by step procedure.

#### Deploy Oracle Globally Distributed Database Containers on Podman using Oracle AI Database 26ai Free Image

To deploy an Oracle Globally Distributed Database on Podman using Oracle AI Database 26ai Free Image, see: [Deploy Oracle Globally Distributed Database Containers on Podman using Oracle AI Database 26ai Free Image](./samples/container-files/podman-container-files-free/README.md). This document provides the commands that you need to deploy an Oracle Globally Distributed Database with Oracle AI Database 26ai Free Image using Podman with System-Managed Sharding or with System-Managed Sharding with RAFT replication or with User Defined Sharding.

#### Deploy Oracle Globally Distributed Database using Single Instance Database in Podman Containers

To deploy Oracle Globally Distributed Database using Single Instance Database in Podman Containers, we will use Extended Oracle Single Instance Database Image with Enterprise Edition Software, see: [Deploy Oracle Globally Distributed Database using Single Instance Database in Podman Containers](./samples/container-files/podman-container-files/README.md). The individual shards and the catalog database are deployed using Single Instance Database in Podman Containers. In this case, the Oracle Globally Distributed Database can be deployed with System-Managed Sharding or with System-Managed Sharding with RAFT replication or with User Defined Sharding.

#### Deploy Oracle Globally Distributed Database using Oracle Restart in Podman Containers

To deploy an Oracle Globally Distributed Database using Oracle Restart in Podman Containers, we will use Extended Oracle RAC Database Container Image, see: [Deploy Oracle Globally Distributed Database using Oracle Restart in Podman Containers](./samples/container-files/podman-container-files-gpc/README.md). The individual shards and the catalog database are deployed using Oracle Restart in Podman Containers. So, we have Automatic Storage Management(ASM) feature available for individual Shard and the Catalog Database. In this case, the Oracle Globally Distributed Database can be deployed with either System-Managed Sharding or System-Managed Sharding with RAFT replication or with User Defined Sharding.

**NOTE:** Oracle Globally Distributed Database using Oracle Restart in Podman Containers is _not_ available for Oracle AI Database 26ai Free version.

#### Deploy Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers

To deploy an Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers, see: [Deploy Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers](./samples/container-files/podman-container-files-rac/README.md). The individual shards and the catalog database are deployed as Oracle RAC Databases in Podman Containers. So, we have active/active Oracle Database high availability and scalability features available for individual Shard and the Catalog Database. In this case, the Oracle Globally Distributed Database can be deployed with either System-Managed Sharding or with User Defined Sharding.

**NOTE:** Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers is _not_ available for Oracle AI Database 26ai Free version.

#### Deploy Oracle Globally Distributed Database Containers on earlier OS Release

**NOTE:** Podman can be used on Oracle Linux 8 onwards. If you want to use the Oracle Database 19c or Oracle Database 21c release-based container images on earlier Oracle Linux Release (Oracle Linux 7), then you use Docker.

To deploy an Oracle Globally Distributed Database Containers on earlier OS Release, see: [Deploy Oracle Globally Distributed Database Containers on Docker](./samples/container-files/docker-container-files/README.md). This document provides the commands that you need to deploy an Oracle Globally Distributed Database using Docker with either System-Managed Sharding or with User Defined Sharding.

## Oracle Globally Distributed Database in Containers Deployment using podman-compose

To deploy an Oracle Globally Distributed Database in Containers using podman-compose, refer to [Deploying Oracle Globally Distributed Database Containers using podman-compose](./samples/compose-files/podman-compose/README.md)

## Oracle Globally Distributed Database in Containers Deployment using docker-compose

This case is applicable if you want to use an earlier OS version i.e. Oracle Linux 7 to deploy Oracle Globally Distributed Database Containers. In this case, you can not use `podman-compose` and will need to use `docker-compose`.

To deploy an Oracle Globally Distributed Database in Containers using docker-compose, refer to [Deploying Oracle Globally Distributed Database Containers using docker-compose](./samples/compose-files/docker-compose/README.md)

## Oracle Container Registry Images for Oracle Globally Distributed Database Deployment

If you want to use Pre-built Oracle Database and Oracle GSM Container images from Oracle Container Registry, you can refer to below set of images, their openssl version and the openssl version of the host machine on which the encrypted password file was generated before the deployment using these set of images:

- Deployment using 19.25 RU Images:

| Image                                                           | Image Openssl Version | Image Id     | Host Machine Openssl Version |
|-----------------------------------------------------------------|-----------------------|--------------|------------------------------|
| container-registry.oracle.com/database/enterprise_ru:19.25.0.0  | OpenSSL 1.0.2k-fips   | 8f776e5d33dc | OpenSSL 1.1.1k               |
| container-registry.oracle.com/database/gsm_ru:19.25.0.0         | OpenSSL 1.1.1k  FIPS  | 87ed4fe32b3a | OpenSSL 1.1.1k               |

- Deployment using Oracle AI Database 26ai FREE Images:

| Image                                                           | Image Openssl Version | Image Id     | Host Machine Openssl Version |
|-----------------------------------------------------------------|-----------------------|--------------|------------------------------|
| container-registry.oracle.com/database/free:latest              | OpenSSL 1.1.1k  FIPS  | 7c044a242a1c | OpenSSL 3.5.1                |
| container-registry.oracle.com/database/gsm:latest               | OpenSSL 1.1.1k  FIPS  | e1d303ddb97c | OpenSSL 3.5.1                |

- Deployment using Oracle AI Database 26ai Enterprise Images:

| Image                                                           | Image Openssl Version | Image Id     | Host Machine Openssl Version |
|-----------------------------------------------------------------|-----------------------|--------------|------------------------------|
| container-registry.oracle.com/database/enterprise:latest        | OpenSSL 3.5.4         | 7c044a242a1c | OpenSSL 3.5.1                |
| container-registry.oracle.com/database/gsm:latest               | OpenSSL 1.1.1k  FIPS  | e1d303ddb97c | OpenSSL 3.5.1                |

- Deployment using 21.3 Images:

| Image                                                           | Image Openssl Version | Image Id     | Host Machine Openssl Version |
|-----------------------------------------------------------------|-----------------------|--------------|------------------------------|
| container-registry.oracle.com/database/enterprise:21.3.0.0      | OpenSSL 1.0.2k-fips   | 35e92315f1f8 | OpenSSL 1.1.1k               |
| container-registry.oracle.com/database/gsm:21.3.0.0             | OpenSSL 1.1.1k  FIPS  | 523f362fee17 | OpenSSL 1.1.1k               |

## Support

Oracle Global Service Manager (GSM) and Oracle Globally Distributed Database on Docker is supported on Oracle Linux 7.
Oracle Database 23ai GSM and Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and onwards.

## License

To download and run Oracle Global Service Manager (GSM) and Oracle Globally Distributed Database, either inside or outside a Container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
