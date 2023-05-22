# Example of creating a custom Oracle RAC database

Once you have built your Oracle RAC container image you can create a Oracle RAC database with a custom configuration by passing the responsefile for Oracle Grid and Database to the container.

- [Example of creating a custom Oracle RAC database](#example-of-creating-a-custom-oracle-rac-database)
  - [Section 1 : Prerequisites for Custom RAC Database on Docker](#section-1--prerequisites-for-custom-rac-database-on-docker)
  - [Section 2 : Preparing Responsefile](#section-2--preparing-responsefile)
  - [Section 3 : Creating the RAC Container](#section-3--creating-the-rac-container)
    - [Network and Password Management](#network-and-password-management)
  - [Section 4: Oracle RAC on Docker](#section-4-oracle-rac-on-docker)
    - [Create Racnoded1 with Block Devices](#create-racnoded1-with-block-devices)
      - [Create Racnoded2 with Block Devices](#create-racnoded2-with-block-devices)
    - [Deploying RAC on Docker with NFS Volume](#deploying-rac-on-docker-with-nfs-volume)
      - [Create Racnoded1 with NFS Volume](#create-racnoded1-with-nfs-volume)
      - [Create Racnoded2 with NFS Volume](#create-racnoded2-with-nfs-volume)
    - [Attach the network to containers](#attach-the-network-to-containers)
      - [Attach the network to Racnoded1](#attach-the-network-to-racnoded1)
      - [Attach the network to Racnoded2](#attach-the-network-to-racnoded2)
    - [Start the containers](#start-the-containers)
      - [Start Racnoded2](#start-racnoded2)
      - [Reset the password](#reset-the-password)
      - [Start Racnoded1](#start-racnoded1)
      - [Connect to the RAC container](#connect-to-the-rac-container)
  - [Section 5: Oracle RAC on Podman](#section-5-oracle-rac-on-podman)
    - [Deploying RAC on Podman With Block Devices](#deploying-rac-on-podman-with-block-devices)
      - [Create Racnodep1 with Block Devices](#create-racnodep1-with-block-devices)
      - [Create Racnodep2 with Block Devices](#create-racnodep2-with-block-devices)
    - [Deploying RAC on Podman with NFS Volume](#deploying-rac-on-podman-with-nfs-volume)
      - [Create Racnodep1 with NFS Volume](#create-racnodep1-with-nfs-volume)
      - [Create Racnodep2 with NFS Volume](#create-racnodep2-with-nfs-volume)
    - [Attach the network to RAC Podman containers](#attach-the-network-to-rac-podman-containers)
      - [Attach the network to Racnodep1](#attach-the-network-to-racnodep1)
      - [Attach the network to Racnodep2](#attach-the-network-to-racnodep2)
    - [Start the Racnodep1 and Racnodep2 containers](#start-the-racnodep1-and-racnodep2-containers)
      - [Start Racnodep2](#start-racnodep2)
      - [Reset the password in Racnodep2 container](#reset-the-password-in-racnodep2-container)
      - [Start Racnodep1](#start-racnodep1)
  - [Copyright](#copyright)

## Section 1 : Prerequisites for Custom RAC Database on Docker

**IMPORTANT :** You must execute all the steps specified in this section (customized for your environment) before you proceed to the next section.

- Create RAC Storage docker image and container, if you are planing to use NFS storage container for testing. Please refer [RAC Storage Container README.MD](../../../OracleRACStorageServer/README.md). You can skip this step if you are planing to use **block devices for storage**.
- Create Oracle Connection Manager on Docker image and container if the IPs are not available on user network.Please refer [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md).
- Execute the [Section 1 : Prerequisites for running Oracle RAC in containers](../../../OracleRealApplicationClusters/README.md).
- If you have not built the Oracle RAC container image, execute the steps in [Section 2: Building Oracle RAC Database Container Images](../../../OracleRealApplicationClusters/README.md) based on your environment.

## Section 2 : Preparing Responsefile

- Create a following directory on container hosts:

```bash
mkdir -p /opt/containers/common_scripts
```

- Copy the Oracle grid and database responsefile under /opt/containers/common_scripts.
  - You can create responsefile, based on your environment. You can find the response file grid.rsp and dbca.rsp under `<version>` dir.
  - In this README.MD, we have used pre-populated Oracle grid and database responsefiles. Copy them under `/opt/containers/common_scripts`.

```bash
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/<version/grid_sample.rsp /opt/containers/common_scripts
cp docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/samples/customracdb/<version>/dbca_sample.rsp /opt/containers/common_scripts
```

**Notes**:

- Using the sample responsefiles, you will be able to create 2 or more node RAC on containers.
- You need to modify responsefiles based on your environment and pass them during container creation. You need to change or add following based on your enviornment:
  - Public/private IP subnet
  - ASM disks for ASM storage
  - ASM Redundancy level
  - ASM failure disk groups
  - Passwords for different accounts

## Section 3 : Creating the RAC Container

All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```bash
# mkdir /opt/containers
# touch /opt/containers/rac_host_file
```

**Note:** Do not modify `/opt/containers/rac_host_file` from docker host. It will be managed from within the containers.

If you are using the Oracle Connection Manager for accessing the Oracle RAC Database from outside the host, you need to add following variable in the container creation command.

```bash
-e CMAN_HOSTNAME=(CMAN_HOSTNAME) -e CMAN_IP=(CMAN_IP)
```

**Note:** You need to replace `CMAN_HOSTNAME` and `CMAN_IP` with the correct values based on your environment settings.

### Network and Password Management

- Refer [Section 3: Network and Password Management](../../../OracleRealApplicationClusters/README.md) to create network and encrypted password files on each container hosts.

<!-- markdownlint-disable-next-line MD036 -->
**Notes**

- If you want to specify different password for all the accounts, create 3 different files and encrypt them under /opt/.secrets and pass the file name to the container using env variable. Env variables can be ORACLE_PWD_FILE for oracle user, GRID_PWD_FILE for grid user and DB_PWD_FILE for database password.
- if you want common password oracle, grid and db user, you can assign password file name to COMMON_OS_PWD_FILE env variable.

## Section 4: Oracle RAC on Docker

Refer [Section 4.1 : Prerequisites for Running Oracle RAC on Docker](../../../OracleRealApplicationClusters/README.md) to complete the pre-requisite steps for Oracle RAC on Docker.

If you are using an NFS volume, skip to the section below "Deploying RAC on Docker with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

Now create the Docker container using the image. For the details of environment variables, please refer to section 5. You can use following example to create a container:

### Create Racnoded1 with Block Devices

```bash
docker create -t -i \
--hostname Racnoded1 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--device=/dev/xvde:/dev/asm_disk1 \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.160 \
-e VIP_HOSTNAME=Racnoded1-vip \
-e PRIV_IP=192.168.17.150 \
-e PRIV_HOSTNAME=Racnoded1-priv \
-e PUBLIC_IP=172.16.1.150 \
-e PUBLIC_HOSTNAME=Racnoded1 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/dev/asm_disk1 \
-e ASM_DISCOVERY_DIR=/dev \
-e CRS_NODES="Racnoded1,Racnoded2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
-e OP_TYPE="INSTALL" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name Racnoded1 oracle/database-rac:19.3.0
```

#### Create Racnoded2 with Block Devices

```bash
docker create -t -i \
--hostname Racnoded2 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--device=/dev/xvde:/dev/asm_disk1 \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.161 \
-e VIP_HOSTNAME=Racnoded2-vip \
-e PRIV_IP=192.168.17.151 \
-e PRIV_HOSTNAME=Racnoded2-priv \
-e PUBLIC_IP=172.16.1.151 \
-e PUBLIC_HOSTNAME=Racnoded2 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/dev/asm_disk1 \
-e ASM_DISCOVERY_DIR=/dev \
-e CRS_NODES="Racnoded1,Racnoded2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name Racnoded2 oracle/database-rac:19.3.0
```

**Note:** Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.

### Deploying RAC on Docker with NFS Volume

Create RAC containers and utilize RAC storage containers for ASM devices:

#### Create Racnoded1 with NFS Volume

```bash
docker create -t -i \
--hostname Racnoded1 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--volume racstorage:/oradata \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.160 \
-e VIP_HOSTNAME=Racnoded1-vip \
-e PRIV_IP=192.168.17.150 \
-e PRIV_HOSTNAME=Racnoded1-priv \
-e PUBLIC_IP=172.16.1.150 \
-e PUBLIC_HOSTNAME=Racnoded1 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
-e ASM_DISCOVERY_DIR=/oradata \
-e CRS_NODES="Racnoded1,Racnoded2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
-e OP_TYPE="INSTALL" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name Racnoded1 oracle/database-rac:19.3.0
```

#### Create Racnoded2 with NFS Volume

```bash
docker create -t -i \
--hostname Racnoded2 \
--volume /boot:/boot:ro \
--volume /dev/shm \
--volume /opt/.secrets:/run/secrets \
--volume /opt/containers/common_scripts:/common_scripts \
--volume /opt/containers/rac_host_file:/etc/hosts \
--volume racstorage:/oradata \
--tmpfs /dev/shm:rw,exec,size=4G \
--dns-search=example.com \
--privileged=false \
--cap-add=SYS_NICE \
--cap-add=SYS_RESOURCE \
--cap-add=NET_ADMIN \
-e NODE_VIP=172.16.1.161 \
-e VIP_HOSTNAME=Racnoded2-vip \
-e PRIV_IP=192.168.17.151 \
-e PRIV_HOSTNAME=Racnoded2-priv \
-e PUBLIC_IP=172.16.1.151 \
-e PUBLIC_HOSTNAME=Racnoded2 \
-e SCAN_NAME="racnode-scan" \
-e SCAN_IP=172.16.1.70 \
-e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
-e DOMAIN=example.com \
-e DEFAULT_GATEWAY=172.16.1.1 \
-e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
-e ASM_DISCOVERY_DIR=/oradata \
-e CRS_NODES="Racnoded1,Racnoded2" \
-e GRID_RESPONSE_FILE="grid_sample.rsp" \
-e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
--restart=always \
--tmpfs=/run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
--cpu-rt-runtime=95000 \
--ulimit rtprio=99 \
--name Racnoded2 oracle/database-rac:19.3.0
```

**Notes:**

- Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.
- You must have created the `racstorage` volume before the creation of RAC Container. For details about the env variables, please refer the section 6.

### Attach the network to containers

You need to assign the Docker networks created in [section 1 of README.md](../../../OracleRealApplicationClusters/README.md) to containers. Please execute following commands:

#### Attach the network to Racnoded1

```bash
# docker network disconnect bridge Racnoded1
# docker network connect rac_pub1_nw --ip 172.16.1.150 Racnoded1
# docker network connect rac_priv1_nw --ip 192.168.17.150  Racnoded1
```

#### Attach the network to Racnoded2

You need to assign the Docker networks created in section 1 to containers. Please execute following commands:

```bash
# docker network disconnect bridge Racnoded2
# docker network connect rac_pub1_nw --ip 172.16.1.151 Racnoded2
# docker network connect rac_priv1_nw --ip 192.168.17.151  Racnoded2
```

### Start the containers

You need to start the container. Please execute following command:

#### Start Racnoded2

```bash
# docker start Racnoded2
```

#### Reset the password

Execute this step only on Racnoded2.

```bash
docker exec Racnoded2 /bin/bash -c "sudo /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --pwd_key_file pwd.key"
```

#### Start Racnoded1

```bash
# docker start Racnoded1
```

It can take at least 40 minutes or longer to create and setup 2 node RAC cluster. To check the logs, use following command from another terminal session:

```bash
# docker logs -f Racnoded1
```

You should see database creation success message at the end:

```bash
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

#### Connect to the RAC container

To connect to the container execute following command:

```bash
# docker exec -i -t Racnoded1 /bin/bash
```

If the install fails for any reason, log in to container using the above command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

## Section 5: Oracle RAC on Podman

Refer [Section 5.1 : Prerequisites for Running Oracle RAC on Podman](../../../OracleRealApplicationClusters/README.md) to complete the pre-requisite steps for Oracle RAC on Podman.

### Deploying RAC on Podman With Block Devices

If you are using an NFS volume, skip to the section below "Deploying RAC on Podman with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

#### Create Racnodep1 with Block Devices

```bash
podman create -t -i \
  --hostname racnodep1 \
  --volume /boot:/boot:ro \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --dns 172.16.1.25 \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/containers/common_scripts:/common_scripts \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns-search=example.info \
  --device=/dev/xvde:/dev/asm_disk1 \
  --privileged=false \
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
  -e NODE_VIP=172.16.1.160 \
  -e VIP_HOSTNAME=racnode1-vip \
  -e PRIV_IP=192.168.17.150 \
  -e PRIV_HOSTNAME=racnode1-priv \
  -e PUBLIC_IP=172.16.1.150 \
  -e PUBLIC_HOSTNAME=racnode1 \
  -e SCAN_NAME="racnode-scan" \
  -e SCAN_IP=172.16.1.70 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e DOMAIN=example.com \
  -e DEFAULT_GATEWAY=172.16.1.1 \
  -e ASM_DEVICE_LIST=/dev/asm_disk1 \
  -e ASM_DISCOVERY_DIR=/dev \
  -e TMPDIR=/var/tmp \
  -e CRS_NODES="racnodep1,racnodep2" \
  -e GRID_RESPONSE_FILE="grid_sample.rsp" \
  -e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
  -e OP_TYPE="INSTALL" \
  -e RESET_FAILED_SYSTEMD="true" \
  -e ORACLE_SID=ORCLCDB \
  --restart=always \
  --systemd=always \
  --ulimit rtprio=99  \
  --name racnodep1 \
  localhost/oracle/database-rac:21.3.0-21.7.0 
```

**Note**: Note: Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.

#### Create Racnodep2 with Block Devices

```bash
podman create -t -i \
  --hostname racnodep2 \
  --volume /boot:/boot:ro \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets1:/run/secrets:ro \
   --volume /opt/containers/common_scripts:/common_scripts \
   --dns 172.16.1.25 \
  --dns-search "example.info" \
  --device=/dev/xvde:/dev/asm_disk1 \
  --privileged=false \
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
  -e NODE_VIP=172.16.1.161 \
  -e VIP_HOSTNAME=racnode2-vip \
  -e PRIV_IP=192.168.17.151 \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151 \
  -e PUBLIC_HOSTNAME=racnode2 \
  -e SCAN_NAME="racnode-scan" \
  -e SCAN_IP=172.16.1.70 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e DOMAIN=example.com \
  -e DEFAULT_GATEWAY=172.16.1.1 \
  -e ASM_DEVICE_LIST=/dev/asm_disk1 \
  -e ASM_DISCOVERY_DIR=/dev \
  -e CRS_NODES="racnode1,racnode2" \
  -e GRID_RESPONSE_FILE="grid_sample.rsp" \
  -e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
  -e TMPDIR=/var/tmp \
  -e RESET_FAILED_SYSTEMD="true" \
  -e ORACLE_SID=ORCLCDB \
  --restart=always \
  --systemd=always \
  --ulimit rtprio=99  \
  --name racnodep2 \
  localhost/oracle/database-rac:21.3.0-21.7.0
```

**Note**: Note: Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.

### Deploying RAC on Podman with NFS Volume

If you are using an Block devices, skip to the section below "Deploying RAC on Podman with Block Devices".

Create RAC containers and utilize RAC storage containers for ASM devices:

#### Create Racnodep1 with NFS Volume

```bash
podman create -t -i \
  --hostname racnodep1 \
  --volume /boot:/boot:ro \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/containers/common_scripts:/common_scripts \
  --volume /opt/.secrets:/run/secrets:ro \
  --dns-search=example.info \
  --volume racstorage:/oradata \
  --privileged=false \
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
  -e NODE_VIP=172.16.1.160 \
  -e VIP_HOSTNAME=racnode1-vip \
  -e PRIV_IP=192.168.17.150 \
  -e PRIV_HOSTNAME=racnode1-priv \
  -e PUBLIC_IP=172.16.1.150 \
  -e PUBLIC_HOSTNAME=racnode1 \
  -e SCAN_NAME="racnode-scan" \
  -e SCAN_IP=172.16.1.70 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e DOMAIN=example.com \
  -e DEFAULT_GATEWAY=172.16.1.1 \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e TMPDIR=/var/tmp \
  -e CRS_NODES="racnodep1,racnodep2" \
  -e GRID_RESPONSE_FILE="grid_sample.rsp" \
  -e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
  -e OP_TYPE="INSTALL" \
  -e RESET_FAILED_SYSTEMD="true" \
  -e ORACLE_SID=ORCLCDB \
  --restart=always \
  --systemd=always \
  --ulimit rtprio=99  \
  --name racnodep1 \
  localhost/oracle/database-rac:21.3.0-21.7.0 
```

#### Create Racnodep2 with NFS Volume

```bash
podman create -t -i \
  --hostname racnodep2 \
  --volume /boot:/boot:ro \
  --tmpfs /dev/shm:rw,exec,size=4G \
  --volume /opt/containers/rac_host_file:/etc/hosts  \
  --volume /opt/.secrets1:/run/secrets:ro \
  --dns-search "example.info" \
  --volume racstorage:/oradata \
  --privileged=false \
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
  -e NODE_VIP=172.16.1.161 \
  -e VIP_HOSTNAME=racnode2-vip \
  -e PRIV_IP=192.168.17.151 \
  -e PRIV_HOSTNAME=racnode2-priv \
  -e PUBLIC_IP=172.16.1.151 \
  -e PUBLIC_HOSTNAME=racnode2 \
  -e SCAN_NAME="racnode-scan" \
  -e SCAN_IP=172.16.1.70 \
  -e COMMON_OS_PWD_FILE=common_os_pwdfile.enc \
  -e DOMAIN=example.com \
  -e DEFAULT_GATEWAY=172.16.1.1 \
  -e ASM_DEVICE_LIST=/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img  \
  -e ASM_DISCOVERY_DIR=/oradata \
  -e CRS_NODES="racnode1,racnode2" \
  -e GRID_RESPONSE_FILE="grid_sample.rsp" \
  -e DBCA_RESPONSE_FILE="dbca_sample.rsp" \
  --restart=always \
  --systemd=always \
  --ulimit rtprio=99  \
  --name racnodep2 \
  localhost/oracle/database-rac:21.3.0-21.7.0
```

**Notes:**

- Change environment variable such as IPs, ASM_DEVICE_LIST, PWD_FILE and PWD_KEY based on your env. Also, change the devices based on your env.
- You must have created the `racstorage` volume before the creation of RAC Container.

### Attach the network to RAC Podman containers

You need to assign the podman networks created in [Section 3: Network and Password Management](../../../OracleRealApplicationClusters/README.md):

#### Attach the network to Racnodep1

```bash
# podman network disconnect bridge racnodep1
# podman network connect rac_pub1_nw --ip 172.16.1.150 racnodep1
# podman network connect rac_priv1_nw --ip 192.168.17.150  racnodep1
```

#### Attach the network to Racnodep2

```bash
# podman network disconnect bridge racnodep2
# podman network connect rac_pub1_nw --ip 172.16.1.151 racnodep2
# podman network connect rac_priv1_nw --ip 192.168.17.151  racnodep2
```

### Start the Racnodep1 and Racnodep2 containers

You need to start the container. Please execute following command:

#### Start Racnodep2

```bash
# podman start racnodep2
```

#### Reset the password in Racnodep2 container

Execute this step only on racnodep2.

```bash
podman exec racnodep2 /bin/bash -c "sudo /opt/scripts/startup/resetOSPassword.sh --op_type reset_grid_oracle --pwd_file common_os_pwdfile.enc --pwd_key_file pwd.key"
```

#### Start Racnodep1

```bash
# podman start racnodep1
```

It can take at least 40 minutes or longer to create and setup 2 node RAC cluster. To check the logs, use following command from another terminal session:

```bash
# podman logs -f racnodep1
```

You should see database creation success message at the end:

```bash
####################################
ORACLE RAC DATABASE IS READY TO USE!
####################################
```

## Copyright

Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
