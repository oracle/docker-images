# Oracle Real Application Clusters in Linux Containers

Learn about container deployment options for Oracle Real Application Clusters (Oracle RAC) Release 21c (21.3)

## Overview of Running Oracle RAC in Containers

Oracle Real Application Clusters (Oracle RAC) is an option to the award-winning Oracle Database Enterprise Edition. Oracle RAC is a cluster database with a shared cache architecture that overcomes the limitations of traditional shared-nothing and shared-disk approaches to provide highly scalable and available database solutions for all business applications.
Oracle RAC uses Oracle Clusterware as a portable cluster software that allows clustering of independent servers so that they cooperate as a single system and Oracle Automatic Storage Management (Oracle ASM) to provide simplified storage management that is consistent across all servers and storage platforms.
Oracle Clusterware and Oracle ASM are part of the Oracle Grid Infrastructure, which bundles both solutions in an easy to deploy software package.

For more information on Oracle RAC Database 21c refer to the [Oracle Database documentation](http://docs.oracle.com/en/database/).

## Using this Image

To create an Oracle RAC environment, complete these steps in order:

- [Oracle Real Application Clusters in Linux Containers](#oracle-real-application-clusters-in-linux-containers)
  - [Overview of Running Oracle RAC in Containers](#overview-of-running-oracle-rac-in-containers)
  - [Using this Image](#using-this-image)
  - [Section 1 : Prerequisites for running Oracle RAC in containers](#section-1--prerequisites-for-running-oracle-rac-in-containers)
  - [Section 2: Building Oracle RAC Database Container Images](#section-2-building-oracle-rac-database-container-images)
    - [Oracle RAC Container Image for Docker](#oracle-rac-container-image-for-docker)
    - [Oracle RAC Container Image for Podman](#oracle-rac-container-image-for-podman)
  - [Section 3:  Network and Password Management](#section-3--network-and-password-management)
  - [Section 4: Oracle RAC on Docker](#section-4-oracle-rac-on-docker)
    - [Section 4.1 : Prerequisites for Running Oracle RAC on Docker](#section-41--prerequisites-for-running-oracle-rac-on-docker)
    - [Section 4.2: Setup Oracle RAC Container on Docker](#section-42-setup-oracle-rac-container-on-docker)
      - [Deploying Oracle RAC on Container with Block Devices on Docker](#deploying-oracle-rac-on-container-with-block-devices-on-docker)
      - [Deploying Oracle RAC on Container With Oracle RAC Storage Container](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container)
      - [Assign networks to Oracle RAC containers](#assign-networks-to-oracle-rac-containers)
      - [Start the first container](#start-the-first-container)
      - [Connect to the Oracle RAC container](#connect-to-the-oracle-rac-container)
    - [Section 4.3: Adding an Oracle RAC Node using a Docker Container](#section-43-adding-an-oracle-rac-node-using-a-docker-container)
      - [Deploying Oracle RAC Additional Node on Container with Block Devices on Docker](#deploying-oracle-rac-additional-node-on-container-with-block-devices-on-docker)
      - [Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Docker](#deploying-oracle-rac-additional-node-on-container-with-oracle-rac-storage-container-on-docker)
      - [Assign Network to additional Oracle RAC container](#assign-network-to-additional-oracle-rac-container)
      - [Start Oracle RAC racnode2 container](#start-oracle-rac-racnode2-container)
      - [Connect to the Oracle RAC racnode2 container](#connect-to-the-oracle-rac-racnode2-container)
    - [Section 4.4: Setup Oracle RAC Container on Docker with Docker Compose](#section-44-setup-oracle-rac-container-on-docker-with-docker-compose)
  - [Section 5: Oracle RAC on Podman](#section-5-oracle-rac-on-podman)
    - [Section 5.1 : Prerequisites for Running Oracle RAC on Podman](#section-51--prerequisites-for-running-oracle-rac-on-podman)
    - [Section 5.2: Setup RAC Containers on Podman](#section-52-setup-rac-containers-on-podman)
      - [Deploying Oracle RAC Containers with Block Devices on Podman](#deploying-oracle-rac-containers-with-block-devices-on-podman)
      - [Deploying Oracle RAC on Container With Oracle RAC Storage Container on Podman](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container-on-podman)
      - [Assign networks to Oracle RAC containers Created Using Podman](#assign-networks-to-oracle-rac-containers-created-using-podman)
      - [Start the first container Created Using Podman](#start-the-first-container-created-using-podman)
      - [Connect to the Oracle RAC container Created Using Podman](#connect-to-the-oracle-rac-container-created-using-podman)
    - [Section 5.3: Adding a Oracle RAC Node using a container on Podman](#section-53-adding-a-oracle-rac-node-using-a-container-on-podman)
      - [Deploying Oracle RAC Additional Node on Container with Block Devices on Podman](#deploying-oracle-rac-additional-node-on-container-with-block-devices-on-podman)
      - [Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Podman](#deploying-oracle-rac-additional-node-on-container-with-oracle-rac-storage-container-on-podman)
      - [Assign Network to additional Oracle RAC container Created Using Podman](#assign-network-to-additional-oracle-rac-container-created-using-podman)
      - [Start Oracle RAC container](#start-oracle-rac-container)
    - [Section 5.4: Setup Oracle RAC Container on Podman with Podman Compose](#section-54-setup-oracle-rac-container-on-podman-with-podman-compose)
  - [Section 6: Connecting to an Oracle RAC Database](#section-6-connecting-to-an-oracle-rac-database)
  - [Section 7: Environment Variables for the First Node](#section-7-environment-variables-for-the-first-node)
  - [Section 8: Environment Variables for the Second and Subsequent Nodes](#section-8-environment-variables-for-the-second-and-subsequent-nodes)
  - [Section 9: Building a Patched Oracle RAC Container Image](#section-9-building-a-patched-oracle-rac-container-image)
  - [Section 10 : Sample Container Files for Older Releases](#section-10--sample-container-files-for-older-releases)
    - [Docker](#docker)
    - [Podman](#podman)
  - [Section 11 : Support](#section-11--support)
    - [Docker Support](#docker-support)
    - [Podman Support](#podman-support)
  - [Section 12 : License](#section-12--license)
  - [Section 13 : Copyright](#section-13--copyright)

## Section 1 : Prerequisites for running Oracle RAC in containers

Before you proceed to section two, you must complete each of the steps listed in this section.

To review the resource requirements for Oracle RAC, see Oracle Database 21c Release documentation [Oracle Grid Infrastructure Installation and Upgrade Guide](https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/index.html)

Complete each of the following prerequisites:

1. Ensure that each container that you will deploy as part of your cluster meets the minimum hardware requirements for Oracle RAC and Oracle Grid Infrastructure software.
2. Ensure all data files, control files, redo log files, and the server parameter file (`SPFILE`) used by the Oracle RAC database reside on shared storage that is accessible by all the Oracle RAC database instances. An Oracle RAC database is a shared-everything database, so each Oracle RAC Node must have the same access.
3. Configure the following addresses manually in your DNS.

   - Public IP address for each container
   - Private IP address for each container
   - Virtual IP address for each container
   - Three single client access name (SCAN) addresses for the cluster.
4. If you are planning to set up RAC on Docker, refer Docker Host machine details in [Section 4.1](#section-41--prerequisites-for-running-oracle-rac-on-docker)
5. If you are planning to set up RAC on Podman, refer Podman Host machine details in [Section 5.1](#section-51--prerequisites-for-running-oracle-rac-on-podman)
6. Block storage: If you are planning to use block devices for shared storage, then allocate block devices for OCR, voting and database files.
7. NFS storage: If you are planning to use NFS storage for OCR, Voting Disk and Database files, then configure NFS storage and export at least one NFS mount. You can also use `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRACStorageServer` container for shared file system on NFS.
8. Set`/etc/sysctl.conf`parameters: For Oracle RAC, you must set following parameters at host level in `/etc/sysctl.conf`:
  ```INI
  fs.aio-max-nr = 1048576
  fs.file-max = 6815744
  net.core.rmem_max = 4194304
  net.core.rmem_default = 262144
  net.core.wmem_max = 1048576
  net.core.wmem_default = 262144
  net.core.rmem_default = 262144
  ```
9. List and reload parameters:  After the `/etc/sysctl.conf` file is modified, run the following commands:
  ```bash
  sysctl -a
  sysctl -p
  ```
10. To resolve VIPs and SCAN IPs, we are using a DNS container in this guide. Before proceeding to the next step, create a [DNS server container](../OracleDNSServer/README.md).
**Note**  If you have a pre-configured DNS server in your environment, then you can replace `-e DNS_SERVERS=172.16.1.25`, `--dns=172.16.1.25`, `-e DOMAIN=example.com`  and `--dns-search=example.com` parameters in **Section 2: Building Oracle RAC Database Podman Install Images** with the `DOMAIN_NAME` and `DNS_SERVER` based on your environment.
11. If you are running RAC on Podman, make sure that you have installed the `podman-docker` rpm package so that podman commands can be run using `docker` utility.
12. The Oracle RAC `Dockerfile` does not contain any Oracle software binaries. Download the following software from the [Oracle Technology Network](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) and stage them under `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRealApplicationCluster/dockerfiles/<VERSION>` folder.

    - Oracle Database 21c Grid Infrastructure (21.3) for Linux x86-64
    - Oracle Database 21c (21.3) for Linux x86-64

    - If you are deploying Oracle RAC on Podman then execute following, otherwise skip to next section.
      - Because Oracle RAC on Podman is supported on Release 21c (21.7) or later, you must download the grid release update (RU) from [support.oracle.com](https://support.oracle.com/portal/).

      - In this Example we download the following latest one-off patches for release 21.13 from [support.oracle.com](https://support.oracle.com/portal/)
        - `36031790`
        - `36041222`
13. Ensure you have git configured in your host machine, [refer this page](https://docs.oracle.com/en/learn/ol-git-start/index.html) for instructions. Clone this git repo by running below command -  
```bash
git clone git@github.com:oracle/docker-images.git
```
<!-- markdownlint-disable-next-line MD036 -->
**Notes**

- If you are planning to use a `DNSServer` container for SCAN IPs, VIPs resolution, then configure the DNSServer. For development and testing purposes only, use the Oracle `DNSServer` image to deploy a container providing DNS resolutions. Please check [OracleDNSServer](../OracleDNSServer/README.md) for details.
- `OracleRACStorageServer` docker image can be used only for development and testing purpose. Please check [OracleRACStorageServer](../OracleRACStorageServer/README.md) for details.
- When you want to deploy RAC on Docker or Podman on Single host, create bridge networks for containers.
- When you want to deploy RAC on Docker or Podman on Multiple host, create macvlan networks for containers.
- To run Oracle RAC using Podman on multiple hosts, refer [Podman macvlan network](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html).
  To run Oracle RAC using Oracle Container Runtime for Docker on multiple hosts, refer [Docker macvlan network](https://docs.docker.com/network/macvlan/).
- If the Docker or Podman bridge network is not available outside your host, you can use the Oracle Connection Manager [CMAN image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleConnectionManager) to access the Oracle RAC Database from outside the host.

## Section 2: Building Oracle RAC Database Container Images

**IMPORTANT :** This section assumes that you have gone through all the prerequisites in Section 1 and completed all the steps, based on your environment. Do not uncompress the binaries and patches.

To assist in building the images, you can use the [`buildContainerImage.sh`](https://github.com/oracle/docker-images/blob/master/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles/buildContainerImage.sh) script. See the following for instructions and usage.

### Oracle RAC Container Image for Docker

If you are planing to deploy Oracle RAC container image on Podman, skip to the section [Oracle RAC Container Image for Podman](#oracle-rac-container-image-for-podman).

```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles
./buildContainerImage.sh -v <Software Version> -o '--build-arg  BASE_OL_IMAGE=oraclelinux:7 --build-arg SLIMMING=true|false'

#  for example ./buildContainerImage.sh -v 21.3.0 -o '--build-arg  BASE_OL_IMAGE=oraclelinux:7 --build-arg SLIMMING=false'
```

### Oracle RAC Container Image for Podman

If you are planing to deploy Oracle RAC container image on Docker, skip to the section [Oracle RAC Container Image for Docker](#oracle-rac-container-image-for-docker).

```bash
cd <git-cloned-path>/docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles
./buildContainerImage.sh -v <Software Version> -o '--build-arg  BASE_OL_IMAGE=oraclelinux:8 --build-arg SLIMMING=true|false'

#  for example ./buildContainerImage.sh -v 21.3.0 -o '--build-arg  BASE_OL_IMAGE=oraclelinux:8 --build-arg SLIMMING=false'
```

- After the `21.3.0` Oracle RAC container image is built, start building a patched image with the download 21.7 RU and one-offs. To build the patch image, refer [Example of how to create a patched database image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleRealApplicationClusters/samples/applypatch).

<!-- markdownlint-disable-next-line MD036 -->
**Notes**

- The resulting images will contain the Oracle Grid Infrastructure binaries and Oracle RAC Database binaries.
- If you are behind a proxy wall, then you must set the `https_proxy` environment variable based on your environment before building the image.
  
## Section 3:  Network and Password Management

1. Before you start the installation, you must plan your private and public network. You can create a network bridge on every container host so containers running within that host can communicate with each other.  
   - For example, create `rac_pub1_nw` for the public network (`172.16.1.0/24`) and `rac_priv1_nw` (`192.168.17.0/24`) for a private network. You can use any network subnet for testing.
   - In this document we reference the public network on `172.16.1.0/24` and the private network on `192.168.17.0/24`.

    ```bash
      docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
      docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
    ```

   - To run Oracle RAC using Oracle Container Runtime for Docker on multiple hosts, you will need to create a [Docker macvlan network](https://docs.docker.com/network/macvlan/) using the following commands:

      ```bash
      docker network create -d macvlan --subnet=172.16.1.0/24 --gateway=172.16.1.1 -o parent=eth0 rac_pub1_nw
      docker network create -d macvlan --subnet=192.168.17.0/24 --gateway=192.168.17.1 -o parent=eth1 rac_priv1_nw
      ```

2. Specify the secret volume for resetting the grid, oracle, and database user password during node creation or node addition. The volume can be a shared volume among all the containers. For example:

    ```bash
    mkdir /opt/.secrets/
    openssl rand -out /opt/.secrets/pwd.key -hex 64 
    ```

   - Edit the `/opt/.secrets/common_os_pwdfile` and seed the password for the  grid, oracle and database users. For this deployment scenario, it will be a common password for the grid, oracle, and database users. Run the command:

      ```bash
      openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
      rm -f /opt/.secrets/common_os_pwdfile
      ```

3. Create `rac_host_file` on both Podman and Docker hosts:

   ```bash
   mkdir /opt/containers/
   touch /opt/containers/rac_host_file
   ```
<!-- markdownlint-disable-next-line MD036 -->
**Notes**

- To run Oracle RAC using Podman on multiple hosts, refer [Podman macvlan network](https://docs.podman.io/en/latest/markdown/podman-network-create.1.html).
To run Oracle RAC using Oracle Container Runtime for Docker on multiple hosts, refer [Docker macvlan network](https://docs.docker.com/network/macvlan/).
- If the Docker or Podman bridge network is not available outside your host, you can use the Oracle Connection Manager [CMAN image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleConnectionManager) to access the Oracle RAC Database from outside the host.
- If you want to specify a different password for each of the user accounts, then create three different files, encrypt them under `/opt/.secrets`,  and pass the file name to the container using the environment variable. Environment variables can be ORACLE_PWD_FILE for the oracle user, GRID_PWD_FILE for the grid user, and DB_PWD_FILE for the database password.
- If you want to use a common password for the oracle, grid, and database users, then you can assign a password file name to COMMON_OS_PWD_FILE environment variable.
  
## Section 4: Oracle RAC on Docker

If you are deploying Oracle RAC On Podman, skip to the [Section 5: Oracle RAC on Podman](#section-5-oracle-rac-on-podman).

**Note** Oracle RAC is supported for production use on Docker starting with Oracle Database 21c (21.3). On earlier releases, Oracle RAC on Docker is supported for development and and test environments. To deploy Oracle RAC on Docker, use the pre-built images available on the Oracle Container Registry. Execute the following steps in a given order to deploy RAC on Docker:

To create an Oracle RAC environment on Docker, complete each of these steps in order.

### Section 4.1 : Prerequisites for Running Oracle RAC on Docker

To run Oracle RAC on Docker, you must install and configure [Oracle Container Runtime for Docker](https://docs.oracle.com/cd/E52668_01/E87205/html/index.html) on Oracle Linux 7. You must have sufficient space on docker file system (`/var/lib/docker`), configured with the Docker OverlayFS storage driver option `overlay2`.

**IMPORTANT:** Completing prerequisite steps is a requirement for successful configuration.

Complete each prerequisite step in order, customized for your environment.

1. Verify that you have enough memory and CPU resources available for all containers. For this `README.md`, we used the following configuration:

   - 2 Docker hosts
   - CPU Cores: 1 Socket with 4 cores, with 2 threads for each core Intel® Xeon® Platinum 8167M CPU at 2.00 GHz
   - RAM: 60GB
   - Swap memory: 32 GB
   - Oracle Linux 7.9 or later with the Unbreakable Enterprise Kernel 6: 5.4.17-2102.200.13.el7uek.x86_64.

2. Oracle RAC must run certain processes in real-time mode. To run processes inside a container in real-time mode, you must make changes to the Docker configuration files. For details, see the [`dockerd` documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#examples). Edit the Docker Daemon based on Docker version:

   - Check the Docker version. In the following output, the Oracle `docker-engine` version is 19.03.

    ```bash
    rpm -qa | grep docker
    docker-cli-19.03.11.ol-9.el7.x86_64
    docker-engine-19.03.11.ol-9.el7.x86_64
    ```

   - If Oracle `docker-engine` version is greater than or equal to 19.03: Edit `/usr/lib/systemd/system/docker.service` and add additional parameters in the `[Service]` section for the `dockerd` daemon:

    ```bash
    ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --cpu-rt-runtime=950000
    ```

   - If Oracle docker-engine version is less than 19.03: Edit `/etc/sysconfig/docker` and add following

    ```bash
    OPTIONS='--selinux-enabled --cpu-rt-runtime=950000'
    ```

3. After you have modified the `dockerd` daemon, reload the daemon with the changes you have made:

    ```bash
    systemctl daemon-reload
    systemctl stop docker
    systemctl start docker
    ```

### Section 4.2: Setup Oracle RAC Container on Docker

This section provides step by step procedure to deploy Oracle RAC on container with block devices and storage container. To understand the details of environment variable, refer For the details of environment variables [Section 7: Environment Variables for the First Node](#section-7-environment-variables-for-the-first-node)

Refer the [Section 3:  Network and Password Management](#section-3--network-and-password-management) and setup the network on a container host based on your Oracle RAC environment. If you have already done the setup, ignore and proceed further.

#### Deploying Oracle RAC on Container with Block Devices on Docker

If you are using an NFS volume, skip to the section [Deploying Oracle RAC on Container With Oracle RAC Storage Container](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container).

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=10000
  ```

Repeat for each shared block device. In the preceding example, `/dev/xvde` is a shared Xen virtual block device.

Now create the Oracle RAC container using the image. You can use the following example to create a container:

  ```bash
docker create -t -i \
  --hostname racnoded1 \
  --volume /boot:/boot:ro \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --device=/dev/oracleoci/oraclevdd:/dev/asm_disk1  \
  --device=/dev/oracleoci/oraclevde:/dev/asm_disk2 \
  --privileged=false  \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e DNS_SERVERS="172.16.1.25" \
  -e NODE_VIP=172.16.1.130 \
  -e VIP_HOSTNAME=racnoded1-vip  \
  -e PRIV_IP=192.168.17.100 \
  -e PRIV_HOSTNAME=racnoded1-priv \
  -e PUBLIC_IP=172.16.1.100 \
  -e PUBLIC_HOSTNAME=racnoded1  \
  -e SCAN_NAME=racnodedc1-scan \
  -e OP_TYPE=INSTALL \
  -e DOMAIN=example.com \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ASM_DISCOVERY_DIR=/dev \
  -e CMAN_HOSTNAME=racnodedc1-cman \
  -e CMAN_IP=172.16.1.164 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  -e RESET_FAILED_SYSTEMD="true" \
  --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 --ulimit rtprio=99  \
  --name racnoded1 \
  oracle/database-rac:21.3.0
```

**Note:** Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.

#### Deploying Oracle RAC on Container With Oracle RAC Storage Container

If you are using block devices, skip to the section [Deploying Oracle RAC on Container with Block Devices on Docker](#deploying-oracle-rac-on-container-with-block-devices-on-docker)

Now create the Oracle RAC container using the image. You can use the following example to create a container:

  ```bash
  docker create -t -i \
    --hostname racnoded1 \
    --volume /boot:/boot:ro \
    --volume /dev/shm \
    --tmpfs /dev/shm:rw,exec,size=4G \
    --volume /opt/containers/rac_host_file:/etc/hosts  \
    --volume /opt/.secrets:/run/secrets:ro \
    --dns=172.16.1.25 \
    --dns-search=example.com \
    --privileged=false \
    --volume racstorage:/oradata \
    --cap-add=SYS_NICE \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    -e DNS_SERVERS="172.16.1.25" \
    -e NODE_VIP=172.16.1.130  \
    -e VIP_HOSTNAME=racnoded1-vip  \
    -e PRIV_IP=192.168.17.100  \
    -e PRIV_HOSTNAME=racnoded1-priv \
    -e PUBLIC_IP=172.16.1.100 \
    -e PUBLIC_HOSTNAME=racnoded1  \
    -e SCAN_NAME=racnodedc1-scan \
    -e OP_TYPE=INSTALL \
    -e DOMAIN=example.com \
    -e ASM_DISCOVERY_DIR=/oradata \
    -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
    -e CMAN_HOSTNAME=racnodedc1-cman \
    -e CMAN_IP=172.16.1.164 \
    -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
    -e PWD_KEY=pwd.key \
    -e RESET_FAILED_SYSTEMD="true" \
    --restart=always \
    --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --cpu-rt-runtime=95000 \
    --ulimit rtprio=99  \
    --name racnoded1 \
    oracle/database-rac:21.3.0
  ```

**Notes:**

- Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.
- You must have created the `racstorage` volume before the creation of the Oracle RAC Container. For details, please refer [OracleRACStorageServer](../OracleRACStorageServer/README.md).
- For details about the available environment variables, refer the [Section 7](#section-7-environment-variables-for-the-first-node).

#### Assign networks to Oracle RAC containers

You need to assign the Docker networks created in section 1 to containers. Execute the following commands:

  ```bash
  
docker network disconnect bridge racnoded1
docker network connect rac_pub1_nw --ip 172.16.1.100 racnoded1
docker network connect rac_priv1_nw --ip 192.168.17.100  racnoded1
  ```

#### Start the first container

To start the first container, run the following command:

  ```bash
  docker start racnoded1
  ```

It can take at least 40 minutes or longer to create the first node of the cluster. To check the logs, use the following command from another terminal session:

  ```bash
  docker logs -f racnoded1
  ```

You should see the database creation success message at the end:

  ```bash
  ####################################
  ORACLE RAC DATABASE IS READY TO USE!
  ####################################
  ```

#### Connect to the Oracle RAC container

To connect to the container execute the following command:

```bash
docker exec -i -t racnoded1 /bin/bash
```

If the install fails for any reason, log in to the container using the preceding command and check `/tmp/orod.log`.

- You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs.
- If the failure occurred during the database creation then check the database logs.

### Section 4.3: Adding an Oracle RAC Node using a Docker Container

Before proceeding to the next step, ensure Oracle Grid Infrastructure is running and the Oracle RAC Database is open as per instructions in [Section 4.2: Setup Oracle RAC on Docker](#section-42-setup-oracle-rac-container-on-docker). Otherwise, the node addition process will fail.

Refer the [Section 3:  Network and Password Management](#section-3--network-and-password-management) and setup the network on a container host based on your Oracle RAC environment. If you have already done the setup, ignore and proceed further.

To understand the details of environment variable, refer For the details of environment variables [Section 8](#section-8-environment-variables-for-the-second-and-subsequent-nodes)

Reset the password on the existing Oracle RAC node for SSH setup between an existing node in the cluster and the new node. Password must be the same on all the nodes for the `grid` and `oracle` users. Execute the following command on an existing node of the cluster.

```bash
docker exec -i -t -u root racnode1 /bin/bash
sh  /opt/scripts/startup/resetOSPassword.sh --help
sh /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --secret_volume /run/secrets --pwd_key_file pwd.key
```

**Note:** If you do not have a common secret volume among Oracle RAC containers, populate the password file with the same password that you have used on the new node, encrypt the file, and execute `resetOSPassword.sh` on the existing node of the cluster.

#### Deploying Oracle RAC Additional Node on Container with Block Devices on Docker

If you are using an NFS volume, skip to the section [Deploying Oracle RAC on Container with Oracle RAC Storage Container on Docker](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container).

To create additional nodes, use the following command:

```bash
docker create -t -i \
  --hostname racnoded2 \
  --volume /boot:/boot:ro \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --device=/dev/oracleoci/oraclevdd:/dev/asm_disk1  \
  --device=/dev/oracleoci/oraclevde:/dev/asm_disk2 \
  --privileged=false  \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnoded1 \
  -e NODE_VIP=172.16.1.131  \
  -e VIP_HOSTNAME=racnoded2-vip  \
  -e PRIV_IP=192.168.17.101  \
  -e PRIV_HOSTNAME=racnoded2-priv \
  -e PUBLIC_IP=172.16.1.101  \
  -e PUBLIC_HOSTNAME=racnoded2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnodedc1-scan \
  -e ASM_DISCOVERY_DIR=/dev \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  -e RESET_FAILED_SYSTEMD="true" \
  --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 --ulimit rtprio=99  \
  --name racnoded2 \
  oracle/database-rac:21.3.0
```

For details of all environment variables and parameters, refer to [Section 7](#section-7-environment-variables-for-the-first-node).

#### Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Docker

If you are using physical block devices for shared storage, skip to [Deploying Oracle RAC on Container with Block Devices on Docker](#deploying-oracle-rac-on-container-with-block-devices-on-docker).

Use the existing `racstorage:/oradata` volume when creating the additional container using the image.

For example:

```bash
docker create -t -i \
  --hostname racnoded2 \
  --volume /boot:/boot:ro \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --volume racstorage:/oradata \
  --privileged=false  \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnoded1 \
  -e NODE_VIP=172.16.1.131  \
  -e VIP_HOSTNAME=racnoded2-vip  \
  -e PRIV_IP=192.168.17.101  \
  -e PRIV_HOSTNAME=racnoded2-priv \
  -e PUBLIC_IP=172.16.1.101  \
  -e PUBLIC_HOSTNAME=racnoded2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnodedc1-scan \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  -e RESET_FAILED_SYSTEMD="true" \
  --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 --ulimit rtprio=99  \
  --name racnoded2 \
  oracle/database-rac:21.3.0
```

**Notes:**

- You must have created **racstorage** volume before the creation of the Oracle RAC container.
- You can change env variables such as IPs and ORACLE_PWD based on your env. For details about the env variables, refer the section 8.

#### Assign Network to additional Oracle RAC container

Connect the private and public networks you created earlier to the container:

```bash
docker network disconnect bridge racnoded2
docker network connect rac_pub1_nw --ip 172.16.1.101 racnoded2
docker network connect rac_priv1_nw --ip 192.168.17.101 racnoded2
```

#### Start Oracle RAC racnode2 container

Start the container

```bash
docker start racnoded2
```

To check the database logs, tail the logs using the following command:

```bash
docker logs -f racnoded2
```

You should see the database creation success message at the end.

```bash
#################################################################
Oracle Database ORCLCDB is up and running on racnoded2    
#################################################################
Running User Script for  oracle user
Setting Remote Listener
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

#### Connect to the Oracle RAC racnode2 container

To connect to the container execute the following command:

```bash
docker exec -i -t racnoded2 /bin/bash
```

If the node addition fails, log in to the container using the preceding command and review `/tmp/orod.log`. You can also review the Grid Infrastructure logs i.e. `$GRID_BASE/diag/crs` and check for failure logs. If the node creation has failed during the database creation process, then check DB logs.

## Section 4.4: Setup Oracle RAC Container on Docker with Docker Compose

Oracle RAC database can also be deployed with Docker Compose. An example of how to install Oracle RAC Database on Single Host via Bridge Network is explained in this [README.md](./samples/racdockercompose/README.md)

Same section covers various below scenarios as well with docker compose-
1. Deploying Oracle RAC on Container with Block Devices on Docker with Docker Compose
2. Deploying Oracle RAC on Container With Oracle RAC Storage Container with Docker Compose
3. Deploying Oracle RAC Additional Node on Container with Block Devices on Docker with Docker Compose
4. Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Docker with Docker Compose

***Note:*** Docker and Docker Compose is not supported with OL8. You need OL7.9 with UEK R5 or R6.

## Section 5: Oracle RAC on Podman

If you are deploying Oracle RAC On Docker, skip to [Section 4: Oracle RAC on Docker](#section-4-oracle-rac-on-docker)

**Note** Oracle RAC is supported for production use on Podman starting with Oracle Database 19c (19.16), and Oracle Database 21c (21.7). You can deploy Oracle RAC on Podman using the pre-built images available on Oracle Container Registry. Execute the following steps in a given order to deploy RAC on Podman:

To create an Oracle RAC environment on Podman, complete each of these steps in order.

### Section 5.1 : Prerequisites for Running Oracle RAC on Podman

You must install and configure [Podman release 4.0.2](https://docs.oracle.com/en/operating-systems/oracle-linux/podman/podman-InstallingPodmanandRelatedUtilities.html#podman-install) or later on Oracle Linux 8.5 or later to run Oracle RAC on Podman.

**Notes**:

- You need to remove `"--cpu-rt-runtime=95000 \"` from container creation commands mentioned below in this document in following sections to create the containers if you are running Oracle 8 with UEKR7:
  - [Section 5.2: Setup RAC Containers on Podman](#section-52-setup-rac-containers-on-podman).
  - [Section 5.3: Adding a Oracle RAC Node using a container on Podman](#section-53-adding-a-oracle-rac-node-using-a-container-on-podman).
  
- You can check the details on [Oracle Linux and Unbreakable Enterprise Kernel (UEK) Releases](https://blogs.oracle.com/scoter/post/oracle-linux-and-unbreakable-enterprise-kernel-uek-releases)

- You do not need to execute step 2 in this section to create and enable `podman-rac-cgroup.service` when we are running Oracle Linux 8 with Unbreakable Enterprise Kernel R7.

**IMPORTANT:** Completing prerequisite steps is a requirement for successful configuration.

Complete each prerequisite step in order, customized for your environment.

1. Verify that you have enough memory and CPU resources available for all containers. In this `README.md` for Podman, we used the following configuration:

   - 2 Podman hosts
   - CPU Cores: 1 Socket with 4 cores, with 2 threads for each core Intel® Xeon® Platinum 8167M CPU at 2.00 GHz
   - RAM: 60 GB
   - Swap memory: 32 GB
   - Oracle Linux 8.5 (Linux-x86-64) with the Unbreakable Enterprise Kernel 6: `5.4.17-2136.300.7.el8uek.x86_64`.
  
2. Oracle RAC must run certain processes in real-time mode. To run processes inside a container in real-time mode, populate the real-time CPU budgeting on machine restarts. Create a oneshot systemd service as follows:

   - Create a file `/etc/systemd/system/podman-rac-cgroup.service`
   - Append the following lines:

      ```INI
      [Unit]
      Description=Populate Cgroups with real time chunk on machine restart
      After=multi-user.target
      [Service]
      Type=oneshot
      ExecStart=/bin/bash -c “/bin/echo 950000 > /sys/fs/cgroup/cpu,cpuacct/machine.slice/cpu.rt_runtime_us && /bin/systemctl restart podman-restart.service”
      StandardOutput=journal
      CPUAccounting=yes
      Slice=machine.slice
      [Install]
      WantedBy=multi-user.target
      ```

   - After creating the file `/etc/systemd/system/podman-rac-cgroup.service` with the lines appended in the preceding step, reload and restart the Podman daemon using the following steps:

       ```bash
       systemctl daemon-reload
       systemctl enable podman-rac-cgroup.service
       systemctl enable podman-restart.service 
       systemctl start podman-rac-cgroup.service
       ```

3. If SELINUX is enabled on the Podman host, then you must create an SELinux policy for Oracle RAC on Podman.

You can check SELinux Status in your host machine by running the `sestatus` command.

For details about how to create SELinux policy for Oracle RAC on Podman, see "How to Configure Podman for SELinux Mode" in the publication [Oracle Real Application Clusters Installation Guide for Podman Oracle Linux x86-64](https://docs.oracle.com/en/database/oracle/oracle-database/21/racpd/target-configuration-oracle-rac-podman.html#GUID-59138DF8-3781-4033-A38F-E0466884D008).

### Section 5.2: Setup RAC Containers on Podman

This section provides step by step procedure to deploy Oracle RAC on container with block devices and storage container. To understand the details of environment variable, refer For the details of environment variables [Section 7: Environment Variables for the First Node](#section-7-environment-variables-for-the-first-node)

Refer the [Section 3:  Network and Password Management](#section-3--network-and-password-management) and setup the network on a container host based on your Oracle RAC environment. If you have already done the setup, ignore and proceed further.

#### Deploying Oracle RAC Containers with Block Devices on Podman

If you are using an NFS volume, skip to the section [Deploying Oracle RAC on Container With Oracle RAC Storage Container on Podman](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container-on-podman).

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  dd if=/dev/zero of=/dev/xvde  bs=8k count=10000
  ```

Repeat for each shared block device. In the preceding example, `/dev/xvde` is a shared Xen virtual block device.

Now create the Oracle RAC container using the image. For the details of environment variables, refer to section 7. You can use the following example to create a container:

  ```bash
  podman create -t -i \
    --hostname racnodep1 \
    --volume /boot:/boot:ro \
    --tmpfs /dev/shm:rw,exec,size=4G \
    --volume /opt/containers/rac_host_file:/etc/hosts  \
    --volume /opt/.secrets:/run/secrets:ro \
    --dns=172.16.1.25 \
    --dns-search=example.com \
    --device=/dev/oracleoci/oraclevdd:/dev/asm_disk1  \
    --device=/dev/oracleoci/oraclevde:/dev/asm_disk2 \
    --privileged=false  \
    --cap-add=SYS_NICE \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    --cap-add=AUDIT_WRITE \
    --cap-add=AUDIT_CONTROL \
    --memory 16G \
    --memory-swap 32G \
    --sysctl kernel.shmall=2097152 \
    --sysctl "kernel.sem=250 32000 100 128" \
    --sysctl kernel.shmmax=8589934592 \
    --sysctl kernel.shmmni=4096 \
    -e DNS_SERVERS="172.16.1.25" \
    -e NODE_VIP=172.16.1.200 \
    -e VIP_HOSTNAME=racnodep1-vip  \
    -e PRIV_IP=192.168.17.170 \
    -e PRIV_HOSTNAME=racnodep1-priv \
    -e PUBLIC_IP=172.16.1.170 \
    -e PUBLIC_HOSTNAME=racnodep1  \
    -e SCAN_NAME=racnodepc1-scan \
    -e OP_TYPE=INSTALL \
    -e DOMAIN=example.com \
    -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
    -e ASM_DISCOVERY_DIR=/dev \
    -e CMAN_HOSTNAME=racnodepc1-cman \
    -e CMAN_IP=172.16.1.166 \
    -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
    -e PWD_KEY=pwd.key \
    -e ORACLE_SID=ORCLCDB \
   -e RESET_FAILED_SYSTEMD="true" \
   -e DEFAULT_GATEWAY="172.16.1.1" \
   -e TMPDIR=/var/tmp \
    --restart=always \
    --systemd=always \
    --cpu-rt-runtime=95000 \
    --ulimit rtprio=99  \
    --name racnodep1 \
    localhost/oracle/database-rac:21.3.0-21.13.0
  ```

**Note:** Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.

#### Deploying Oracle RAC on Container With Oracle RAC Storage Container on Podman

If you are using block devices, skip to the section [Deploying RAC Containers with Block Devices on Podman](#deploying-oracle-rac-containers-with-block-devices-on-podman).
Now create the Oracle RAC container using the image.  You can use the following example to create a container:

  ```bash
  podman create -t -i \
    --hostname racnodep1 \
    --volume /boot:/boot:ro \
    --tmpfs /dev/shm:rw,exec,size=4G \
    --volume /opt/containers/rac_host_file:/etc/hosts  \
    --volume /opt/.secrets:/run/secrets:ro \
    --dns=172.16.1.25 \
    --dns-search=example.com \
    --privileged=false \
    --volume racstorage:/oradata \
    --cap-add=SYS_NICE \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    --cap-add=AUDIT_WRITE \
    --cap-add=AUDIT_CONTROL \
    --memory 16G \
    --memory-swap 32G \
    --sysctl kernel.shmall=2097152 \
    --sysctl "kernel.sem=250 32000 100 128" \
    --sysctl kernel.shmmax=8589934592 \
    --sysctl kernel.shmmni=4096 \
    -e DNS_SERVERS="172.16.1.25" \
    -e NODE_VIP=172.16.1.200 \
    -e VIP_HOSTNAME=racnodep1-vip  \
    -e PRIV_IP=192.168.17.170 \
    -e PRIV_HOSTNAME=racnodep1-priv \
    -e PUBLIC_IP=172.16.1.170 \
    -e PUBLIC_HOSTNAME=racnodep1  \
    -e SCAN_NAME=racnodepc1-scan \
    -e OP_TYPE=INSTALL \
    -e DOMAIN=example.com \
    -e ASM_DISCOVERY_DIR=/oradata \
    -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
    -e CMAN_HOSTNAME=racnodepc1-cman \
    -e CMAN_IP=172.16.1.166 \
    -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
    -e PWD_KEY=pwd.key \
    -e ORACLE_SID=ORCLCDB \
    -e RESET_FAILED_SYSTEMD="true" \
    -e DEFAULT_GATEWAY="172.16.1.1" \
    -e TMPDIR=/var/tmp \
    --restart=always \
    --systemd=always \
    --cpu-rt-runtime=95000 \
    --ulimit rtprio=99  \
    --name racnodep1 \
    localhost/oracle/database-rac:21.3.0-21.13.0
  ```

**Notes:**

- Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.
- You must have created the `racstorage` volume before the creation of the Oracle RAC Container. For details about the available environment variables, refer the [Section 7](#section-7-environment-variables-for-the-first-node).

#### Assign networks to Oracle RAC containers Created Using Podman

You need to assign the Podman networks created in section 1 to containers. Execute the following commands:

  ```bash
  podman network disconnect podman racnodep1
  podman network connect rac_pub1_nw --ip 172.16.1.170 racnodep1
  podman network connect rac_priv1_nw --ip 192.168.17.170  racnodep1
  ```

#### Start the first container Created Using Podman

To start the first container, run the following command:

  ```bash
  podman start racnodep1
  ```

It can take at least 40 minutes or longer to create the first node of the cluster. To check the database logs, tail the logs using the following command:

```bash
podman exec racnodep1 /bin/bash -c "tail -f /tmp/orod.log"
```

You should see the database creation success message at the end.

```bash
01-31-2024 12:31:20 UTC :  : #################################################################
01-31-2024 12:31:20 UTC :  :  Oracle Database ORCLCDB is up and running on racnodep1    
01-31-2024 12:31:20 UTC :  : #################################################################
01-31-2024 12:31:20 UTC :  : Running User Script
01-31-2024 12:31:20 UTC :  : Setting Remote Listener
01-31-2024 12:31:27 UTC :  : 172.16.1.166
01-31-2024 12:31:27 UTC :  : Executing script to set the remote listener
01-31-2024 12:31:28 UTC :  : ####################################
01-31-2024 12:31:28 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
01-31-2024 12:31:28 UTC :  : ####################################
```

#### Connect to the Oracle RAC container Created Using Podman

To connect to the container execute the following command:

```bash
podman exec -i -t racnodep1 /bin/bash
```

If the install fails for any reason, log in to the container using the preceding command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

### Section 5.3: Adding a Oracle RAC Node using a container on Podman

Before proceeding to the next step, ensure Oracle Grid Infrastructure is running and the Oracle RAC Database is open as per instructions in [Section 5.2: Setup RAC Containers on Podman](#section-52-setup-rac-containers-on-podman). Otherwise, the node addition process will fail.

Refer the [Section 3:  Network and Password Management](#section-3--network-and-password-management) and setup the network on a container host based on your Oracle RAC environment. If you have already done the setup, ignore and proceed further.

To understand the details of environment variable, refer For the details of environment variables [Section 8](#section-8-environment-variables-for-the-second-and-subsequent-nodes).

Reset the password on the existing Oracle RAC node for SSH setup between an existing node in the cluster and the new node. Password must be the same on all the nodes for the `grid` and `oracle` users. Execute the following command on an existing node of the cluster.

```bash
podman exec -i -t -u root racnode1 /bin/bash
sh  /opt/scripts/startup/resetOSPassword.sh --help
sh /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --secret_volume /run/secrets --pwd_key_file pwd.key
```

**Note:** If you do not have a common secret volume among Oracle RAC containers, populate the password file with the same password that you have used on the new node, encrypt the file, and execute `resetOSPassword.sh` on the existing node of the cluster.

#### Deploying Oracle RAC Additional Node on Container with Block Devices on Podman

If you are using an NFS volume, skip to the section [Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Podman](#deploying-oracle-rac-additional-node-on-container-with-oracle-rac-storage-container-on-podman).

To create additional nodes, use the following command:

```bash
podman create -t -i \
  --hostname racnodep2 \
  --tmpfs /dev/shm:rw,exec,size=4G  \
  --volume /boot:/boot:ro \
  --dns-search=example.com  \
  --volume /opt/containers/rac_host_file:/etc/hosts \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --device=/dev/oracleoci/oraclevdd:/dev/asm_disk1 \
  --device=/dev/oracleoci/oraclevde:/dev/asm_disk2 \
  --privileged=false \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=AUDIT_CONTROL \
  --cap-add=AUDIT_WRITE \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152 \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592 \
  --sysctl kernel.shmmni=4096 \
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnodep1 \
  -e NODE_VIP=172.16.1.201  \
  -e VIP_HOSTNAME=racnodep2-vip  \
  -e PRIV_IP=192.168.17.171  \
  -e PRIV_HOSTNAME=racnodep2-priv \
  -e PUBLIC_IP=172.16.1.171  \
  -e PUBLIC_HOSTNAME=racnodep2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnodepc1-scan \
  -e ASM_DISCOVERY_DIR=/dev \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  -e RESET_FAILED_SYSTEMD="true" \
  -e DEFAULT_GATEWAY="172.16.1.1" \
  -e TMPDIR=/var/tmp \
  --systemd=always \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnodep2 \
  localhost/oracle/database-rac:21.3.0-21.13.0
```

For details of all environment variables and parameters, refer to [Section 8](#section-8-environment-variables-for-the-second-and-subsequent-nodes).

#### Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Podman

If you are using physical block devices for shared storage, skip to [Deploying Oracle RAC Additional Node on Container with Block Devices on Podman](#deploying-oracle-rac-additional-node-on-container-with-block-devices-on-podman).

Use the existing `racstorage:/oradata` volume when creating the additional container using the image.

For example:

```bash
podman create -t -i \
  --hostname racnodep2 \
  --tmpfs /dev/shm:rw,exec,size=4G  \
  --volume /boot:/boot:ro \
  --dns-search=example.com  \
  --volume /opt/containers/rac_host_file:/etc/hosts \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --privileged=false \
  --volume racstorage:/oradata \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  --cap-add=AUDIT_WRITE \
  --cap-add=AUDIT_CONTROL \
  --memory 16G \
  --memory-swap 32G \
  --sysctl kernel.shmall=2097152 \
  --sysctl "kernel.sem=250 32000 100 128" \
  --sysctl kernel.shmmax=8589934592 \
  --sysctl kernel.shmmni=4096 \
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnodep1 \
  -e NODE_VIP=172.16.1.201  \
  -e VIP_HOSTNAME=racnodep2-vip  \
  -e PRIV_IP=192.168.17.171  \
  -e PRIV_HOSTNAME=racnodep2-priv \
  -e PUBLIC_IP=172.16.1.171  \
  -e PUBLIC_HOSTNAME=racnodep2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnodepc1-scan \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  -e RESET_FAILED_SYSTEMD="true" \
  -e DEFAULT_GATEWAY="172.16.1.1" \
  -e TMPDIR=/var/tmp \
  --systemd=always \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnodep2 \
  localhost/oracle/database-rac:21.3.0-21.13.0
```

**Notes:**

- You must have created **racstorage** volume before the creation of the Oracle RAC container.
- You can change env variables such as IPs and ORACLE_PWD based on your env. For details about the env variables, refer the [Section 8](#section-8-environment-variables-for-the-second-and-subsequent-nodes).

#### Assign Network to additional Oracle RAC container Created Using Podman

Connect the private and public networks you created earlier to the container:

```bash
podman network disconnect podman racnodep2
podman network connect rac_pub1_nw --ip 172.16.1.171 racnodep2
podman network connect rac_priv1_nw --ip 192.168.17.171 racnodep2
```

#### Start Oracle RAC container

Start the container

```bash
podman start racnodep2
```

To check the database logs, tail the logs using the following command:

```bash
podman exec racnodep2 /bin/bash -c "tail -f /tmp/orod.log"
```

You should see the database creation success message at the end.

```bash
02-01-2024 09:36:14 UTC :  : #################################################################
02-01-2024 09:36:14 UTC :  :  Oracle Database ORCLCDB is up and running on racnodep2    
02-01-2024 09:36:14 UTC :  : #################################################################
02-01-2024 09:36:14 UTC :  : Running User Script
02-01-2024 09:36:14 UTC :  : Setting Remote Listener
02-01-2024 09:36:14 UTC :  : ####################################
02-01-2024 09:36:14 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
02-01-2024 09:36:14 UTC :  : ####################################
```
## Section 5.4: Setup Oracle RAC Container on Podman with Podman Compose

Oracle RAC database can also be deployed with podman Compose. An example of how to install Oracle RAC Database on Single Host via Bridge Network is explained in this [README.md](./samples/racpodmancompose/README.md)

Same section covers various below scenarios as well with podman compose-
1. Deploying Oracle RAC on Container with Block Devices on Podman with Podman Compose
2. Deploying Oracle RAC on Container with NFS Devices on Podman with Podman Compose
3. Deploying Oracle RAC Additional Node on Container with Block Devices on Podman with Podman Compose
4. Deploying Oracle RAC Additional Node on Container with Oracle RAC Storage Container on Podman with Podman Compose

***Note:*** Podman and Podman Compose is not supported with OL7. You need minimum OL8.8 with UEK R7.

## Section 6: Connecting to an Oracle RAC Database

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.

If you are using a connection manager and exposed the port 1521 on the host, then connect from an external client using the following connection string, where `<container_host>` is the host container, and `<ORACLE_SID>` is the database system identifier:

```bash
system/<password>@//<container_host>:1521/<ORACLE_SID>
```

If you are using the bridge created using MACVLAN driver, and you have configured DNS appropriately, then you can connect using the public Single Client Access (SCAN) listener directly from any external client. To connect with the SCAN, use the following connection string, where `<scan_name>` is the SCAN name for the database, and `<ORACLE_SID>` is the database system identifier:

```bash
system/<password>@//<scan_name>:1521/<ORACLE_SID>
```

## Section 7: Environment Variables for the First Node

This section provides information about the environment variables that can be used when creating the first node of a cluster.

```bash
OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE####
NODE_VIP=####Specify the Node VIP###
VIP_HOSTNAME=###Specify the VIP hostname###
PRIV_IP=###Specify the Private IP###
PRIV_HOSTNAME=###Specify the Private Hostname###
PUBLIC_IP=###Specify the public IP###
PUBLIC_HOSTNAME=###Specify the public hostname###
SCAN_NAME=###Specify the scan name###
ASM_DEVICE_LIST=###Specify the ASM Disk lists.
SCAN_IP=###Specify this if you do not have DNS server###
DOMAIN=###Default value set to example.com###
PASSWORD=###OS password will be generated by openssl###
CLUSTER_NAME=###Default value set to racnode-c####
ORACLE_SID=###Default value set to ORCLCDB###
ORACLE_PDB=###Default value set to ORCLPDB###
ORACLE_PWD=###Default value set to generated by openssl random password###
ORACLE_CHARACTERSET=###Default value set AL32UTF8###
DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers will be running on multiple hosts.####
CMAN_HOSTNAME=###Connection Manager Host Name###
CMAN_IP=###Connection manager Host IP###
ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######
COMMON_OS_PWD_FILE=###Pass the file name to setup grid and oracle user password. If you specify ORACLE_PWD_FILE, GRID_PWD_FILE, and DB_PWD_FILE then you do not need to specify this env variable###
ORACLE_PWD_FILE=###Pass the file name to set the password for oracle user.###
GRID_PWD_FILE=###Pass the file name to set the password for grid user.###
DB_PWD_FILE=###Pass the file name to set the password for DB user i.e. sys.###
REMOVE_OS_PWD_FILES=###Set this env variable to true to remove pwd key file and password file after resetting password.###
CONTAINER_DB_FLAG=###Default value is set to true to create container database. Set this to false if you do not want to create container database.###
```

## Section 8: Environment Variables for the Second and Subsequent Nodes

This section provides the details about the environment variables that can be used for all additional nodes added to an existing cluster.

```bash
OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE###
EXISTING_CLS_NODES=###Specify the Existing Node of the cluster which you want to join. If you have 2 nodes in the cluster and you are trying to add the third node then specify existing 2 nodes of the clusters and separate them by comma.####
NODE_VIP=###Specify the Node VIP###
VIP_HOSTNAME=###Specify the VIP hostname###
PRIV_IP=###Specify the Private IP###
PRIV_HOSTNAME=###Specify the Private Hostname###
PUBLIC_IP=###Specify the public IP###
PUBLIC_HOSTNAME=###Specify the public hostname###
SCAN_NAME=###Specify the scan name###
SCAN_IP=###Specify this if you do not have DNS server###
ASM_DEVICE_LIST=###Specify the ASM Disk lists.
DOMAIN=###Default value set to example.com###
ORACLE_SID=###Default value set to ORCLCDB###
DEFAULT_GATEWAY=###Default gateway. You need this env variable if containers will be running on multiple hosts.####
CMAN_HOSTNAME=###Connection Manager Host Name###
CMAN_IP=###Connection manager Host IP###
ASM_DISCOVERY_DIR=####ASM disk location inside the container. By default it is /dev######
COMMON_OS_PWD_FILE=###You need to pass the file name to setup grid and oracle user password. If you specify ORACLE_PWD_FILE, GRID_PWD_FILE, and DB_PWD_FILE then you do not need to specify this env variable###
ORACLE_PWD_FILE=###You need to pass the file name to set the password for oracle user.###
GRID_PWD_FILE=###You need to pass the file name to set the password for grid user.###
DB_PWD_FILE=###You need to pass the file name to set the password for DB user i.e. sys.###
REMOVE_OS_PWD_FILES=###You need to set this to true to remove pwd key file and password file after resetting password.###
```

## Section 9: Building a Patched Oracle RAC Container Image

If you want to build a patched image based on a base 21.3.0 container image, then refer to the GitHub page [Example of how to create a patched database image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleRealApplicationClusters/samples/applypatch).

## Section 10 : Sample Container Files for Older Releases

### Docker

This project offers sample container files for Oracle Grid Infrastructure and Oracle Real Application Clusters for dev and test:
  
- Oracle Database 19c Oracle Grid Infrastructure (19.3) for Linux x86-64
- Oracle Database 19c (19.3) for Linux x86-64

- Oracle Database 18c Oracle Grid Infrastructure (18.3) for Linux x86-64

- Oracle Database 18c (18.3) for Linux x86-64
  
- Oracle Database 12c Release 2 Oracle Grid Infrastructure (12.2.0.1.0) for Linux x86-64
  
- Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64
  
 **Notes:**

- Note that the Oracle RAC on Docker Container releases are supported only for test and development environments, but not for production environments.
  
- If you are planning to build and deploy Oracle RAC 18.3.0, you need to download Oracle 18.3.0 Grid Infrastructure and Oracle Database 18.3.0 Database.
  
  - You also need to download Patch# p28322130_183000OCWRU_Linux-x86-64.zip from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html).
  
  - Stage it under dockerfiles/18.3.0 folder.

- If you are planning to build and deploy Oracle RAC 12.2.0.1, you need to download Oracle 12.2.0.1 Grid Infrastructure and Oracle Database 12.2.0.1 Database.
  
  - You also need to download Patch# p27383741_122010_Linux-x86-64.zip from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html).
  
  - Stage it under dockerfiles/12.2.0.1 folder.

### Podman

This project offers sample container files for Oracle Grid Infrastructure and Oracle Real Application Clusters for dev and test:

- Oracle Database 19c Oracle Grid Infrastructure (19.3) for Linux x86-64
- Oracle Database 19c (19.3) for Linux x86-64

**Notes:**
- Because Oracle RAC on Podman is supported on 19c from 19.16 or later, you must download the grid release update (RU) from [support.oracle.com](https://support.oracle.com/portal/).

- For RAC on Podman for v19.22, download following one-offs from [support.oracle.com](https://support.oracle.com/portal/)
  - `35943157`
  - `35940989`

- Before starting the next step, you must edit `docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles/19.3.0/Dockerfile`, change `oraclelinux:7-slim` to `oraclelinux:8`, and save the file.

- You must add `CV_ASSUME_DISTID=OEL8` inside the `Dockerfile` as an env variable.

- Once the `19.3.0` Oracle RAC on Podman image is built, start building patched image with the download 19.16 RU and one-offs. To build the patch the image, refer [Example of how to create a patched database image](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleRealApplicationClusters/samples/applypatch).

## Section 11 : Support

### Docker Support

At the time of this release, Oracle RAC on Docker is supported only on Oracle Linux 7. To see current details, refer the [Real Application Clusters Installation Guide for Docker Containers Oracle Linux x86-64](https://docs.oracle.com/en/database/oracle/oracle-database/21/racdk/oracle-rac-on-docker.html).

### Podman Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 8.5 later. To see current Linux support certifications, refer [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## Section 12 : License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Section 13 : Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates.
