# Example of creating an Oracle RAC database with Docker Compose

Once you have built your Oracle RAC container image, you can create a Oracle RAC database with Docker Compose on Single Host via Bridge Network as example given below.

- [Example of creating an Oracle RAC database with Docker Compose](#example-of-creating-an-oracle-rac-database-with-docker-compose)
  - [Section 1 : Prerequisites for RAC Database on Docker with Docker Compose](#section-1--prerequisites-for-rac-database-on-docker-with-docker-compose)
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

## Section 1 : Prerequisites for RAC Database on Docker with Docker Compose

**IMPORTANT :** You must execute all the steps specified in this section (customized for your environment) before you proceed to the next section. Docker and Docker Compose is not supported with OL8. You need OL7.9 with UEK R5 or above. This guide and example is mainly for development and testing purposes only.

- It is assumed that before proceeding further you have executed the pre-requisites from [Section 1 : Prerequisites for running Oracle RAC in containers](../../../OracleRealApplicationClusters/README.md)  and [Section 4.1 : Prerequisites for Running Oracle RAC on Docker](../../../OracleRealApplicationClusters/README.md) for Single Docker Host Machine .
- Create DNS docker image, if you are planing to use DNS container for testing. Please refer [DNS Container README.MD](../../../OracleDNSServer/README.md). You can skip this step if you are planing to use **your own DNS Server**.
- Create Oracle Connection Manager Docker image.Please refer [RAC Oracle Connection Manager README.MD](../../../OracleConnectionManager/README.md) for details.
- Create Storage Server Docker image, if you are planning to use NFS Storage Devices provided in this guide.Please refer [How to build NFS Storage Container Image](../../../OracleRACStorageServer/README.md) for details.

- If you have not built the Oracle RAC container image, execute the steps in [Section 2: Building Oracle RAC Database Container Images](../../../OracleRealApplicationClusters/README.md) based on your environment.

In order to setup RAC on Docker with Docker Compose, latest `docker compose` binary is required from [respective website](https://github.com/docker/compose/releases). This is example of how to install `docker compose` executable v2.23.1 from github-
```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
ls -lrt $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.23.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
ls -lrt $DOCKER_CONFIG/cli-plugins
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

## Section 2 : Preparing Environment Variables

### Section 2.1: Preparing Environment Variables for RAC with Block Devices

In order to setup Oracle RAC on Docker with Block Devices with Docker Compose, first lets identify necessary variables to export that will be used by `docker-compose.yml` file later. Below is one example of exporting necessary variables related to docker network, DNS container, RAC Container and CMAN container discussed in this repo.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIXD="racnoded"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_pzriv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export DNS_PRIVATE_IP=192.168.17.25
export INSTALL_NODE=racnoded1
export SCAN_NAME="racnodedc1-scan"
export SCAN_IP=172.16.1.230
export ASM_DISCOVERY_DIR="/dev/"
export PWD_KEY="pwd.key"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export RACNODE1_CONTAINER_NAME=racnoded1
export RACNODE1_HOST_NAME=racnoded1
export RACNODE_IMAGE_NAME="oracle/database-rac:19.3.0"
export RACNODE1_NODE_VIP=172.16.1.130
export RACNODE1_VIP_HOSTNAME="racnoded1-vip"
export RACNODE1_PRIV_IP=192.168.17.100
export RACNODE1_PRIV_HOSTNAME="racnoded1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.100
export RACNODE1_PUBLIC_HOSTNAME="racnoded1"
export CMAN_CONTAINER_NAME=racnodedc1-cman
export CMAN_IMAGE_NAME="oracle/client-cman:19.3.0"
export DNS_DOMAIN="example.com"
export CMAN_PUBLIC_IP=172.16.1.164
export CMAN_HOSTNAME="racnodedc1-cman"
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnodec1-cman"
export CMAN_VERSION="19.3.0"
export ORACLE_HOME=/u01/app/oracle/product/${CMAN_VERSION}/client_1
```

### Section 2.2: Preparing Environment Variables for RAC with NFS Storage Devices

In order to setup Oracle RAC on Docker with Oracle RAC Storage Container with Docker Compose, lets first make sure `nfs-utils` rpm package is installed in Docker Host machine.
```bash
yum -y install nfs-utils
```

Lets identify necessary variables to export that will be used by `docker-compose.yml` file later. Below is one example of exporting necessary variables related to docker network, DNS container, Storage Container, RAC Container and CMAN container discussed in this guide. Change as per your requirements.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIXD="racnoded"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_pzriv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export DNS_PRIVATE_IP=192.168.17.25
export INSTALL_NODE=racnoded1
export SCAN_NAME="racnodedc1-scan"
export SCAN_IP=172.16.1.230
export PWD_KEY="pwd.key"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export RACNODE1_CONTAINER_NAME=racnoded1
export RACNODE1_HOST_NAME=racnoded1
export RACNODE_IMAGE_NAME="oracle/database-rac:19.3.0"
export RACNODE1_NODE_VIP=172.16.1.130
export RACNODE1_VIP_HOSTNAME="racnoded1-vip"
export RACNODE1_PRIV_IP=192.168.17.100
export RACNODE1_PRIV_HOSTNAME="racnoded1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.100
export RACNODE1_PUBLIC_HOSTNAME="racnoded1"
export CMAN_CONTAINER_NAME=racnodedc1-cman
export CMAN_PUBLIC_IP=172.16.1.164
export CMAN_HOSTNAME="racnodedc1-cman"
export CMAN_IMAGE_NAME="oracle/client-cman:19.3.0"
export DNS_DOMAIN="example.com"
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnodec1-cman"
export CMAN_VERSION="19.3.0"
export ORACLE_HOME=/u01/app/oracle/product/${CMAN_VERSION}/client_1
export ASM_DISCOVERY_DIR="/oradata"
export ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export STORAGE_CONTAINER_NAME="racnode-storage"
export STORAGE_HOST_NAME="racnode-storage"
export STORAGE_IMAGE_NAME="oracle/rac-storage-server:19.3.0"
export ORACLE_DBNAME="ORCLCDB"
export STORAGE_PRIVATE_IP=192.168.17.80
export NFS_STORAGE_VOLUME="/docker_volumes/asm_vol/$ORACLE_DBNAME"
```
## Section 3 : Deploy the RAC Container

Refer [Section 4.1 : Prerequisites for Running Oracle RAC on Docker](../../../OracleRealApplicationClusters/README.md) to complete the pre-requisite steps for Oracle RAC on Docker.

All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```bash
mkdir /opt/containers
touch /opt/containers/rac_host_file
```

**Note:** Do not modify `/opt/containers/rac_host_file` from docker host. It will be managed from within the containers.

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

If you are using an NFS volume, skip to the section below "Deploying RAC on Docker with NFS Volume".

Make sure the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

### Section 3.1: Deploy the RAC Container with Block Devices

Once pre-requisites and above necessary variables are exported, copy `docker-compose.yml` file from [this location](./compose-files/blockdevices/docker-compose.yml) and `cd` to same directory where you have copied `docker-compose` file before running `docker compose` commands.

After copying compose file, you can bring up DNS Container, RAC Container and CMAN container in order by following below commands-
```bash
#---------Bring up DNS------------
docker compose up -d ${DNS_CONTAINER_NAME} && docker compose stop ${DNS_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${DNS_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${DNS_PRIVATE_IP} ${DNS_CONTAINER_NAME}
docker compose start ${DNS_CONTAINER_NAME}
docker compose logs ${DNS_CONTAINER_NAME} 

rac-dnsserver  | 01-30-2024 10:51:51 UTC :  : DNS Server started successfully
rac-dnsserver  | 01-30-2024 10:51:51 UTC :  : ################################################
rac-dnsserver  | 01-30-2024 10:51:51 UTC :  :  DNS Server IS READY TO USE!            
rac-dnsserver  | 01-30-2024 10:51:51 UTC :  : ################################################
rac-dnsserver  | 01-30-2024 10:51:51 UTC :  : DNS Server Started Successfully
```

```bash
#-----Bring up racnode1----------
docker compose up -d ${RACNODE1_CONTAINER_NAME} && docker compose stop ${RACNODE1_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE1_PRIV_IP} ${RACNODE1_CONTAINER_NAME}
docker compose start ${RACNODE1_CONTAINER_NAME}
docker compose logs -f ${RACNODE1_CONTAINER_NAME}

racnoded1  | 01-31-2024 09:09:56 UTC :  : #################################################################
racnoded1  | 01-31-2024 09:09:56 UTC :  :  Oracle Database ORCLCDB is up and running on racnoded1    
racnoded1  | 01-31-2024 09:09:56 UTC :  : #################################################################
racnoded1  | 01-31-2024 09:09:56 UTC :  : Running User Script oracle user
racnoded1  | 01-31-2024 09:09:56 UTC :  : Setting Remote Listener
racnoded1  | 01-31-2024 09:09:56 UTC :  : 172.16.1.164
racnoded1  | 01-31-2024 09:09:56 UTC :  : Executing script to set the remote listener
racnoded1  | 01-31-2024 09:09:58 UTC :  : ####################################
racnoded1  | 01-31-2024 09:09:58 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnoded1  | 01-31-2024 09:09:58 UTC :  : ####################################
```

```bash
#-----Bring up CMAN----------
docker compose up -d ${CMAN_CONTAINER_NAME}
docker compose logs -f ${CMAN_CONTAINER_NAME}

racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : cman started sucessfully
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : ################################################
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  :  CONNECTION MANAGER IS READY TO USE!            
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : ################################################
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : cman started sucessfully
```

Note: Docker compose currently doesn't supports assigning multiple network IP address via compose file. Due to this limitation, above commands are specificically assigning required public and private networks to DNS and RAC container while stopping it in between. Also, above example is specific to bridge networks on a Single Docker Host.

In case, of MCVLAN or IPVLAN networks, you may want to edit `docker-compose.yml` file are per your needs and respective environment variables.

### Section 3.2: Deploy the RAC Container with NFS Storage Devices

Once pre-requisites for NFS Storage Devices and above necessary variables are exported, copy `docker-compose.yml` file from [this location](./compose-files/nfsdevices/docker-compose.yml) and `cd` to same directory where you have copied `docker-compose.yml` file before running `docker compose` commands.

Create placeholder for NFS storage and make sure it is empty -
```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /docker_volumes/asm_vol/$ORACLE_DBNAME
rm -rf /docker_volumes/asm_vol/$ORACLE_DBNAME/asm_disk0*
```

```bash
#-----Create docker volume---
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.17.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
  --opt device=192.168.17.80:/oradata \
  racstorage
```

After copying compose file, you can bring up DNS Container, Storage Container, RAC Container and CMAN container by following below commands-
```bash
#---------Bring up DNS------------
docker compose up -d ${DNS_CONTAINER_NAME} && docker compose stop ${DNS_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${DNS_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${DNS_PRIVATE_IP} ${DNS_CONTAINER_NAME}
docker compose start ${DNS_CONTAINER_NAME}
docker compose logs ${DNS_CONTAINER_NAME} 

rac-dnsserver  | 01-31-2024 07:22:06 UTC :  : DNS Server started successfully
rac-dnsserver  | 01-31-2024 07:22:06 UTC :  : ################################################
rac-dnsserver  | 01-31-2024 07:22:06 UTC :  :  DNS Server IS READY TO USE!            
rac-dnsserver  | 01-31-2024 07:22:06 UTC :  : ################################################
rac-dnsserver  | 01-31-2024 07:22:06 UTC :  : DNS Server Started Successfully
```

```bash
#----- Bring up Storage Container-----
docker compose up -d ${STORAGE_CONTAINER_NAME}
docker compose logs -f ${STORAGE_CONTAINER_NAME}

racnode-storage  | ####################################################
racnode-storage  |  NFS Server is up and running                      
racnode-storage  |  Create NFS volume for /oradata/        
racnode-storage  | ####################################################
```

```bash
#-----Bring up racnode1----------
docker compose up -d ${RACNODE1_CONTAINER_NAME} && docker compose stop ${RACNODE1_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE1_PRIV_IP} ${RACNODE1_CONTAINER_NAME}
docker compose start ${RACNODE1_CONTAINER_NAME}

docker compose logs -f ${RACNODE1_CONTAINER_NAME}
racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
racnode1  | 01-19-2024 16:34:24 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
```

```bash
#-----Bring up CMAN----------
docker compose up -d ${CMAN_CONTAINER_NAME}
docker compose logs -f ${CMAN_CONTAINER_NAME}

racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : cman started sucessfully
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : ################################################
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  :  CONNECTION MANAGER IS READY TO USE!            
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : ################################################
racnodedc1-cman  | 01-31-2024 10:35:00 UTC :  : cman started sucessfully
```

Note: Docker compose currently doesn't supports assigning multiple network IP address via compose file. Due to this limitation, above commands are specificically assigning required public and private networks to RAC container while stopping it in between. Also, above example is specific to bridge networks.

In case, of MCVLAN or IPVLAN networks, you may want to edit `docker-compose.yml` file are per your needs and respective environment variables.

## Section 4: Add Additional Node in Existing Oracle RAC Cluster

### Section 4.1: Add Additional Node in Existing Oracle RAC Cluster with Block Devices
In order to add additional node in existing Oracle RAC on Docker with Block Devices with Docker Compose, first lets identify necessary variables to export that will be used by `docker-compose.yml` file later. Below is one example of exporting necessary variables related to additional RAC Container with Block Devices. Change these as per your environment.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_HOST_NAME=rac-dnsserver
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_pzriv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export INSTALL_NODE=racnoded1
export SCAN_NAME="racnodedc1-scan"
export SCAN_IP=172.16.1.230
export ASM_DISCOVERY_DIR="/dev/"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export RACNODE2_CONTAINER_NAME=racnoded2
export RACNODE2_HOST_NAME=racnoded2
export RACNODE_IMAGE_NAME="oracle/database-rac:19.3.0"
export RACNODE2_NODE_VIP=172.16.1.131
export RACNODE2_VIP_HOSTNAME="racnoded2-vip"
export RACNODE2_PRIV_IP=192.168.17.101
export RACNODE2_PRIV_HOSTNAME="racnoded2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.101
export RACNODE2_PUBLIC_HOSTNAME="racnoded2"
export ORACLE_DBNAME="ORCLCDB"
```
Once necessary variables are exported, copy `docker-compose-addition.yml` file from [this location](./compose-files/blockdevices/docker-compose-addition.yml) and rename it as `docker-compose.yml`

After copying compose file, you can bring up additional RAC Container by following below commands-

```bash
#-----Bring up racnode2----------
docker compose up -d ${RACNODE2_CONTAINER_NAME} && docker compose stop ${RACNODE2_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE2_PRIV_IP} ${RACNODE2_CONTAINER_NAME}
docker compose start ${RACNODE2_CONTAINER_NAME}
docker compose logs -f ${RACNODE2_CONTAINER_NAME}

racnoded2  | 01-30-2024 13:34:52 UTC :  : #################################################################
racnoded2  | 01-30-2024 13:34:52 UTC :  :  Oracle Database ORCLCDB is up and running on racnoded2    
racnoded2  | 01-30-2024 13:34:52 UTC :  : #################################################################
racnoded2  | 01-30-2024 13:34:52 UTC :  : Running User Script for  oracle user
racnoded2  | 01-30-2024 13:34:52 UTC :  : Setting Remote Listener
racnoded2  | 01-30-2024 13:34:52 UTC :  : ####################################
racnoded2  | 01-30-2024 13:34:52 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnoded2  | 01-30-2024 13:34:52 UTC :  : ####################################
```

### Section 4.2: Add Additional Node in Existing Oracle RAC Cluster with NFS Volume

In order to add additional node in existing Oracle RAC on Docker with NFS Storage Devices with Docker Compose, first lets identify necessary variables to export that will be used by `docker-compose.yml` file later. Below is one example of exporting necessary variables related to additional RAC Container with NFS Storage.
```bash
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_HOST_NAME=rac-dnsserver
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_pzriv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export DNS_PUBLIC_IP=172.16.1.25
export INSTALL_NODE=racnoded1
export SCAN_NAME="racnodedc1-scan"
export SCAN_IP=172.16.1.230
export ASM_DISCOVERY_DIR="/oradata"
export ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export RACNODE2_CONTAINER_NAME=racnoded2
export RACNODE2_HOST_NAME=racnoded2
export RACNODE_IMAGE_NAME="oracle/database-rac:19.3.0"
export RACNODE2_NODE_VIP=172.16.1.131
export RACNODE2_VIP_HOSTNAME="racnoded2-vip"
export RACNODE2_PRIV_IP=192.168.17.101
export RACNODE2_PRIV_HOSTNAME="racnoded2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.101
export RACNODE2_PUBLIC_HOSTNAME="racnoded2"
export ORACLE_DBNAME="ORCLCDB"
```
Once necessary variables are exported, copy `docker-compose-addition.yml` file from [this location](./compose-files/nfsdevices/docker-compose-addition.yml) and rename it as `docker-compose.yml`


After copying compose file, you can bring up additional RAC Container by following below commands-

```bash
#-----Bring up racnode2----------
docker compose up -d ${RACNODE2_CONTAINER_NAME} && docker compose stop ${RACNODE2_CONTAINER_NAME}
docker network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
docker network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
docker network connect ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
docker network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE2_PRIV_IP} ${RACNODE2_CONTAINER_NAME}
docker compose start ${RACNODE2_CONTAINER_NAME}
docker compose logs -f ${RACNODE2_CONTAINER_NAME}

racnoded2  | 01-31-2024 10:45:54 UTC :  : #################################################################
racnoded2  | 01-31-2024 10:45:54 UTC :  :  Oracle Database ORCLCDB is up and running on racnoded2    
racnoded2  | 01-31-2024 10:45:54 UTC :  : #################################################################
racnoded2  | 01-31-2024 10:45:54 UTC :  : Running User Script for  oracle user
racnoded2  | 01-31-2024 10:45:54 UTC :  : Setting Remote Listener
racnoded2  | 01-31-2024 10:45:54 UTC :  : ####################################
racnoded2  | 01-31-2024 10:45:54 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnoded2  | 01-31-2024 10:45:54 UTC :  : ####################################
```


#### Connect to the RAC container

To connect to the container execute following command:

```bash
docker exec -i -t racnoded1 /bin/bash
```

If the install fails for any reason, log in to container using the above command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.

## Cleanup RAC Environment
Below commands can be executed to cleanup above RAC Environment -

### Cleanup RAC based on Block Devices
```bash
#----Cleanup RAC Containers-----
docker rm -f racnoded1 racnoded2 rac-dnsserver racnodedc1-cman 
#----Cleanup Disks--------------
dd if=/dev/zero of=/dev/oracleoci/oraclevde  bs=8k count=10000 status=progress && dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000 status=progress
#----Cleanup Files and Folders--
rm -rf /opt/containers /opt/.secrets
#----Cleanup Docker Networks--
docker network rm -f rac_pub1_nw rac_pzriv1_nw
#----Cleanup Docker Images--
docker rmi -f oracle/rac-dnsserver:latest oracle/database-rac:19.3.0 oracle/client-cman:19.3.0
```

### Cleanup RAC based on NFS Storage Devices
```bash
#----Cleanup RAC Containers-----
docker rm -f racnoded1 racnoded2 rac-dnsserver racnode-storage racnodedc1-cman 
#----Cleanup Files and Folders--
rm -rf /opt/containers /opt/.secrets
export ORACLE_DBNAME=ORCLCDB
rm -rf /docker_volumes/asm_vol/$ORACLE_DBNAME/asm_disk0*
#----Cleanup Docker Volumes---
docker volume -f racstorage
#----Cleanup Docker Networks--
docker network rm -f rac_pub1_nw rac_pzriv1_nw
#----Cleanup Docker Images--
docker rmi -f oracle/rac-dnsserver:latest oracle/rac-storage-server:19.3.0 oracle/database-rac:19.3.0 oracle/client-cman:19.3.0
```

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates. All rights reserved.