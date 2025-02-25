# Oracle Real Application Clusters in Linux Containers for Developers

Learn about container deployment options for Oracle Real Application Clusters (Oracle RAC) Release 21c (v21.3).

## Overview of Running Oracle RAC in Containers

Oracle Real Application Clusters (Oracle RAC) is an option for the award-winning Oracle Database Enterprise Edition. Oracle RAC is a cluster database with a shared cache architecture that overcomes the limitations of traditional shared-nothing and shared-disk approaches to provide highly scalable and available database solutions for all business applications.

Oracle RAC uses Oracle Clusterware as a portable cluster software that allows clustering of independent servers so that they cooperate as a single system, and Oracle Automatic Storage Management (Oracle ASM) to provide simplified storage management that is consistent across all servers and storage platforms.
Oracle Clusterware and Oracle ASM are part of the Oracle Grid Infrastructure, which bundles both solutions in an easy-to-deploy software package.

For more information on Oracle RAC Database 21c, refer to the [Oracle Database documentation](http://docs.oracle.com/en/database/).

This guide helps you install Oracle RAC on Containers on Host Machines as explained in detail below. With the current release, you prepare the host machine, build or use pre-built Oracle RAC Container Images v21.3, and set up Oracle RAC on Single or Multiple Host machines with Oracle ASM.
In this installation guide, we use [Podman](https://docs.podman.io/en/v3.0/) to create Oracle RAC Containers and manage them.

## Using this Documentation
To create an Oracle RAC environment, follow these steps:

- [Oracle Real Application Clusters in Linux Containers for Developers](#oracle-real-application-clusters-in-linux-containers-for-developers)
  - [Overview of Running Oracle RAC in Containers](#overview-of-running-oracle-rac-in-containers)
  - [Using this Documentation](#using-this-documentation)
  - [Preparation Steps for Running Oracle RAC in Containers](#preparation-steps-for-running-oracle-rac-database-in-containers)
  - [Getting Oracle RAC Database Container Images](#getting-oracle-rac-database-container-images)
    - [Building Oracle RAC Database Container Image](#building-oracle-rac-database-container-image)
    - [Building Oracle RAC Database Container Slim Image](#building-oracle-rac-database-container-slim-image)
  - [Network Management](#network-management)
  - [Password Management](#password-management)
  - [Oracle RAC on Containers Deployment Scenarios](#oracle-rac-on-containers-deployment-scenarios)
    - [Oracle RAC Containers on Podman](#oracle-rac-containers-on-podman)  
      - [Setup Using Oracle RAC Image](#1-setup-using-oracle-rac-container-image)
      - [Setup Using Oracle RAC Slim Image](#2-setup-using-oracle-rac-container-slim-image)
  - [Connecting to an Oracle RAC Database](#connecting-to-an-oracle-rac-database)
  - [Deletion of Node from Oracle RAC Cluster](#deletion-of-node-from-oracle-rac-cluster)
  - [Building a Patched Oracle RAC Container Image](#building-a-patched-oracle-rac-container-image)
  - [Sample Container Files for Older Releases](#sample-container-files-for-older-releases)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Preparation Steps for Running Oracle RAC Database in Containers

Before you proceed to the next section, you must complete each of the steps listed in this section and complete the following prerequisites.

* Refer to the following sections in the publication [Oracle Real Application Clusters Installation Guide](https://docs.oracle.com/cd/F39414_01/racpd/oracle-real-application-clusters-installation-guide-podman-oracle-linux-x86-64.pdf) for Podman Oracle Linux x86-64 to complete the preparation steps for Oracle RAC on Container deployment:

  * Overview of Oracle RAC on Podman
  * Host Preparation for Oracle RAC on Podman
  * Podman Host Server Configuration
  * Podman Containers and Oracle RAC Nodes
  * Provisioning the Podman Host Server
  * Podman Host Preparation
    * Preparing for Podman Container Installation
    * Installing Podman Engine
    * Allocating Linux Resources for Oracle Grid Infrastructure Deployment
    * How to Configure Podman for SELinux Mode
* Install `git` from dnf or yum repository and clone the git repo. We clone this repo on a path called `<GITHUB_REPO_CLONED_PATH>` and refer here.
* If you are planning to use NFS storage for OCR, Voting Disk, and Database files, then configure NFS storage and export at least one NFS mount. You can also use the `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRACStorageServer` container for the shared file system on NFS. Refer [OracleRACStorageServer](../OracleRACStorageServer/README.md).

* If SELinux is enabled on the Podman host, you must create an SELinux policy for Oracle RAC on Podman. For details about this procedure, see `How to Configure Podman for SELinux Mode` in the publication [Oracle Real Application Clusters Installation Guide for Podman Oracle Linux x86-64](https://docs.oracle.com/en/database/oracle/oracle-database/21/racpd/target-configuration-oracle-rac-podman.html#GUID-59138DF8-3781-4033-A38F-E0466884D008).
Also, when you are performing the installation using any files from a Podman host machine where SELinux is enabled, make sure they are labeled correctly with `container_file_t` context. You can use `ls -lZ <file_name/<Directory_name>` to see the security context set on files.

* To resolve VIPs and SCAN IPs, in this guide we use a DNS container. Before proceeding to the next step, create a [DNS server container](../OracleDNSServer/README.md).
If you have a preconfigured DNS server in your environment, then you can replace `-e DNS_SERVERS=10.0.20.25`, `--dns=10.0.20.25`, `-e DOMAIN=example.info`, and `--dns-search=example.info` parameters in the examples in this guide with the `DOMAIN_NAME` and `DNS_SERVER` based on your environment.

* The Oracle RAC `Containerfile` does not contain any Oracle software binaries. Download the following software from the [Oracle Technology Network](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html), if you are planning to build Oracle RAC Container Images from the next section.
However, if you are using pre-built RAC images from the Oracle Container Registry, you can skip this step.
  - Oracle Grid Infrastructure 21c (21.3) for Linux x86-64
  - Oracle Database 21c (21.3) for Linux x86-64

**Notes**

- **For testing purposes only**, use the Oracle `DNSServer` Image to deploy a container providing DNS resolution. Refer [OracleDNSServer](../OracleDNSServer/README.md) for details.
- `OracleRACStorageServer` container image can be used **only for testing purposes**. Refer [OracleRACStorageServer](../OracleRACStorageServer/README.md) for details.
- If the Podman bridge network is not available outside your host, you can use the Oracle Connection Manager [CMAN image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleConnectionManager) to access the Oracle RAC Database from outside the host.

## Getting Oracle RAC Database Container Images

Oracle RAC is supported for production use on Podman starting with Oracle Database 19c (19.16), and Oracle Database 21c (21.7). You can also deploy Oracle RAC on Podman using the pre-built images available on the Oracle Container Registry.
Refer to [this documentation](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/docker-UsingDockerRegistries.html#docker-registry) for details on using the Oracle Container Registry.

Example of pulling an Oracle RAC Image from the Oracle Container Registry:
```bash
# For Oracle RAC Container Image
podman pull container-registry.oracle.com/database/rac_ru:latest
podman tag container-registry.oracle.com/database/rac_ru:latest localhost/oracle/database-rac:21c
```
**NOTE** Currently, latest tag in Oracle Container registry represents `21.16.0` tag. If you are pulling any other version of container image, then retag approriately as per your environment to use in `podman create` commands later.

If you are using pre-built Oracle RAC images from the Oracle Container Registry, then you can skip the section that follows where we build the container images.

If you want to build the latest Oracle RAC Image from this Github repository, instead of a pre-built image, then then follow these instructions.

**IMPORTANT :** This section assumes that you have completed all of the prerequisites in [Preparation Steps for running Oracle RAC Database in containers](#preparation-steps-for-running-oracle-rac-database-in-containers) and completed all the steps, based on your environment. Ensure that you do not uncompress the binaries and patches manually before building the Oracle RAC Image.

To assist in building the images, you can use the [`buildContainerImage.sh`](./containerfiles/buildContainerImage.sh) script. See the following for instructions and usage.

### Building Oracle RAC Database Container Image

In  this document, Oracle RAC Database Container Image refers to an Oracle RAC Database Container Image with Oracle Grid Infrastructure and Oracle Database software binaries installed during Oracle RAC Podman image creation. The resulting images will contain the Oracle Grid Infrastructure and Oracle RAC Database software binaries.
Before you begin, you must download grid and database binaries and stage them under `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRealApplicationCluster/containerfiles/<VERSION>`.

```bash
 ./buildContainerImage.sh -v <Software Version>
```
Example: Building Oracle RAC image for v 21.3.0-
```bash
 ./buildContainerImage.sh -v 21.3.0
```

### Building Oracle RAC Database Container Slim Image
In this document, an Oracle RAC container slim image refers to a container image that does not include installing Oracle Grid Infrastructure and Oracle Database during the Oracle RAC image creation. To build an Oracle RAC slim image that doesn't contain the Oracle RAC Database and Grid infrastructure software, run the following command:
```bash
  ./buildContainerImage.sh -v <Software Version> -i -o '--build-arg SLIMMING=true'
```
  Example: Building Oracle Slim Image for v 21.3.0-
 ```bash
 ./buildContainerImage.sh -v 21.3.0 -i -o '--build-arg SLIMMING=true'
 ```
 To build an Oracle RAC slim image, you must use `--build-arg SLIMMING=true`.
 To change the base image for building Oracle RAC images, you must use `--build-arg  BASE_OL_IMAGE=oraclelinux:9`.

**Notes**
- Usage of `./buildContainerImage.sh`-
   ```text
   -v: version to build
   -i: ignore the MD5 checksums
   -t: user-defined image name and tag (e.g., image_name:tag). Default is set to `oracle/database-rac:<VERSION>` for  RAC Image and `oracle/database-rac:<VERSION>-slim` for RAC slim image.
   -o: passes on container build option (e.g., --build-arg SLIMMIMG=true for slim,--build-arg  BASE_OL_IMAGE=oraclelinux:9 to change base image). The default is "--build-arg SLIMMING=false"
   ```
- Ensure that you have enough space in `/var/lib/containers` while building the Oracle RAC image. Also, if required use `export TMPDIR=</path/to/tmpdir>` for Podman to refer to any other folder as the temporary podman cache location instead of the default '/tmp' location.
- After the `21.3.0` Oracle RAC container image is built, to apply the 21c RU and build the 21c patched image, refer to [Example of how to create a patched database image](./samples/applypatch/README.md).
- If you are behind a proxy wall, then you must set the `https_proxy` or `http_proxy` environment variable based on your environment before building the image.
- In the slim image case, the resulting images will not contain the Oracle Grid Infrastructure binaries and Oracle RAC Database binaries.

## Network Management

Before you start the installation, you must plan your private and public network. Refer to section `Podman Host Preparation` in the publication [Oracle Real Application Clusters Installation Guide](https://docs.oracle.com/cd/F39414_01/racpd/oracle-real-application-clusters-installation-guide-podman-oracle-linux-x86-64.pdf) for Podman Oracle Linux x86-64.
You can create a `network bridge` on every container host so containers running within that host can communicate with each other. For example:  create `rac_pub1_nw` for the public network (`10.0.20.0/24`) and `rac_priv1_nw` (`192.168.17.0/24`) for a private network.
You can use any network subnet for testing. In this document we define the public network on `10.0.20.0/24` and the private network on `192.168.17.0/24`.

```bash
  podman network create --driver=bridge --subnet=10.0.20.0/24 rac_pub1_nw
  podman network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw --disable-dns --internal
  podman network create --driver=bridge --subnet=192.168.18.0/24 rac_priv2_nw --disable-dns --internal

```

- To run Oracle RAC using Oracle Container Runtime for Docker on multiple hosts, you must create one of the following:

a. [Podman macvlan network](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html) using the following commands:

```bash
  podman network create -d macvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=ens5 rac_pub1_nw
  podman network create -d macvlan --subnet=192.168.17.0/24 --gateway=192.168.17.1 -o parent=ens6 rac_priv1_nw --disable-dns --internal
  podman network create -d macvlan --subnet=192.168.18.0/24 --gateway=192.168.18.1 -o parent=ens7 rac_priv2_nw --disable-dns --internal
```


b. [Podman ipvlan network](https://docs.docker.com/network/drivers/ipvlan/) using the following commands:
```bash
  podman network create -d ipvlan --subnet=10.0.20.0/24 -o parent=ens5 rac_pub1_nw
  podman network create -d ipvlan --subnet=192.168.17.0/24 -o parent=ens6 rac_priv1_nw --disable-dns --internal
  podman network create -d ipvlan --subnet=192.168.18.0/24 -o parent=ens7 rac_priv2_nw --disable-dns --internal
 ```

## Password Management
- Specify the secret volume for resetting the grid, oracle, and database user password during node creation or node addition. The volume can be a shared volume among all the containers. For example:

```bash
mkdir /opt/.secrets/
```
- Generate a password file - Edit the `/opt/.secrets/pwdfile.txt` and seed the password for the grid, oracle, and database users. For this deployment scenario, it will be a common password for the grid, oracle, and database users. Run the command:

```bash
cd /opt/.secrets
openssl genrsa -out key.pem
openssl rsa -in key.pem -out key.pub -pubout
openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
rm -rf /opt/.secrets/pwdfile.txt
```
- Oracle recommends using Podman secrets inside the containers. To create Podman secrets, run the following command:

```bash
podman secret create pwdsecret /opt/.secrets/pwdfile.enc
podman secret create keysecret /opt/.secrets/key.pem

podman secret ls
ID                         NAME        DRIVER      CREATED       UPDATED
7eb7f573905283c808bdabaff  keysecret   file        13 hours ago  13 hours ago
e3ac963fd736d8bc01dcd44dd  pwdsecret   file        13 hours ago  13 hours ago

podman secret inspect <secret_name>
```
Notes:
- In this example we use `pwdsecret` as the common password for SSH setup between containers for the oracle, grid, and Oracle RAC database users. Also, `keysecret` is used to extract secrets inside the Oracle RAC Containers.

## Oracle RAC on Containers Deployment Scenarios
Oracle RAC can be deployed with various scenarios, such as using podman vs podman-compose, NFS vs Block Devices, Oracle RAC Container Image vs Slim Image, with User Defined Response files, and so on. All are covered in detail in the instructions that follow.

### Oracle RAC Containers on Podman
#### [1. Setup Using Oracle RAC Container Image](./rac-container/racimage/README.md)
#### [2. Setup Using Oracle RAC Container Slim Image](./rac-container/racslimimage/README.md)

### Oracle RAC Containers on Podman Compose
#### [1. Setup Using Oracle RAC Container Image](../samples/rac-compose/racimage/README.md)
#### [2. Setup Using Oracle RAC Container Slim Image](../samples/rac-compose/racslimimage/README.md)

## Connecting to an Oracle RAC Database

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.  
Refer to the [README](./CONNECTING.md) for instructions on how to connect to the Oracle RAC Database.

## Deletion of Node from Oracle RAC Cluster
Refer to [README](./DELETION.md) for instructions on how to delete a Node from Existing Oracle RAC Container Cluster.

## Building a Patched Oracle RAC Container Image

If you want to build a patched image based on a base 21.3.0 container image, then refer to the GitHub page [Example of how to create a patched database image](./samples/applypatch/README.md).

## Sample Container Files for Older Releases

This project offers example container files for Oracle Grid Infrastructure and Oracle Real Application Clusters for dev and test:

* Oracle Database 21c Oracle Grid Infrastructure (21.3) for Linux x86-64
* Oracle Database 21c (21.3) for Linux x86-64
* Oracle Database 19c Oracle Grid Infrastructure (19.3) for Linux x86-64
* Oracle Database 19c (19.3) for Linux x86-64
* Oracle Database 18c Oracle Grid Infrastructure (18.3) for Linux x86-64
* Oracle Database 18c (18.3) for Linux x86-64
* Oracle Database 12c Release 2 Oracle Grid Infrastructure (12.2.0.1.0) for Linux x86-64
* Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64

To install older releases of Oracle RAC on Podman or Oracle RAC on Docker, refer to the [README.md](./README_1.md)

## Cleanup
Refer to [README](./CLEANUP.md) for instructions on how to connect to an Oracle RAC Database Container Environment.

## Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 9.3 or later. To see the current Linux support certifications, refer to [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid Infrastructure and Oracle Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under a UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
