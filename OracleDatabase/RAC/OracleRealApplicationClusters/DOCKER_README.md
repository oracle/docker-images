# Running an Oracle Real Application Clusters Database using Docker Engine

This project offers sample container files for Oracle Grid Infrastructure(GI) and Oracle Real Application Clusters(RAC):

* Oracle Database 21c Oracle Grid Infrastructure (21.3) for Linux x86-64
* Oracle Database 21c (21.3) for Linux x86-64

IMPORTANT: To access the Oracle RAC DB on your network either use the Docker MACVLAN driver or use Oracle Connection Manager. To Run Oracle RAC containers on Multi-Host, you must use the Docker MACVLAN driver and your network must be reachable on all the nodes for Oracle RAC containers.

## Using this Image

To create an Oracle RAC environment, execute the steps in the following sections:

- [Running an Oracle Real Application Clusters Database using Docker Engine](#running-an-oracle-real-application-clusters-database-using-docker-engine)
  - [Using this Image](#using-this-image)
  - [Section 1: Prerequisites for running Oracle RAC with Docker Engine](#section-1-prerequisites-for-running-oracle-rac-with-docker-engine)
    - [Notes](#notes)
  - [Section 2: Building Oracle RAC Database Container Images](#section-2-building-oracle-rac-database-container-images)
    - [Notes](#notes-1)
  - [Section 3: Creating the Oracle GI and RAC Container](#section-3-creating-the-oracle-gi-and-rac-container)
    - [Password management](#password-management)
    - [Notes](#notes-2)
    - [Deploying Oracle RAC on Container With Block Devices](#deploying-oracle-rac-on-container-with-block-devices)
    - [Deploying Oracle RAC on Container  With Oralce RAC Storage Container](#deploying-oracle-rac-on-container--with-oralce-rac-storage-container)
    - [Assign networks to Oracle RAC containers](#assign-networks-to-oracle-rac-containers)
    - [Start the first container](#start-the-first-container)
    - [Connect to the Oracle RAC container](#connect-to-the-oracle-rac-container)
  - [Section 4: Adding a Oracle RAC Node using a container](#section-4-adding-a-oracle-rac-node-using-a-container)
    - [Password management](#password-management-1)
    - [Notes](#notes-3)
    - [Deploying with Block Devices](#deploying-with-block-devices)
    - [Deploying Oracle RAC on Container with Oracle RAC Storage Container](#deploying-oracle-rac-on-container-with-oracle-rac-storage-container)
    - [Assign Network to additional Oracle RAC container](#assign-network-to-additional-oracle-rac-container)
    - [Start Oracle RAC container](#start-oracle-rac-container)
    - [Connect to the Oracle RAC container](#connect-to-the-oracle-rac-container-1)
  - [Section 5: Connecting to Oracle RAC Database](#section-5-connecting-to-oracle-rac-database)
  - [Section 6: Environment Variables for the first node](#section-6-environment-variables-for-the-first-node)
  - [Section 7: Environment Variables for the second and subsequent nodes](#section-7-environment-variables-for-the-second-and-subsequent-nodes)
  - [Sample Container Files for Older Releases](#sample-container-files-for-older-releases)
  - [Section 9 : Support](#section-9--support)
  - [Section 10 : License](#section-10--license)
  - [Section 11 : Copyright](#section-11--copyright)

## Section 1: Prerequisites for running Oracle RAC with Docker Engine

**IMPORTANT:** You must make the changes specified in this section (customized for your environment) before you proceed to the next section.

You must install and configure [Oracle Container Runtime for Docker](https://docs.oracle.com/cd/E52668_01/E87205/html/index.html) on Oracle Linux 7 to run Oracle RAC on Docker. Each container that you will deploy as part of your cluster must satisfy the minimum hardware requirements of the Oracle RAC and GI software. An Oracle Oracle RAC database is a shared everything database.

All data files, control files, redo log files, and the server parameter file (`SPFILE`) used by the Oracle RAC database must reside on shared storage that is accessible by all the Oracle Oracle RAC database instances.

You must provide block devices shared across the hosts.  If you don't have shared block storage, you can use an NFS volume.

Refer Oracle Database 21c Release documentation [Oracle Grid Infrastructure Installation and Upgrade Guide](https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/index.html) and allocate the following resource as per the Oracle documentation.

1. You must configure the following addresses manually in your DNS.
   * Public IP address for each container
   * Private IP address for each container
   * Virtual IP address for each container
   * Three single client access name (SCAN) addresses for the cluster.
2. If you are planning to use block devices for shared storage, allocate block devices for Oracle Cluster Registry (OCR)/voting and database files.
3. If you are planning to use NFS storage for OCR, voting and database files, configure NFS storage and export at least one NFS mount. For testing purposes only, use the Oracle `rac-storage-server` image to deploy a docker container providing NFS-based sharable storage. This applies also to domain name server (DNS) server.
4. If you are planning to use DNSServer container for SCAN, IPs, VIPs resolution, configure DNSServer. For testing purposes only, use the Oracle DNSServer image to deploy a Docker container providing DNS resolutions.
5. Verify you have enough memory and CPU resources available for all containers. Each container for Oracle RAC requires 8GB memory and 16GB swap.
6. For Oracle RAC, you must set the following parameters at the host level in `/etc/sysctl.conf`:

  ```INI
  fs.file-max = 6815744
  net.core.rmem_max = 4194304
  net.core.rmem_default = 262144
  net.core.wmem_max = 1048576
  net.core.wmem_default = 262144
  ```

* Execute the following once the file is modified.

   ```bash
   # sysctl -a
   # sysctl -p
   ```

7. You need to plan your private and public network for containers before you start the installation. You can create a network bridge on every host so containers running within that host can communicate with each other.  For example, create `rac_pub1_nw` for the public network (`172.16.1.0/24`) and `rac_priv1_nw` (`192.168.17.0/24`) for a private network. You can use any network subnet for testing however in this document we reference the public network on `172.16.1.0/24` and the private network on `192.168.17.0/24`.

  ```bash
  # docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
  # docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
  ```

* To run Oracle RAC using Oracle Container Runtime for Docker on multiple hosts, you will need to create a [Docker `macvlan` network](https://docs.docker.com/network/macvlan/) using the following commands:

    ```bash
    # docker network create -d macvlan --subnet=172.16.1.0/24 --gateway=172.16.1.1 -o parent=eth0 rac_pub1_nw
    # docker network create -d macvlan --subnet=192.168.17.0/24 --gateway=192.168.17.1 -o parent=eth1 rac_priv1_nw
    ```

8. Oracle RAC needs to run certain processes in real-time mode. To run processes inside a container in real-time mode, you need to make changes to the Docker configuration files. Execute following steps to run processes in real-time mode as shoen below:

* Edit `/usr/lib/systemd/system/docker.service` on all hosts that run Oracle Container Runtime for Docker.
* Append the following parameter setting for the line starting with entry `ExecStart=` under the `[Service]` section:

    ```bash
    --cpu-rt-runtime=950000
    ```

* After appending the parameter, the `ExecStart` value should appear similar to the following example:

    ```bash
    ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --cpu-rt-runtime=950000
    ```

* Save the `/usr/lib/systemd/system/docker.service` file.
* Run the following commands to reload the daemon and container with the changes

    ```bash
    systemctl daemon-reload
    systemctl restart docker
    ```

   For details, refer to the [`dockerd` documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#examples) and  [Oracle Database Enterprise Edition Installation Guide for Docker Containers on Oracle Linux](https://docs.oracle.com/en/database/oracle/oracle-database/21/clustering.html)  

9. Verify you have enough memory and CPU resources available for container. For details, refer to [Oracle 21c Grid Infrastructure Installation and Upgrade Guide](https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/index.html)

10. To resolve VIPs and SCAN IPs, we are using a dummy DNS container in this guide. Before proceeding to the next step, create a [DNS server container](../OracleDNSServer/README.md). If you have a pre-configured DNS server in your environment, you can replace `-e DNS_SERVERS=172.16.1.25`, `--dns=172.16.1.25`, `-e DOMAIN=example.com`  and `--dns-search=example.com` parameters in **Section 2: Building Oracle RAC Database Docker Install Images** with the `DOMAIN_NAME' and 'DNS_SERVER' based on your environment.

11. The Oracle RAC `Dockerfile` does not contain any Oracle software binaries. Download the following software from the [Oracle Technology Network](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html) and stage them under `<GITHUM_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRACStorageServer/dockerfiles` folder.

    Oracle Database 21c Grid Infrastructure (21.3) for Linux x86-64
    Oracle Database 21c (21.3) for Linux x86-64

### Notes

* If the Docker bridge network is not available outside your host, you can use the Oracle Connection Manager (CMAN) image to access the Oracle RAC Database from outside the host.
* To understand the Oracle RAC on Docker setup in detail, you can refer [Best Practices for Deploying Oracle RAC on Docker](https://www.oracle.com/technetwork/database/options/clustering/rac-ondocker-bp-wp-5458685.pdf) white paper published on OTN.

## Section 2: Building Oracle RAC Database Container Images

**IMPORTANT :** This section assumes that you have gone through all the pre-requisites in Section 1 and executed all the steps based on your environment. Do not uncompress the binaries and patches.

To assist in building the images, you can use the [`buildContainerImage.sh`](https://github.com/oracle/docker-images/blob/master/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles/buildContainerImage.sh) script. See the following for instructions and usage.

  ```bash
  ./buildContainerImage.sh -v <Software Version>
  #  e.g., ./buildContainerImage.sh -v 21.3.0
  ```

For detailed usage of the command, execute the following command:

  ```bash
  #  ./buildContainerImage.sh -h
  ```

### Notes

* The resulting images will contain the Oracle Grid Infrastructure Binaries and Oracle RAC Database binaries.
* If you are behind a proxy, you will need to set the `https_proxy` environment variable based on your environment before building the image.

## Section 3: Creating the Oracle GI and RAC Container

All containers will share a host file for name resolution.  The shared hostfile must be available to all containers. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

  ```bash
  # mkdir /opt/containers
  # touch /opt/containers/rac_host_file
  ```

**Note:** Do not modify `/opt/containers/rac_host_file` from the host running Oracle Container Runtime for Docker. It will be managed from within the containers.

If you are using the Oracle Connection Manager for accessing the Oracle RAC Database from outside the host, you need to add the following variable in the container creation command.

  ```bash
  -e CMAN_HOSTNAME=(CMAN_HOSTNAME) -e CMAN_IP=(CMAN_IP)
  ```

**Note:** You need to replace `CMAN_HOSTNAME` and `CMAN_IP` with the correct values based on your environment settings.

### Password management

Specify the secret volume for resetting grid/oracle and database password during node creation or node addition. It can be shared volume among all the containers

  ```bash
  mkdir /opt/.secrets/
  openssl rand -hex 64 -out /opt/.secrets/pwd.key
  ```

Edit the `/opt/.secrets/common_os_pwdfile` and seed the password for grid/oracle and database. It will be a common password for grid/oracle and database users. Execute the following command:

  ```bash
  openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
  rm -f /opt/.secrets/common_os_pwdfile
  chmod 400 /opt/.secrets/common_os_pwdfile.enc
  chmod 400 /opt/.secrets/pwd.key
  ```

### Notes

* If you want to specify different passwords for all the accounts, create 3 different files and encrypt them under `/opt/.secrets` and pass the file name to the container using the `env` parameter. Environment variables are `ORACLE_PWD_FILE` for `oracle` user, `GRID_PWD_FILE` for `grid` user, and `DB_PWD_FILE` for the database password.
* if you want a common password for the `oracle`, `grid`, and `database` users, assign a password file name to `COMMON_OS_PWD_FILE` environment variable.
* Once the RAC environment setup is completed, you must change the `oracle`, `grid` and database passwords to meet any corporate or other requirements.

### Deploying Oracle RAC on Container With Block Devices

If you are using an NFS volume, skip to the section "Deploying Oracle RAC on Container with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

  ```bash
  # dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
  ```

Repeat for each shared block device. In the preceding example, `/dev/xvde` is a shared Xen virtual block device.

Now create the Oracle RAC container using the image. For the details of environment variables, refer to section 5. You can use the following example to create a container:

  ```bash
  # docker create -t -i \
    --hostname racnode1 \
    --volume /boot:/boot:ro \
    --volume /dev/shm \
    --tmpfs /dev/shm:rw,exec,size=4G \
    --volume /opt/containers/rac_host_file:/etc/hosts  \
    --volume /opt/.secrets:/run/secrets:ro \
    --dns=172.16.1.25 \
    --dns-search=example.com \
    --device=/dev/xvde:/dev/asm_disk1  \
    --device=/dev/xvdf:/dev/asm_disk2 \
    --privileged=false  \
    --cap-add=SYS_NICE \
    --cap-add=SYS_RESOURCE \
    --cap-add=NET_ADMIN \
    -e DNS_SERVERS="172.16.1.25" \
    -e NODE_VIP=172.16.1.160 \
    -e VIP_HOSTNAME=racnode1-vip  \
    -e PRIV_IP=192.168.17.150 \
    -e PRIV_HOSTNAME=racnode1-priv \
    -e PUBLIC_IP=172.16.1.150 \
    -e PUBLIC_HOSTNAME=racnode1  \
    -e SCAN_NAME=racnode-scan \
    -e OP_TYPE=INSTALL \
    -e DOMAIN=example.com \
    -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
    -e ASM_DISCOVERY_DIR=/dev \
    -e CMAN_HOSTNAME=racnode-cman1 \
    -e CMAN_IP=172.16.1.15 \
    -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
    -e PWD_KEY=pwd.key \
    --restart=always --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --cpu-rt-runtime=95000 --ulimit rtprio=99  \
    --name racnode1 \
    oracle/database-rac:21.3.0
  ```

**Note:** Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.

### Deploying Oracle RAC on Container  With Oralce RAC Storage Container

Now create the Oracle RAC container using the image. For the details of environment variables, refer to section 6. You can use the following example to create a container:

  ```bash
  # docker create -t -i \
    --hostname racnode1 \
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
    -e NODE_VIP=172.16.1.160  \
    -e VIP_HOSTNAME=racnode1-vip  \
    -e PRIV_IP=192.168.17.150  \
    -e PRIV_HOSTNAME=racnode1-priv \
    -e PUBLIC_IP=172.16.1.150 \
    -e PUBLIC_HOSTNAME=racnode1  \
    -e SCAN_NAME=racnode-scan \
    -e OP_TYPE=INSTALL \
    -e DOMAIN=example.com \
    -e ASM_DISCOVERY_DIR=/oradata \
    -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
    -e CMAN_HOSTNAME=racnode-cman1 \
    -e CMAN_IP=172.16.1.15 \
    -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
    -e PWD_KEY=pwd.key \
    --restart=always \
    --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --cpu-rt-runtime=95000 \
    --ulimit rtprio=99  \
    --name racnode1 \
    oracle/database-rac:21.3.0
  ```

**Notes:**

* Change environment variables such as `NODE_IP`, `PRIV_IP`, `PUBLIC_IP`,  `ASM_DEVICE_LIST`, `PWD_FILE`, and `PWD_KEY` based on your environment. Also, ensure you use the correct device names on each host.
* You must have created the `racstorage` volume before the creation of the Oracle RAC Container. For details about the available environment variables, refer the section 6.

### Assign networks to Oracle RAC containers

You need to assign the Docker networks created in section 1 to containers.Eexecute the following commands:

  ```bash
  # docker network disconnect bridge racnode1
  # docker network connect rac_pub1_nw --ip 172.16.1.150 racnode1
  # docker network connect rac_priv1_nw --ip 192.168.17.150  racnode1
  ```

### Start the first container

To start the first container, run the following command:

  ```bash
  # docker start racnode1
  ```

It can take at least 40 minutes or longer to create the first node of the cluster. To check the logs, use the following command from another terminal session:

  ```bash
  # docker logs -f racnode1
  ```

You should see the database creation success message at the end:

  ```bash
  ####################################
  ORACLE RAC DATABASE IS READY TO USE!
  ####################################
  ```

### Connect to the Oracle RAC container

To connect to the container execute the following command:

```bash
# docker exec -i -t racnode1 /bin/bash
```

If the install fails for any reason, log in to the container using the preceding command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

## Section 4: Adding a Oracle RAC Node using a container

Before proceeding to the next step, ensure Oracle Grid Infrastructure is running and the Oracle RAC Database is open as per instructions in section 3. Otherwise, the node addition process will fail.

### Password management

Specify the secret volume for resetting grid/oracle and database passwords during node creation or node addition. It can be shared volume among all the containers

```bash
mkdir /opt/.secrets/
openssl rand -hex 64 -out /opt/.secrets/pwd.key
```

Edit the `/opt/.secrets/common_os_pwdfile` and seed the password for grid/oracle and database. It will be a common password for grid/oracle and database user. Execute the following command:

```bash
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

### Notes

* If you want to specify the different password for all the accounts, create 3 different files and encrypt them under `/opt/.secrets` and pass the file name to the container using the following environment variables: `ORACLE_PWD_FILE` for the `oracle` user, `GRID_PWD_FILE` for the  `grid` user and `DB_PWD_FILE` for the database password.
* if you want a common password for the `oracle`, `grid`, and database users, assign a swingle password file by using the `COMMON_OS_PWD_FILE` environment variable.

Reset the password on the existing Oracle RAC node for SSH setup between an existing node in the cluster and the new node. Password must be the same on all the nodes for the `grid` and `oracle` users. Execute the following command on an existing node of the cluster.

```bash
docker exec -i -t -u root racnode1 /bin/bash
sh  /opt/scripts/startup/resetOSPassword.sh --help
sh /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --secret_volume /run/secrets --pwd_key_file pwd.key
```

**Note:** If you do not have a common secret volume among Oracle RAC containers, populate the password file with the same password that you have used on the new node, encrypt the file, and execute `resetOSPassword.sh` on the existing node of the cluster.

### Deploying with Block Devices

If you are using an NFS volume, skip to the section "Deploying with the Oracle RAC Storage Container".

To create additional nodes, use the following command:

```bash
# docker create -t -i \
  --hostname racnode2 \
  --volume /dev/shm \
  --tmpfs /dev/shm:rw,exec,size=4G  \
  --volume /boot:/boot:ro \
  --dns-search=example.com  \
  --volume /opt/containers/rac_host_file:/etc/hosts \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns=172.16.1.25 \
  --dns-search=example.com \
  --device=/dev/xvde:/dev/asm_disk1 \
  --device=/dev/zvdf:/dev/asm_disk2 \
  --privileged=false \
  --cap-add=SYS_NICE \
  --cap-add=SYS_RESOURCE \
  --cap-add=NET_ADMIN \
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnode1 \
  -e NODE_VIP=172.16.1.161  \
  -e VIP_HOSTNAME=racnode2-vip  \
  -e PRIV_IP=192.168.17.151  \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151  \
  -e PUBLIC_HOSTNAME=racnode2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnode-scan \
  -e ASM_DISCOVERY_DIR=/dev \
  -e ASM_DEVICE_LIST=/dev/asm_disk1,/dev/asm_disk2 \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnode2 \
  oracle/database-rac:21.3.0
```

For details of all environment variables and parameters, refer to section 6.

### Deploying Oracle RAC on Container with Oracle RAC Storage Container

If you are using physical block devices for shared storage, skip to "Assigning Network to additional Oracle RAC container"

Use the existing `racstorage:/oradata` volume when creating the additional container using the image.

For example:

```bash
# docker create -t -i \
  --hostname racnode2 \
  --volume /dev/shm \
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
  -e DNS_SERVERS="172.16.1.25" \
  -e EXISTING_CLS_NODES=racnode1 \
  -e NODE_VIP=172.16.1.161  \
  -e VIP_HOSTNAME=racnode2-vip  \
  -e PRIV_IP=192.168.17.151  \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151  \
  -e PUBLIC_HOSTNAME=racnode2  \
  -e DOMAIN=example.com \
  -e SCAN_NAME=racnode-scan \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img \
  -e ORACLE_SID=ORCLCDB \
  -e OP_TYPE=ADDNODE \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e PWD_KEY=pwd.key \
  --tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cpu-rt-runtime=95000 \
  --ulimit rtprio=99  \
  --restart=always \
  --name racnode2 \
  oracle/database-rac:21.3.0
```

**Notes:**

* You must have created **racstorage** volume before the creation of the Oracle RAC container.
* You can change env variables such as IPs and ORACLE_PWD based on your env. For details about the env variables, refer the section 6.

### Assign Network to additional Oracle RAC container

Connect the private and public networks you created earlier to the container:

```bash
# docker network disconnect bridge racnode2
# docker network connect rac_pub1_nw --ip 172.16.1.151 racnode2
# docker network connect rac_priv1_nw --ip 192.168.17.151 racnode2
```

### Start Oracle RAC container

Start the container

```bash
# docker start racnode2
```

To check the database logs, tail the logs using the following command:

```bash
# docker logs -f racnode2
```

You should see the database creation success message at the end.

```text
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

### Connect to the Oracle RAC container

To connect to the container execute the following command:

```bash
# docker exec -i -t racnode2 /bin/bash
```

If the node addition fails, log in to the container using the preceding command and review `/tmp/orod.log`. You can also review the Grid Infrastructure logs i.e. `$GRID_BASE/diag/crs` and check for failure logs. If the node creation has failed during the database creation process, then check DB logs.

## Section 5: Connecting to Oracle RAC Database

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC environment.

If you are using Connection Manager and exposed port 1521 on the host, connect from an external client using the following connection string:

```bash
system/<password>@//<docker_host>:1521/<ORACLE_SID>
```

If you are using a Docker `macvlan` network and you have configured DNS appropriately, you can connect using the public SCAN listener directly from any external client using the following connection string:

```bash
system/<password>@//<scan_name>:1521/<ORACLE_SID>
```

## Section 6: Environment Variables for the first node

**IMPORTANT:** This section provides details about the environment variables that can be used when creating the first node of a cluster.

Parameters:

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
COMMON_OS_PWD_FILE=###Pass the file name to setup grid and oracle user password. If you specify ORACLE_PWD_FILE, GRID_PWD_FILE and DB_PWD_FILE then you do not need to specify this env variable###
ORACLE_PWD_FILE=###Pass the file name to set the password for oracle user.###
GRID_PWD_FILE=###Pass the file name to set the password for grid user.###
DB_PWD_FILE=###Pass the file name to set the password for DB user i.e. sys.###
REMOVE_OS_PWD_FILES=###Set this env variable to true to remove pwd key file and password file after resetting the password.###
CONTAINER_DB_FLAG=###Default value is set to true to create container database. Set this to false if you do not want to create a container database.###
```

## Section 7: Environment Variables for the second and subsequent nodes

**IMPORTANT:** This section provides the details about the environment variables that can be used for all additional nodes added to an existing cluster.

```bash
OP_TYPE=###Specify the Operation TYPE. It can accept 2 values INSTALL OR ADDNODE###
EXISTING_CLS_NODES=###Specify the Existing Node of the cluster which you want to join.If you have 2 node in the cluster and you are trying to add third node then spcify existing 2 nodes of the clusters and separate them by comma.####
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
ASM_DISCOVERY_DIR=####ASM disk location insdie the container. By default it is /dev######
COMMON_OS_PWD_FILE=###You need to pass the file name to setup grid and oracle user password. If you specify ORACLE_PWD_FILE, GRID_PWD_FILE and DB_PWD_FILE then you do not need to specify this env variable###
ORACLE_PWD_FILE=###You need to pass the file name to set the password for oracle user.###
GRID_PWD_FILE=###You need to pass the file name to set the password for grid user.###
DB_PWD_FILE=###You need to pass the file name to set the password for DB user i.e. sys.###
REMOVE_OS_PWD_FILES=###You need to set this to true to remove pwd key file and password file after resetting password.###
```

## Sample Container Files for Older Releases

This project offers sample container files for Oracle Grid Infrastructure and Oracle Real Application Clusters for dev and test:
  
* Oracle Database 19c Oracle Grid Infrastructure (19.3) for Linux x86-64
* Oracle Database 19c (19.3) for Linux x86-64
* Oracle Database 18c Oracle Grid Infrastructure (18.3) for Linux x86-64
* Oracle Database 18c (18.3) for Linux x86-64
* Oracle Database 12c Release 2 Oracle Grid Infrastructure (12.2.0.1.0) for Linux x86-64
* Oracle Database 12c Release 2 (12.2.0.1.0) Enterprise Edition for Linux x86-64
  
 **Notes:**

* Note that the Oracle RAC on Docker Container releases are supported only for test and development environments, but not for production environments.
* If you are planning to build and deploy Oracle RAC 18.3.0, you need to download Oracle 18.3.0 Grid Infrastructure and Oracle Database 18.3.0 Database. You also need to download Patch# p28322130_183000OCWRU_Linux-x86-64.zip from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html). Stage it under dockerfiles/18.3.0 folder.
* If you are planning to build and deploy Oracle RAC 12.2.0.1, you need to download Oracle 12.2.0.1 Grid Infrastructure and Oracle Database 12.2.0.1 Database. You also need to download Patch# p27383741_122010_Linux-x86-64.zip from [Oracle Technology Network](https://www.oracle.com/technetwork/database/database-technologies/clusterware/downloads/docker-4418413.html). Stage it under dockerfiles/12.2.0.1 folder.
  
## Section 9 : Support

At the time of this release, Oracle RAC on Docker is supported only on Oracle Linux 7. To see current details, refer the [Real Application Clusters Installation Guide for Docker Containers Oracle Linux x86-64](https://docs.oracle.com/en/database/oracle/oracle-database/21/racdk/oracle-rac-on-docker.html).

## Section 10 : License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Section 11 : Copyright

Copyright (c) 2014-2022 Oracle and/or its affiliates.
