# Example of creating an Oracle RAC database with Podman Compose

Once you have built your Oracle RAC container image, you can create a Oracle RAC database with Podman Compose on Single Host via Bridge Network as example given below.

- [Example of creating an Oracle RAC database with Podman Compose](#example-of-creating-an-oracle-rac-database-with-podman-compose)
  - [Section 1 : Prerequisites for RAC Database on Podman with Podman Compose](#section-1--prerequisites-for-rac-database-on-podman-with-podman-compose)
  - [Section 2 : Preparing Environment Variables](#section-2--preparing-environment-variables)
    - [Section 2.1: Preparing Environment Variables for RAC with Block Devices](#section-21-preparing-environment-variables-for-rac-with-block-devices)
    - [Section 2.2: Preparing Environment Variables for RAC with NFS Storage Devices](#section-22-preparing-environment-variables-for-rac-with-nfs-storage-devices)
  - [Section 3 : Deploy the RAC Container](#section-3--deploy-the-rac-container)
    - [Section 3.1: Deploy the RAC Container with Block Devices](#section-31-deploy-the-rac-container-with-block-devices)
    - [Section 3.2: Deploy the RAC Container with NFS Storage Devices](#section-32-deploy-the-rac-container-with-nfs-storage-devices)
  - [Section 4: Add Additional Node in Existing Oracle RAC Cluster](#section-4-add-additional-node-in-existing-oracle-rac-cluster)
    - [Section 4.1: Add Additional Node in Existing Oracle RAC Cluster with Block Devices](#section-41-add-additional-node-in-existing-oracle-rac-cluster-with-block-devices)
    - [Section 4.2: Add Additional Node in Existing Oracle RAC Cluster with NFS Volume](#section-42-add-additional-node-in-existing-oracle-rac-cluster-with-nfs-volume)
  - [Section 5: Connect to the RAC container](#connect-to-the-rac-container)
  - [Cleanup RAC Environment](#cleanup-rac-environment)
  - [Copyright](#copyright)

## Section 1 : Prerequisites for RAC Database on Podman with Podman Compose

**IMPORTANT :** You must execute all the steps specified in this section (customized for your environment) before you proceed to the next section. Podman and Podman Compose is not supported with OL7. You need OL8.8 with UEK R7. This guide and example is mainly for development and testing purposes only.

- It is assumed that before proceeding further you have executed the pre-requisites from [Section 1 : Prerequisites for running Oracle RAC in containers](../../../OracleRealApplicationClusters/README.md)  and [Section 5.1 : Prerequisites for Running Oracle RAC on Podman](../../../OracleRealApplicationClusters/README.md) for Single Podman Host Machine .
- Create DNS podman image, if you are planing to use DNS container for testing. Please refer [DNS Container README.MD](../../../OracleDNSServer/README.md). You can skip this step if you are planing to use **your own DNS Server**.
- Create Oracle Connection Manager Podman image.Please refer [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md) for details.
- Execute the [Section 1 : Prerequisites for running Oracle RAC in containers](../../../OracleRealApplicationClusters/README.md).
- If you have not built the Oracle RAC container image, execute the steps in [Section 2: Building Oracle RAC Database Container Images](../../../OracleRealApplicationClusters/README.md) based on your environment.

In order to setup RAC on Podman with Podman Compose, latest `podman-compose` binary is required from yum repo in OL8 Host. This is example of how to install latest `podman-compose` from yum repo-
```bash
dnf config-manager --enable ol8_developer_EPEL
dnf install podman-compose -y
```

## Section 2 : Preparing Environment Variables

### Section 2.1: Preparing Environment Variables for RAC with Block Devices

In order to setup Oracle RAC on Podman with Block Devices with Podman Compose, first lets identify necessary variables to export that will be used by `podman-compose.yml` file later. Below is one example of exporting necessary variables related to podman network, DNS container, RAC Container and CMAN container discussed in this repo.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_PUBLIC_IP=172.16.1.25
export DNS_PRIVATE_IP=192.168.17.25
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE1_NODE_VIP=172.16.1.200
export RACNODE1_VIP_HOSTNAME="racnodep1-vip"
export RACNODE1_PRIV_IP=192.168.17.170
export RACNODE1_PRIV_HOSTNAME="racnodep1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.170
export RACNODE1_PUBLIC_HOSTNAME="racnodep1"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export INSTALL_NODE=racnodep1
export SCAN_NAME="racnodepc1-scan"
export SCAN_IP=172.16.1.236
export ASM_DISCOVERY_DIR="/dev/"
export PWD_KEY="pwd.key"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ORACLE_SID="ORCLCDB"
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_IP=172.16.1.15
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="oracle/client-cman:21.3.0"
export DNS_DOMAIN="example.com"
export CMAN_PUBLIC_IP=172.16.1.166
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export CMAN_VERSION="21.3.0"
```
### Section 2.2: Preparing Environment Variables for RAC with NFS Storage Devices

In order to setup Oracle RAC on Podman with Oracle RAC Storage Container with Podman Compose, lets first make sure `nfs-utils` rpm package is installed in Podman Host machine.
```bash
yum -y install nfs-utils
```

If SELinux is enabled on Podman Host (you can check by running `sestatus` command), then execute below to make SELinux policy as `permissive` and reboot host machine. This will allow permissions to write to `asm-disks*` in the `/oradata` folder inside the podman containers-
```bash
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
reboot
```

Lets identify necessary variables to export that will be used by `podman-compose.yml` file later. Below is one example of exporting necessary variables related to docker network, DNS container, Storage Container, RAC Container and CMAN container discussed in this repo.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_PUBLIC_IP=172.16.1.25
export DNS_PRIVATE_IP=192.168.17.25
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE1_NODE_VIP=172.16.1.200
export RACNODE1_VIP_HOSTNAME="racnodep1-vip"
export RACNODE1_PRIV_IP=192.168.17.170
export RACNODE1_PRIV_HOSTNAME="racnodep1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.170
export RACNODE1_PUBLIC_HOSTNAME="racnodep1"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export INSTALL_NODE=racnodep1
export SCAN_NAME="racnodepc1-scan"
export SCAN_IP=172.16.1.236
export ASM_DISCOVERY_DIR="/dev/"
export PWD_KEY="pwd.key"
export ASM_DISCOVERY_DIR="/oradata"
export ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export ORACLE_SID="ORCLCDB"
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_IP=172.16.1.15
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="oracle/client-cman:21.3.0"
export DNS_DOMAIN="example.com"
export CMAN_PUBLIC_IP=172.16.1.166
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export CMAN_VERSION="21.3.0"
export STORAGE_CONTAINER_NAME="racnode-storage"
export STORAGE_HOST_NAME="racnode-storage"
export STORAGE_IMAGE_NAME="localhost/oracle/rac-storage-server:latest"
export ORACLE_DBNAME="ORCLCDB"
export STORAGE_PRIVATE_IP=192.168.17.80
export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
```

## Section 3 : Deploy the RAC Container

Refer [Section 5.1 : Prerequisites for Running Oracle RAC on Podman](../../../OracleRealApplicationClusters/README.md) to complete the pre-requisite steps for Oracle RAC on Podman.

All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```bash
mkdir /opt/containers
touch /opt/containers/rac_host_file
```

**Note:** Do not modify `/opt/containers/rac_host_file` from podman host. It will be managed from within the containers.

Specify the secret volume for resetting the grid, oracle, and database user password during node creation or node addition. The volume can be a shared volume among all the containers. For example:
```bash
mkdir /opt/.secrets/
openssl rand -out /opt/.secrets/pwd.key -hex 64 
```
Edit the /opt/.secrets/common_os_pwdfile and seed the password for the grid, oracle and database users. For this deployment scenario, it will be a common password for the grid, oracle, and database users. Run the command:
```bash
openssl enc -aes-256-cbc -salt -in /opt/.secrets/common_os_pwdfile -out /opt/.secrets/common_os_pwdfile.enc -pass file:/opt/.secrets/pwd.key
rm -f /opt/.secrets/common_os_pwdfile
```

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
dd if=/dev/zero of=/dev/xvde  bs=8k count=10000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

### Section 3.1: Deploy the RAC Container with Block Devices

Once pre-requisites and above necessary variables are exported, copy `podman-compose.yml` file from [this location](./compose-files/blockdevices/podman-compose.yml)

After copying compose file, you can bring up DNS Container, RAC Container and CMAN container in order by following below commands-
```bash
#---------Bring up DNS------------
podman-compose up -d ${DNS_CONTAINER_NAME} && podman-compose stop ${DNS_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${DNS_PRIVATE_IP} ${DNS_CONTAINER_NAME}
podman-compose start ${DNS_CONTAINER_NAME}
podman-compose logs ${DNS_CONTAINER_NAME}


01-21-2024 18:03:46 UTC : : ################################################
01-21-2024 18:03:46 UTC : : DNS Server IS READY TO USE!
01-21-2024 18:03:46 UTC : : ################################################
```

```bash
#-----Bring up racnode1----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE1_CONTAINER_NAME} && \
podman-compose stop ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE1_PRIV_IP} ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod.log"

racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
racnode1  | 01-19-2024 16:34:24 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
```

```bash
#-----Bring up CMAN----------
podman-compose up -d ${CMAN_CONTAINER_NAME}
podman-compose logs ${CMAN_CONTAINER_NAME}

01-21-2024 17:32:55 UTC :  : ################################################
01-21-2024 17:32:55 UTC :  :  CONNECTION MANAGER IS READY TO USE!           
01-21-2024 17:32:55 UTC :  : ################################################
```

Note: Podman compose currently doesn't supports assigning multiple network IP address via compose file. Due to this limitation, above commands are specificically assigning required public and private networks to RAC container while stopping it in between. Also, above example is specific to bridge networks.

In case, of MCVLAN or IPVLAN networks, you may want to edit `podman-compose.yml` file are per your needs and respective environment variables.

### Section 3.2: Deploy the RAC Container with NFS Storage Devices

Once pre-requisites for NFS Storage Devices and above necessary variables are exported, copy `podman-compose.yml` file from [this location](./compose-files/nfsdevices/podman-compose.yml)

Create placeholder for NFS storage and make sure it is empty -
```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /scratch/stage/rac-storage/$ORACLE_DBNAME
rm -rf /scratch/stage/rac-storage/ORCLCDB/asm_disk0*
```

After copying compose file, you can bring up DNS Container, Storage Container, RAC Container and CMAN container by following below commands-
```bash
#---------Bring up DNS------------
podman-compose up -d ${DNS_CONTAINER_NAME} && podman-compose stop ${DNS_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${DNS_PRIVATE_IP} ${DNS_CONTAINER_NAME}
podman-compose start ${DNS_CONTAINER_NAME}
podman-compose logs ${DNS_CONTAINER_NAME}

01-21-2024 18:03:46 UTC : : ################################################
01-21-2024 18:03:46 UTC : : DNS Server IS READY TO USE!
01-21-2024 18:03:46 UTC : : ################################################
```

```bash
#----- Bring up Storage Container-----
podman-compose --podman-run-args="-t -i --systemd=always" up -d ${STORAGE_CONTAINER_NAME}
podman-compose exec ${STORAGE_CONTAINER_NAME} tail -f /tmp/storage_setup.log

Export list for racnode-storage:
/oradata *
#################################################
 Setup Completed                                 
#################################################
```

```bash
#----------Create NFS volume--------------
podman volume create --driver local \
--opt type=nfs \
--opt   o=addr=192.168.17.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=192.168.17.80:/oradata \
racstorage
```


```bash
#-----Bring up racnode1----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE1_CONTAINER_NAME} && \
podman-compose stop ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE1_PRIV_IP} ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod.log"

02-01-2024 12:26:29 UTC :  : #################################################################
02-01-2024 12:26:29 UTC :  :  Oracle Database ORCLCDB is up and running on racnodep1    
02-01-2024 12:26:29 UTC :  : #################################################################
02-01-2024 12:26:29 UTC :  : Running User Script
02-01-2024 12:26:29 UTC :  : Setting Remote Listener
02-01-2024 12:26:39 UTC :  : 172.16.1.166
02-01-2024 12:26:39 UTC :  : Executing script to set the remote listener
02-01-2024 12:26:40 UTC :  : ####################################
02-01-2024 12:26:40 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
02-01-2024 12:26:40 UTC :  : ####################################
```

```bash
#-----Bring up CMAN----------
podman-compose up -d ${CMAN_CONTAINER_NAME}
podman-compose logs ${CMAN_CONTAINER_NAME}

02-01-2024 12:30:50 UTC :  : ################################################
02-01-2024 12:30:50 UTC :  :  CONNECTION MANAGER IS READY TO USE!            
02-01-2024 12:30:50 UTC :  : ################################################
```

Note: Podman compose currently doesn't supports assigning multiple network IP address via compose file. Due to this limitation, above commands are specificically assigning required public and private networks to RAC container while stopping it in between. Also, above example is specific to bridge networks.

In case, of MCVLAN or IPVLAN networks, you may want to edit `podman-compose.yml` file are per your needs and respective environment variables.

## Section 4: Add Additional Node in Existing Oracle RAC Cluster

### Section 4.1: Add Additional Node in Existing Oracle RAC Cluster with Block Devices
In order to add additional node in existing Oracle RAC on Podman with Block Devices with Podman Compose, first lets identify necessary variables to export that will be used by `podman-compose.yml` file later. Below is one example of exporting necessary variables related to additional RAC Container with Block Devices.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_HOST_NAME=rac-dns
export DNS_DOMAIN="example.com"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export INSTALL_NODE=racnodep1
export SCAN_NAME="racnodepc1-scan"
export SCAN_IP=172.16.1.236
export ASM_DISCOVERY_DIR="/dev/"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE2_NODE_VIP=172.16.1.201
export RACNODE2_VIP_HOSTNAME="racnodep2-vip"
export RACNODE2_PRIV_IP=192.168.17.171
export RACNODE2_PRIV_HOSTNAME="racnodep2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.171
export RACNODE2_PUBLIC_HOSTNAME="racnodep2"
export ORACLE_DBNAME="ORCLCDB"
```
Once necessary variables are exported, copy `podman-compose-addition.yml` file from [this location](./compose-files/blockdevices/podman-compose-addition.yml) and rename it as `podman-compose.yml`

After copying compose file, you can bring up additional RAC Container by following below commands-

```bash
#-----Bring up racnode2----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME} && \
podman-compose stop ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE2_PRIV_IP} ${RACNODE2_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman-compose exec ${RACNODE2_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod.log"

02-01-2024 11:48:39 UTC :  : #################################################################
02-01-2024 11:48:39 UTC :  :  Oracle Database ORCLCDB is up and running on racnodep2    
02-01-2024 11:48:39 UTC :  : #################################################################
02-01-2024 11:48:39 UTC :  : Running User Script
02-01-2024 11:48:40 UTC :  : Setting Remote Listener
02-01-2024 11:48:40 UTC :  : ####################################
02-01-2024 11:48:40 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
02-01-2024 11:48:40 UTC :  : ####################################
```


### Section 4.2: Add Additional Node in Existing Oracle RAC Cluster with NFS Volume

In order to add additional node in existing Oracle RAC on Podman with NFS Storage Devices with Podman Compose, first lets identify necessary variables to export that will be used by `podman-compose.yml` file later. Below is one example of exporting necessary variables related to additional RAC Container with NFS Storage.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_HOST_NAME=rac-dns
export DNS_DOMAIN="example.com"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export INSTALL_NODE=racnodep1
export SCAN_NAME="racnodepc1-scan"
export SCAN_IP=172.16.1.236
export ASM_DISCOVERY_DIR="/dev/"
export ASM_DISCOVERY_DIR="/oradata"
export ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export ORACLE_SID="ORCLCDB"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export STORAGE_PRIVATE_IP=192.168.17.80
export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE2_NODE_VIP=172.16.1.201
export RACNODE2_VIP_HOSTNAME="racnodep2-vip"
export RACNODE2_PRIV_IP=192.168.17.171
export RACNODE2_PRIV_HOSTNAME="racnodep2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.171
export RACNODE2_PUBLIC_HOSTNAME="racnodep2"
export ORACLE_DBNAME="ORCLCDB"
```
Once necessary variables are exported, copy `podman-compose-addition.yml` file from [this location](./compose-files/nfsdevices/podman-compose-addition.yml) and rename it as `podman-compose.yml`


After copying compose file, you can bring up additional RAC Container by following below commands-

```bash
#-----Bring up racnode2----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME} && \
podman-compose stop ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE2_PRIV_IP} ${RACNODE2_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman-compose exec ${RACNODE2_CONTAINER_NAME} /bin/bash -c "systemctl reset-failed && tail -f /tmp/orod.log"

02-01-2024 12:46:13 UTC :  : ####################################
02-01-2024 12:46:13 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
02-01-2024 12:46:13 UTC :  : ####################################
```
#### Connect to the RAC container

To connect to the container execute following command:

```bash
podman exec -i -t racnodep1 /bin/bash
```

If the install fails for any reason, log in to container using the above command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

## Cleanup RAC Environment
Below commands can be executed to cleanup above RAC Environment -

### Cleanup RAC based on Block Devices
```bash
#----Cleanup RAC Containers-----
podman rm -f racnodep1 racnodep2 rac-dnsserver racnodepc1-cman 
#----Cleanup Disks--------------
dd if=/dev/zero of=/dev/oracleoci/oraclevde  bs=8k count=10000 status=progress && dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000 status=progress
#----Cleanup Files and Folders--
rm -rf /opt/containers /opt/.secrets
#----Cleanup Docker Networks--
podman network rm -f rac_pub1_nw rac_zriv1_nw
#----Cleanup Docker Images--
podman rmi -f localhost/oracle/rac-dnsserver:latest localhost/oracle/database-rac:21.3.0-21.13.0 localhost/oracle/client-cman:21.3.0
```

### Cleanup RAC based on NFS Storage Devices
```bash
#----Cleanup RAC Containers-----
podman rm -f racnodep1 racnodep2 rac-dnsserver racnode-storage racnodepc1-cman 
#----Cleanup Files and Folders--
rm -rf /opt/containers /opt/.secrets
export ORACLE_DBNAME=ORCLCDB
rm -rf /scratch/stage/rac-storage/ORCLCDB/asm_disk0*
#----Cleanup Docker Volumes---
podman volume -f racstorage
#----Cleanup Docker Networks--
podman network rm -f rac_pub1_nw rac_priv1_nw
#----Cleanup Docker Images--
podman rmi -f localhost/oracle/rac-dnsserver:latest localhost/oracle/rac-storage-server:latest localhost/oracle/database-rac:21.3.0-21.13.0 localhost/oracle/client-cman:21.3.0
```

## Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.