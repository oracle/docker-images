# Oracle RAC Data Guard Setup on Containers

Learn about container deployment options for Oracle RAC Data Guard Setup on Containers.

## Overview of Oracle RAC Data Guard Setup on Containers

Oracle Real Application Clusters (Oracle RAC) is an option to the award-winning Oracle Database Enterprise Edition. Oracle RAC is a cluster database with a shared cache architecture that overcomes the limitations of traditional shared-nothing and shared-disk approaches to provide highly scalable and available database solutions for all business applications. Oracle RAC uses Oracle Clusterware as a portable cluster software that allow Oracle Real Application Clusters in Linux Containers.

Oracle Data Guard ensures high availability, data protection, and disaster recovery for enterprise data. Oracle Data Guard provides a comprehensive set of services that create, maintain, manage, and monitor one or more standby databases to enable production Oracle databases to survive disasters and data corruptions. Oracle Data Guard maintains these standby databases as copies of the production database. Then, if the production database becomes unavailable because of a planned or an unplanned outage, Oracle Data Guard can switch any standby database to the production role, minimizing the downtime associated with the outage. Oracle Data Guard can be used with traditional backup, restoration, and cluster techniques to provide a high level of data protection and data availability. Oracle Data Guard transport services are also used by other Oracle features such as Oracle Streams and Oracle GoldenGate for efficient and reliable transmission of redo from a source database to one or more remote destinations.

## Using this Documentation
To create an Oracle RAC Data Guard Setup on Containers, follow these steps:
- [Oracle RAC Data Guard Setup on Containers](#oracle-rac-data-guard-setup-on-containers)
  - [Overview of Oracle RAC Data Guard Setup on Containers](#overview-of-oracle-rac-data-guard-setup-on-containers)
  - [Using this Documentation](#using-this-documentation)
  - [Section 1: Prerequisites for Setting up Oracle RAC Data Guard on Container](#section-1-prerequisites-for-setting-up-oracle-rac-data-guard-on-container)
  - [Section 2: Oracle RAC Data Guard on Podman](#section-2-oracle-rac-data-guard-on-podman)
    - [Section 2.1: Prerequisites for Running Oracle RAC Data Guard on Podman](#section-21-prerequisites-for-running-oracle-rac-data-guard-on-podman)
    - [Section 2.2: Setup RAC Data Guard on Podman using Oracle RAC Database Container Image](#section-22-set-up-oracle-rac-data-guard-on-podman-using-oracle-rac-database-container-image)
      - [Deploying Oracle RAC Primary Container with Block Devices on Podman with Oracle RAC Container Image](#deploying-oracle-rac-primary-container-with-block-devices-and-oracle-rac-container-image)
      - [Deploying Oracle RAC Primary Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image](#deploying-oracle-rac-primary-container-with-oracle-rac-storage-container-on-podman-with-oracle-rac-container-image)
      - [Deploying Oracle RAC Standby Container with Block Devices on Podman with Oracle RAC Container Image](#deploying-oracle-rac-standby-container-with-block-devices-on-podman-with-oracle-rac-container-image)
      - [Deploying Oracle RAC Standby Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image](#deploying-oracle-rac-standby-container-with-oracle-rac-storage-container-on-podman-with-oracle-rac-container-image)
    - [Section 2.3: Setup RAC Data Guard on Podman using Oracle RAC Database Container Slim Image](#section-23-set-up-oracle-rac-containers-on-podman-using-oracle-rac-database-container-slim-image)
      - [Deploying Oracle RAC Primary Container with Block Devices on Podman with Slim Image](#deploying-oracle-rac-primary-container-with-block-devices-on-podman-with-slim-image)
      - [Deploying Oracle RAC Primary Container With Oracle RAC Storage Container on Podman with Slim Image](#deploying-oracle-rac-primary-container-with-oracle-rac-storage-container-on-podman-with-slim-image)
      - [Deploying Oracle RAC Standby Container with Block Devices on Podman with Slim Image](#deploying-oracle-rac-standby-container-with-block-devices-on-podman-with-slim-image)
      - [Deploying Oracle RAC Standby Container With Oracle RAC Storage Container on Podman with Slim Image](#deploying-oracle-rac-standby-container-with-oracle-rac-storage-container-on-podman-with-slim-image)
  - [Attach the network to containers](#attach-the-network-to-containers)
  - [Start the Primary RAC Database Containers](#start-the-primary-rac-database-containers)
  - [Start the Standby RAC Database Containers](#start-the-standby-rac-database-containers)
  - [Validating Oracle RAC Environment](#validating-oracle-rac-environment)
  - [Connecting to an Oracle RAC Database](#connecting-to-an-oracle-rac-database)
  - [Additional Parameter Example to use separate Diskgroups](#additional-parameter-example-to-use-separate-diskgroups)
- [License](#license)
- [Copyright](#copyright)

## Section 1: Prerequisites for Setting up Oracle RAC Data Guard on Container

**IMPORTANT :** You must complete all the steps specified in this section before you proceed to the next section.
* Complete the [Preparation Steps for running Oracle RAC Database in containers](../../../OracleRealApplicationClusters/README.md#preparation-steps-for-running-oracle-rac-database-in-containers)
* Create a NFS Volume if you are planning to use NFS Storage for ASM Devices. See [Configuring NFS for Storage for Oracle RAC on Podman](https://review.us.oracle.com/review2/Review.html#reviewId=467473;scope=document;status=open,fixed;documentId=4229197) for more details. **Note:** You can skip this step if you are planning to use block devices for storage.
* Create Oracle Connection Manager on Container (image and container), if the IPs required for Oracle Grid Infrastructure and Oracle RAC are not available on your network. See [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md) for more details.
* If you have not downloaded or created the Oracle RAC Container image, then complete the tasks in [Getting Oracle RAC Database Container Images](../../../OracleRealApplicationClusters/README.md#getting-oracle-rac-database-container-images)
* Complete the steps in [Network Management](../../../OracleRealApplicationClusters/README.md#network-management).
* Complete the steps in [Password Management](../../../OracleRealApplicationClusters/README.md#password-management).

## Section 2: Oracle RAC Data Guard on Podman

**Note** Oracle RAC is supported for production use on Podman starting with Oracle Database 19c (19.16), Oracle Database 21c (21.7), and onwards. You can deploy Oracle RAC on Podman using the prebuilt images available on Oracle Container Registry.

For Oracle RAC Data Guard on Podman deployment, the supported version is 26ai.

To create an Oracle RAC Data Guard environment on Podman, you must complete each of the following steps in the order in which they are listed.

### Section 2.1: Prerequisites for Running Oracle RAC Data Guard on Podman
Before proceeding further, complete all of the prerequisites required for the Oracle RAC Podman host machine for Oracle RAC Containers. For more details related to preparation of the host machine, see [Preparation Steps for running Oracle RAC Database in containers](../../../OracleRealApplicationClusters/README.md#preparation-steps-for-running-oracle-rac-database-in-containers)
* Validate the host machine for supported operating system version (Oracle Linux 9.3 or later (OL9.3), Unbreakable Enterprise Kernel Release 7 or later (UEKR7), 32 GB or more memory, 32 GB or more allocated to Swap, 4 GB or more allocated to shared memory (shm), and so on.
* Update /etc/sysctl.conf
* Set up node directories for Slim Image
* Set up chronyd service
* Set up tsc clock (if available).
* Install Podman
* Install Podman Compose
* Set up and load SELinux modules
* Create Oracle RAC Podman secrets

### Section 2.2: Set up Oracle RAC Data Guard on Podman using Oracle RAC Database Container Image

This section provides a step-by-step procedure to deploy Oracle RAC on a container with block devices and a storage container using the Oracle RAC Database Container Image. To create the Oracle RAC Database Container Image, see [Building Oracle RAC Database Container Image](../../../OracleRealApplicationClusters/README.md#building-oracle-rac-database-container-image)

To understand the details of required environment variables, see [Environment Variables for Oracle RAC on Containers](../../../OracleRealApplicationClusters/docs/rac-container/racimage/README.md#environment-variables-for-oracle-rac-on-containers)

For details of additional environment parameters that you use with separate diskgroups, see [Additional Parameter Example to use separate Diskgroups](#additional-parameter-example-to-use-separate-diskgroups)

Complete the steps in [Network Management](../../../OracleRealApplicationClusters/README.md#network-management) and set up the network on a container host based on your Oracle RAC environment. If you have already completed the setup, then you can skip this step and continue to the next step.
Complete the steps in [Password Management](../../../OracleRealApplicationClusters/README.md#password-management) and set up the password on a container host based on your Oracle RAC environment. If you have already completed the setup, then you can skip this step and continue to the next step.

#### Deploying Oracle RAC Primary Container with Block Devices and Oracle RAC Container Image

If you are using an NFS volume, then skip to the section [Deploying Oracle RAC Primary on Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image](#deploying-oracle-rac-primary-container-with-oracle-rac-storage-container-on-podman-with-oracle-rac-container-image)

Ensure that the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
  ```

Next, create the Oracle RAC primary containers using the image. You can use the following example to see how to create a container:

1. Create `racnodep1` primary on `podman-host-01` podman host.
  ```bash
  podman create -t -i \
  --hostname racnodep1 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.170 \
  -e CRS_PRIVATE_IP2=192.168.18.170 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e INSTALL_NODE=racnodep1 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1 \
  --device=/dev/oracleoci/oraclevde:/dev/asm-disk2 \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  -e OP_TYPE=setuprac \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep1 \
  localhost/oracle/database-rac:23.26ai
  ```

  2. Create `racnodep2` primary on `podman-host-02` podman host.

  ```bash
  podman create -t -i \
  --hostname racnodep2 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.171 \
  -e CRS_PRIVATE_IP2=192.168.18.171 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e INSTALL_NODE=racnodep1 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1:rwm \
  --device=/dev/oracleoci/oraclevde:/dev/asm-disk2:rwm \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  -e OP_TYPE=setuprac \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep2 \
  localhost/oracle/database-rac:23.26ai
  ```

**Note:** Change environment variables such as `PRIVATE_IP1_LIST`, `PRIVATE_IP1_LIST`, `PUBLIC_HOST_DOMAIN`, `CRS_NODES`, `SCAN_NAME`, `CRS_ASM_DEVICE_LIST`, `CRS_ASM_DISCOVERY_STRING` to the correct values, based on your environment. Also, ensure that you use the correct device names for your environment on each host.
For details about the available environment variables, see [Environment Variables for Oracle RAC on Containers](../../../OracleRealApplicationClusters/docs/rac-container/racimage/README.md#environment-variables-for-oracle-rac-on-containers)

**Note:** You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

#### Deploying Oracle RAC Primary Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image

If you are using block devices, then skip to the section [Deploying Oracle RAC Primary Container with Block Devices on Podman with Oracle RAC Container Image](#deploying-oracle-rac-primary-container-with-block-devices-and-oracle-rac-container-image)

Create the Oracle RAC container using the image.  You can use the following example to see how to create a container:

1. Create `racnodep1` primary on `podman-host-01` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep1 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.170 \
  -e CRS_PRIVATE_IP2=192.168.18.170 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e INSTALL_NODE=racnodep1 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e OP_TYPE=setuprac \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep1 \
  localhost/oracle/database-rac:23.26ai
  ```

2. Create `racnodep2` primary on `podman-host-02` podman host.

 ```bash
podman create -t -i \
  --hostname racnodep2 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.171 \
  -e CRS_PRIVATE_IP2=192.168.18.171 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e INSTALL_NODE=racnodep1 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e OP_TYPE=setuprac \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep2 \
  localhost/oracle/database-rac:23.26ai
  ```

**Note:**
* Change environment variables such as `PRIVATE_IP1_LIST`, `PRIVATE_IP1_LIST`, `PUBLIC_HOST_DOMAIN`, `CRS_NODES`, `SCAN_NAME`, `CRS_ASM_DEVICE_LIST`, `CRS_ASM_DISCOVERY_STRING` to the correct values based on your environment. Also, ensure that you use the correct device names on each host in your environment.

* You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

* You must have created the `racstorage` volume before attempting to create the Oracle RAC Container. For details about the available environment variables, see [Environment Variables for Oracle RAC on Containers](../../../OracleRealApplicationClusters/docs/rac-container/racimage/README.md#environment-variables-for-oracle-rac-on-containers)

#### Deploying Oracle RAC Standby Container with Block Devices on Podman with Oracle RAC Container Image

If you are using an NFS volume, then skip to the section [Deploying Oracle RAC Standby on Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image](#deploying-oracle-rac-standby-container-with-oracle-rac-storage-container-on-podman-with-oracle-rac-container-image)

Ensure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
  ```

Next, create the Oracle RAC Standby container using the image. For details about the available environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/docs/ENVIRONMENTVARIABLES.md). You can use the following example to create a container:


1. Create `racnodep3` standby on `podman-host-03` podman host.

  ```bash
podman create -t -i \
--hostname racnodep3 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
-e DNS_SERVERS="10.0.20.25" \
-e CRS_PRIVATE_IP1=192.168.17.172 \
-e CRS_PRIVATE_IP2=192.168.18.172 \
-e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
-e SCAN_NAME=racnodepc2-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep3 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--device=/dev/oracleoci/oraclevdf:/dev/asm-disk1:rwm \
--device=/dev/oracleoci/oraclevdg:/dev/asm-disk2:rwm \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e DB_UNIQUE_NAME=SORCLCDB \
-e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
-e CRS_ASM_DISKGROUP="+STDBYDATA" \
-e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
-e PRIMARY_DB_NAME=ORCLCDB \
-e OP_TYPE=setupracstandby \
-e DB_BLOCK_CHECKSUM=TYPICAL \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep3 \
localhost/oracle/database-rac:23.26ai
  ```

  2. Create `racnodep4` standby on `podman-host-04` podman host.

  ```bash
podman create -t -i \
--hostname racnodep4 \
--dns-search "example.info" \
--dns 10.0.20.25 \
--shm-size 4G \
--env ContainerType=RAC \
--cpuset-cpus 0-1 \
--memory 16G \
--memory-swap 32G \
--sysctl kernel.shmall=2097152  \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=8589934592  \
--sysctl kernel.shmmni=4096 \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
--cap-add=SYS_NICE \
--cap-add=AUDIT_WRITE \
--cap-add=AUDIT_CONTROL \
--cap-add=NET_RAW \
--secret pwdsecret \
--secret keysecret \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
-e DNS_SERVERS="10.0.20.25" \
-e CRS_PRIVATE_IP1=192.168.17.173 \
-e CRS_PRIVATE_IP2=192.168.18.173 \
-e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
-e SCAN_NAME=racnodepc2-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e INSTALL_NODE=racnodep3 \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e GRID_HOME=/u01/app/26ai/grid \
--device=/dev/oracleoci/oraclevdf:/dev/asm-disk1:rwm \
--device=/dev/oracleoci/oraclevdg:/dev/asm-disk2:rwm \
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
-e DB_UNIQUE_NAME=SORCLCDB \
-e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
-e CRS_ASM_DISKGROUP="+STDBYDATA" \
-e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
-e PRIMARY_DB_NAME=ORCLCDB \
-e OP_TYPE=setupracstandby \
-e DB_BLOCK_CHECKSUM=TYPICAL \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--name racnodep4 \
localhost/oracle/database-rac:23.26ai
```

**Note:** You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

#### Deploying Oracle RAC Standby Container With Oracle RAC Storage Container on Podman with Oracle RAC Container Image

If you are using block devices, then skip to the section [Deploying Oracle RAC Standby Container with Block Devices on Podman with Oracle RAC Container Image](#deploying-oracle-rac-standby-container-with-block-devices-on-podman-with-oracle-rac-container-image)

Create the Oracle RAC container using the image.  You can use the following example to create a container:


1. Create `racnodep3` standby on `podman-host-03` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep3 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.172 \
  -e CRS_PRIVATE_IP2=192.168.18.172 \
  -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
  -e SCAN_NAME=racnodepc2-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e DB_UNIQUE_NAME=SORCLCDB \
  -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
  -e CRS_ASM_DISKGROUP="+STDBYDATA" \
  -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
  -e PRIMARY_DB_NAME=ORCLCDB \
  -e OP_TYPE=setupracstandby \
  -e INSTALL_NODE=racnodep3 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep3 \
  localhost/oracle/database-rac:23.26ai
  ```

2. Create `racnodep4` standby on `podman-host-04` podman host.

 ```bash
podman create -t -i \
  --hostname racnodep4 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.173 \
  -e CRS_PRIVATE_IP2=192.168.18.173 \
  -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
  -e SCAN_NAME=racnodepc2-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e DB_UNIQUE_NAME=SORCLCDB \
  -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
  -e CRS_ASM_DISKGROUP="+STDBYDATA" \
  -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
  -e PRIMARY_DB_NAME=ORCLCDB \
  -e OP_TYPE=setupracstandby \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  -e INSTALL_NODE=racnodep3 \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep4 \
  localhost/oracle/database-rac:23.26ai
  ```

**Note:**
* Change environment variables such as `PRIVATE_IP1_LIST`, `PRIVATE_IP1_LIST`, `PUBLIC_HOST_DOMAIN`, `CRS_NODES`, `SCAN_NAME`, `CRS_ASM_DEVICE_LIST`, `CRS_ASM_DISCOVERY_STRING`, `COMMON_OS_PWD_FILE` and `PWD_KEY` to the correct values based on your environment. Also, ensure you use the correct device names on each host in your environment.

* You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

* You must have created the `racstorage` volume before attempting to create the Oracle RAC Container.
* For details about the available environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/docs/ENVIRONMENTVARIABLES.md)


### Section 2.3: Set up Oracle RAC Containers on Podman using Oracle RAC Database Container Slim Image

This section provides a step-by-step procedure to deploy Oracle RAC on a container with block devices and a storage container using the Oracle RAC Database Container Slim Image.
* To create the Oracle RAC Database Container Slim Image, see [Building Oracle RAC Database Container Slim Image](../../../OracleRealApplicationClusters/README.md#building-oracle-rac-database-container-slim-image)

* To understand the details about environment variables, see [Environment variables for Oracle RAC on Containers](../../../OracleRealApplicationClusters/docs/rac-container/racslimimage/README.md#section-9-environment-variables-for-oracle-rac-on-containers)
* Execute the [Network Management](../../../OracleRealApplicationClusters/README.md#network-management).
* Execute the [Password Management](../../../OracleRealApplicationClusters/README.md#password-management).

#### Deploying Oracle RAC Primary Container with Block Devices on Podman with Slim Image

If you are using an NFS volume, then skip to the section [Deploying Oracle RAC Primary on Container With Oracle RAC Storage Container on Podman with Slim Image](#deploying-oracle-rac-standby-container-with-oracle-rac-storage-container-on-podman-with-slim-image)

Ensure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=10000
  ```
Ensure that the downloaded Oracle RAC software location is staged and available for both the Oracle RAC nodes. In the example that follows, we have staged Oracle RAC software in the location `/scratch/software/26ai/goldimages`
  ```bash
  ls /scratch/software/26ai/goldimages
  LINUX.X64_260000_db_home.zip  LINUX.X64_260000_grid_home.zip
  ```
If SELinux is enabled on the host machine, then also run the following commands:
  ```bash
  semanage fcontext -a -t container_file_t /scratch/software/26ai/goldimages/LINUX.X64_260000_grid_home.zip
  restorecon -v /scratch/software/26ai/goldimages/LINUX.X64_260000_grid_home.zip
  semanage fcontext -a -t container_file_t /scratch/software/26ai/goldimages/LINUX.X64_260000_db_home.zip
  restorecon -v /scratch/software/26ai/goldimages/LINUX.X64_260000_db_home.zip
  ```

Next, create the Oracle RAC primary containers using the image. You can use the following example to see how to create a container.

For the details about environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/ENVIRONMENTVARIABLES.md)

1. Create `racnodep1` primary on `podman-host-01` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep1 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.170 \
  -e CRS_PRIVATE_IP2=192.168.18.170 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  -e OP_TYPE=setuprac \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e DB_NAME=ORCLCDB \
  --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1:rwm \
  --device=/dev/oracleoci/oraclevde:/dev/asm-disk2:rwm \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep1 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

  2. Create `racnodep2` primary on `podman-host-02` podman host.

  ```bash
 podman create -t -i \
  --hostname racnodep2 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.171 \
  -e CRS_PRIVATE_IP2=192.168.18.171 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e SCAN_NAME=racnodepc1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e DEFAULT_GATEWAY="10.0.20.1" \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  -e OP_TYPE=setuprac \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e DB_NAME=ORCLCDB \
  --device=/dev/oracleoci/oraclevdd:/dev/asm-disk1:rwm \
  --device=/dev/oracleoci/oraclevde:/dev/asm-disk2:rwm \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep2 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

**Note:** You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

#### Deploying Oracle RAC Primary Container With Oracle RAC Storage Container on Podman with Slim Image

If you are using block devices, then skip to the section [Deploying Oracle RAC Primary Container with Block Devices on Podman with Slim Image](#deploying-oracle-rac-standby-container-with-block-devices-on-podman-with-slim-image)

Create the Oracle RAC container using the image.  You can use the following example to see how to create a container:

1. Create `racnodep1` primary on `podman-host-01` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep1 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.170 \
  -e CRS_PRIVATE_IP2=192.168.18.170 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e SCAN_NAME=racnodep1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e OP_TYPE=setuprac \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep1 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

2. Create `racnodep2` primary on `podman-host-02` podman host.

 ```bash
podman create -t -i \
  --hostname racnodep2 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --volume racstorage:/oradata \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.171 \
  -e CRS_PRIVATE_IP2=192.168.18.171 \
  -e CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip" \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e SCAN_NAME=racnodep1-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
  -e OP_TYPE=setuprac \
  -e INSTALL_NODE=racnodep1 \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e ASM_ON_NAS=True \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep2 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

**Note:**
* You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

* You must have created the `racstorage` volume before attempting to create the Oracle RAC Container. For details about the available environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/docs/ENVIRONMENTVARIABLES.md)

#### Deploying Oracle RAC Standby Container with Block Devices on Podman with Slim Image

If you are using an NFS volume, then skip to the section [Deploying Oracle RAC Standby on Container With Oracle RAC Storage Container on Podman with Slim Image](#deploying-oracle-rac-standby-container-with-oracle-rac-storage-container-on-podman-with-oracle-rac-container-image)

Ensure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=10000
  ```


Ensure that the downloaded Oracle RAC software location is staged and available for both Oracle RAC nodes. In the example that follows, we have staged Oracle RAC software in the location `/scratch/software/26ai/goldimages`
  ```bash
  ls /scratch/software/26ai/goldimages
  LINUX.X64_260000_db_home.zip  LINUX.X64_260000_grid_home.zip
  ```
If SELinux is enabled on the host machine, then run the following commands:
  ```bash
  semanage fcontext -a -t container_file_t /scratch/software/26ai/goldimages/LINUX.X64_260000_grid_home.zip
  restorecon -v /scratch/software/26ai/goldimages/LINUX.X64_260000_grid_home.zip
  semanage fcontext -a -t container_file_t /scratch/software/26ai/goldimages/LINUX.X64_260000_db_home.zip
  restorecon -v /scratch/software/26ai/goldimages/LINUX.X64_260000_db_home.zip
  ```

Next, create the Oracle RAC Standby container using the image. You can use the following example to see how to create a container.

For the details about environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/docs/ENVIRONMENTVARIABLES.md)

1. Create `racnodep3` standby on `podman-host-03` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep3 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.172 \
  -e CRS_PRIVATE_IP2=192.168.18.172 \
  -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
  -e SCAN_NAME=racnodepc2-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e DB_UNIQUE_NAME=SORCLCDB \
  -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
  -e CRS_ASM_DISKGROUP="+STDBYDATA" \
  -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
  -e PRIMARY_DB_NAME=ORCLCDB \
  -e OP_TYPE=setupracstandby \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e INSTALL_NODE=racnodep3 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e DB_NAME=ORCLCDB \
  --device=/dev/oracleoci/oraclevdf:/dev/asm-disk1:rwm \
  --device=/dev/oracleoci/oraclevdg:/dev/asm-disk2:rwm \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep3 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

  2. Create `racnodep4` standby on `podman-host-04` podman host.

  ```bash
podman create -t -i \
  --hostname racnodep4 \
  --dns-search "example.info" \
  --dns 10.0.20.25 \
  --shm-size 4G \
  --volume /scratch:/scratch \
  --cpuset-cpus 0-1 \
  --memory 16G \
  --memory-swap 32G \
  --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
  --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
  --sysctl kernel.shmall=2097152  \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592  \
  --sysctl kernel.shmmni=4096 \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_NICE \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --cap-add=NET_RAW \
  --secret pwdsecret \
  --secret keysecret \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  -e DNS_SERVERS="10.0.20.25" \
  -e DB_SERVICE=service:soepdb \
  -e CRS_PRIVATE_IP1=192.168.17.173 \
  -e CRS_PRIVATE_IP2=192.168.18.173 \
  -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
  -e SCAN_NAME=racnodepc2-scan \
  -e INIT_SGA_SIZE=3G \
  -e INIT_PGA_SIZE=2G \
  -e GRID_HOME=/u01/app/26ai/grid \
  -e GRID_BASE=/u01/app/grid \
  -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
  -e DB_BASE=/u01/app/oracle \
  -e INVENTORY=/u01/app/oraInventory \
  -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
  -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
  -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
  -e DB_UNIQUE_NAME=SORCLCDB \
  -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
  -e CRS_ASM_DISKGROUP="+STDBYDATA" \
  -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
  -e PRIMARY_DB_NAME=ORCLCDB \
  -e OP_TYPE=setupracstandby \
  -e DB_BLOCK_CHECKSUM=TYPICAL \
  -e INSTALL_NODE=racnodep3 \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e DB_NAME=ORCLCDB \
  --device=/dev/oracleoci/oraclevdf:/dev/asm-disk1:rwm \
  --device=/dev/oracleoci/oraclevdg:/dev/asm-disk2:rwm \
  -e CRS_ASM_DEVICE_LIST=/dev/asm-disk1,/dev/asm-disk2 \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --name racnodep4 \
  localhost/oracle/database-rac:23.26ai-slim
  ```

**Note:** You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

#### Deploying Oracle RAC Standby Container With Oracle RAC Storage Container on Podman with Slim Image

If you are using block devices, then skip to the section [Deploying Oracle RAC Standby Container with Block Devices on Podman with Slim Image](#deploying-oracle-rac-primary-container-with-oracle-rac-storage-container-on-podman-with-slim-image)
Create the Oracle RAC container using the image.  You can use the following example to see how to create a container:


1. Create `racnodep3` standby on `podman-host-03` podman host.

  ```bash
 podman create -t -i \
    --hostname racnodep3 \
    --dns-search "example.info" \
    --dns 10.0.20.25 \
    --shm-size 4G \
    --volume /scratch:/scratch \
    --volume racstorage:/oradata \
    --cpuset-cpus 0-1 \
    --memory 16G \
    --memory-swap 32G \
    --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
    --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
    --sysctl kernel.shmall=2097152  \
    --sysctl "kernel.sem=250 32000 100 128" \
    --sysctl kernel.shmmax=8589934592  \
    --sysctl kernel.shmmni=4096 \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_NICE \
    --cap-add=AUDIT_WRITE \
    --cap-add=AUDIT_CONTROL \
    --cap-add=NET_RAW \
    --secret pwdsecret \
    --secret keysecret \
    --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
    -e DNS_SERVERS="10.0.20.25" \
    -e DB_SERVICE=service:soepdb \
    -e CRS_PRIVATE_IP1=192.168.17.172 \
    -e CRS_PRIVATE_IP2=192.168.18.172 \
    -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
    -e GRID_HOME=/u01/app/26ai/grid \
    -e GRID_BASE=/u01/app/grid \
    -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
    -e DB_BASE=/u01/app/oracle \
    -e INVENTORY=/u01/app/oraInventory \
    -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
    -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
    -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
    -e SCAN_NAME=racnodep2-scan \
    -e INIT_SGA_SIZE=3G \
    -e INIT_PGA_SIZE=2G \
    -e DB_PWD_FILE=pwdsecret \
    -e PWD_KEY=keysecret \
    -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
    -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
    -e DB_UNIQUE_NAME=SORCLCDB \
    -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
    -e CRS_ASM_DISKGROUP="+STDBYDATA" \
    -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
    -e PRIMARY_DB_NAME=ORCLCDB \
    -e OP_TYPE=setupracstandby \
    -e INSTALL_NODE=racnodep3 \
    -e DB_BLOCK_CHECKSUM=TYPICAL \
    -e DB_NAME=ORCLCDB \
    -e ASM_ON_NAS=True \
    --restart=always \
    --ulimit rtprio=99  \
    --systemd=always \
    --name racnodep3 \
   localhost/oracle/database-rac:23.26ai-slim
  ```

2. Create `racnodep4` standby on `podman-host-04` podman host.

 ```bash
 podman create -t -i \
    --hostname racnodep4 \
    --dns-search "example.info" \
    --dns 10.0.20.25 \
    --shm-size 4G \
    --volume /scratch:/scratch \
    --volume racstorage:/oradata \
    --cpuset-cpus 0-1 \
    --memory 16G \
    --memory-swap 32G \
    --sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
    --sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
    --sysctl kernel.shmall=2097152  \
    --sysctl "kernel.sem=250 32000 100 128" \
    --sysctl kernel.shmmax=8589934592  \
    --sysctl kernel.shmmni=4096 \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_NICE \
    --cap-add=AUDIT_WRITE \
    --cap-add=AUDIT_CONTROL \
    --cap-add=NET_RAW \
    --secret pwdsecret \
    --secret keysecret \
    --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
    -e DNS_SERVERS="10.0.20.25" \
    -e DB_SERVICE=service:soepdb \
    -e CRS_PRIVATE_IP1=192.168.17.173 \
    -e CRS_PRIVATE_IP2=192.168.18.173 \
    -e CRS_NODES="pubhost:racnodep3,viphost:racnodep3-vip;pubhost:racnodep4,viphost:racnodep4-vip" \
    -e GRID_HOME=/u01/app/26ai/grid \
    -e GRID_BASE=/u01/app/grid \
    -e DB_HOME=/u01/app/oracle/product/26ai/dbhome_1 \
    -e DB_BASE=/u01/app/oracle \
    -e INVENTORY=/u01/app/oraInventory \
    -e STAGING_SOFTWARE_LOC=/scratch/software/26ai/goldimages \
    -e GRID_SW_ZIP_FILE=LINUX.X64_260000_grid_home.zip \
    -e DB_SW_ZIP_FILE=LINUX.X64_260000_db_home.zip \
    -e SCAN_NAME=racnodep2-scan \
    -e INIT_SGA_SIZE=3G \
    -e INIT_PGA_SIZE=2G \
    -e DB_PWD_FILE=pwdsecret \
    -e PWD_KEY=keysecret \
    -e CRS_ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
    -e CRS_ASM_DISCOVERY_STRING="/oradata/asm_disk*" \
    -e DB_UNIQUE_NAME=SORCLCDB \
    -e PRIMARY_DB_SCAN_NAME=racnodepc1-scan \
    -e CRS_ASM_DISKGROUP="+STDBYDATA" \
    -e PRIMARY_DB_UNIQUE_NAME=ORCLCDB \
    -e PRIMARY_DB_NAME=ORCLCDB \
    -e OP_TYPE=setupracstandby \
    -e INSTALL_NODE=racnodep3 \
    -e DB_BLOCK_CHECKSUM=TYPICAL \
    -e DB_NAME=ORCLCDB \
    -e ASM_ON_NAS=True \
    --restart=always \
    --ulimit rtprio=99  \
    --systemd=always \
    --name racnodep4 \
   localhost/oracle/database-rac:23.26ai-slim
  ```

**Note:** You can use the Linux capabilities feature (`--cap-add=NET_RAW`) only when you are using a Podman Image based on Oracle Linux 9.

* You must have created the `racstorage` volume before attempting to create the Oracle RAC Container.
* For details about the available environment variables, see [Environment Variables Explained for Oracle RAC on Podman](../../../OracleRealApplicationClusters/docs/ENVIRONMENTVARIABLES.md)


## Attach the network to containers

After the containers are created, you must assign the Podman networks you created based on [Network Management](../../../OracleRealApplicationClusters/README.md#network-management) to containers. Run the following commands:


Attach the network to `racnodep1`
```bash
podman network disconnect podman racnodep1
podman network connect rac_pub1_nw --ip 10.0.20.170 racnodep1
podman network connect rac_priv1_nw --ip 192.168.17.170  racnodep1
podman network connect rac_priv2_nw --ip 192.168.18.170  racnodep1
```

Attach the network to `racnodep2`
```bash
podman network disconnect podman racnodep2
podman network connect rac_pub1_nw --ip 10.0.20.171 racnodep2
podman network connect rac_priv1_nw --ip 192.168.17.171 racnodep2
podman network connect rac_priv2_nw --ip 192.168.18.171 racnodep2
```

Attach the network to `racnodep3`
```bash
podman network disconnect podman racnodep3
podman network connect rac_pub1_nw --ip 10.0.20.172 racnodep3
podman network connect rac_priv1_nw --ip 192.168.17.172 racnodep3
podman network connect rac_priv2_nw --ip 192.168.18.172 racnodep3
```

Attach the network to `racnodep4`
```bash
podman network disconnect podman racnodep4
podman network connect rac_pub1_nw --ip 10.0.20.173 racnodep4
podman network connect rac_priv1_nw --ip 192.168.17.173 racnodep4
podman network connect rac_priv2_nw --ip 192.168.18.173 racnodep4
```

## Start the Primary Oracle RAC Database Containers

First start the Primary Oracle RAC Database Container. Run the following commands:

#### Start racnodep1

```bash
podman start racnodep1
```

#### Start racnodep2

```bash
podman start racnodep2
```

To check the logs, run  the following command from another terminal session:

```bash
podman exec racnodep1 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

At the completion of a successful deployment, you should see a database creation success message similar to the following:

```bash
===================================
  ORACLE RAC DATABASE IS READY TO USE
===================================
```

After you see this message for the Primary RAC Database Installation Node Container (`racnodep1` in this example), the Primary Oracle RAC Database Setup is complete.


## Start the Standby RAC Database Containers

Once the Primary RAC Database Setup is ready, start the Standby RAC Database Containers. Please execute following command:

#### Start racnodep3

```bash
podman start racnodep3
```

#### Start racnodep4

```bash
podman start racnodep4
```

To check the logs, use following command from another terminal session:

```bash
podman exec racnodep3 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Once the Oracle RAC Standby Database setup is completed, you should see the DGMGRL configuration enabled in the above logs.

**Note**
* It can take at least 60 minutes or longer to create and setup 2 node RAC Primary and Standby setup.

## Validating Oracle Data Guard Container Environment
You can validate if environment is healthy by running below command-
```bash
podman ps -a

CONTAINER ID  IMAGE                                  COMMAND               CREATED         STATUS                   PORTS       NAMES
2f42e49758d1  localhost/oracle/database-rac:23.26ai                         2 hours ago  Up 37 minutes (healthy)              racnodep1
a27fceea9fe6  localhost/oracle/database-rac:23.26ai                         2 hours ago  Up 37 minutes (healthy)              racnodep2
4b901525bdef  localhost/oracle/database-rac:23.26ai                         About an hour ago  Up 18 minutes (starting)       racnodep3
d4568ecaeb24  localhost/oracle/database-rac:23.26ai                         About an hour ago  Up 18 minutes (starting)       racnodep4
```
Note:
- Look for `(healthy)` next to container names under `STATUS` section.

## Connecting to an Oracle RAC Database

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.
Refer [README](../../docs/CONNECTING.md) for instructions on how to connect to Oracle RAC Database.

## Additional Parameter Example to use separate Diskgroups

In case you want to use different Diskgroups for the CRS Voting Disk, Database Files and Database Recovery Area, you can do that using additional parameters while creating the RAC Containers.

Example: If you want to create:

- Diskgroup CRSDATA with disk "/dev/asm-disk1" to use for CRS Voting Files
- Diskgroup DBDATA with disk "/dev/asm-disk2" to use for Database DATA Files
- Diskgroup RECODATA with disk "/dev/asm-disk3" to use for Database Recovery Area

then, you will need to specify below parameters:

```bash
-e CRS_ASM_DEVICE_LIST=/dev/asm-disk1 \
-e CRS_ASM_DISCOVERY_STRING="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DB_ASM_DEVICE_LIST=/dev/asm-disk2 \
-e DB_CREATE_FILE_DEST="+DBDATA" \
-e DB_DATA_FILE_DEST="+DBDATA" \
-e RECO_ASM_DEVICE_LIST=/dev/asm-disk3 \
-e DB_RECOVERY_FILE_DEST="+RECODATA" \
-e DB_ASMDG_PROPERTIES="name=DBDATA" \
-e RECO_ASMDG_PROPERTIES="name=RECODATA" \
```
Similarly, in order to setup RAC with CMAN Container , you will need to specify below parameters as well.-

- CMAN_HOST Hostname of CMAN Container
- CMAN_PORT Port of CMAN Container Exposed for Connection

Below is example in order to setup RAC with CMAN Container-

```bash
-e CMAN_HOST=racnodepc1-cman \
-e CMAN_PORT=1521 \
```

Refer [Environment Variables Explained for Oracle RAC on Podman](../ENVIRONMENTVARIABLES.md) for more details.

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates.
