# Example of creating an Oracle RAC database with Podman Compose

Once you have built your Oracle RAC container image, you can create a Oracle RAC database with Podman Compose on Single Host via Bridge Network as example given below.

- [Example of creating an Oracle RAC database with Podman Compose](#example-of-creating-an-oracle-rac-database-with-podman-compose)
  - [Section 1 : Prerequisites for RAC Database on Podman with Podman Compose](#section-1--prerequisites-for-rac-database-on-podman-with-podman-compose)
  - [Section 2 : Preparing Environment Variables](#section-2--preparing-environment-variables)
    - [Section 2.1: Preparing Environment Variables for RAC with Block Devices](#section-21-preparing-environment-variables-for-rac-with-block-devices)
  - [Section 3 : Deploy the RAC Container](#section-3--deploy-the-rac-container)
    - [Section 3.1: Deploy the RAC Container with Block Devices](#section-31-deploy-the-rac-container-with-block-devices)
  - [Section 4: Add Additional Node in Existing Oracle RAC Cluster](#section-4-add-additional-node-in-existing-oracle-rac-cluster)
    - [Section 4.1: Add Additional Node in Existing Oracle RAC Cluster with Block Devices](#section-41-add-additional-node-in-existing-oracle-rac-cluster-with-block-devices)
  - [Section 5: Connect to the RAC container](#connect-to-the-rac-container)
  - [Copyright](#copyright)

## Section 1 : Prerequisites for RAC Database on Podman with Podman Compose

**IMPORTANT :** You must execute all the steps specified in this section (customized for your environment) before you proceed to the next section. Podman and Podman Compose is not supported with OL7. You need OL8.8 with UEK R7.

- Create DNS podman image and container, if you are planing to use DNS container for testing. Please refer [DNS Container README.MD](../../../OracleDNSServer/README.md). You can skip this step if you are planing to use **your own DNS Server**.
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
export DNS_CONTAINER_NAME=racdns
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIX="racnode"
export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_PUBLIC_IP=172.16.1.25
export RACNODE1_CONTAINER_NAME=racnode1
export RACNODE1_HOST_NAME=racnode1
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE1_NODE_VIP=172.16.1.160
export RACNODE1_VIP_HOSTNAME="racnode1-vip"
export RACNODE1_PRIV_IP=192.168.17.150
export RACNODE1_PRIV_HOSTNAME="racnode1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.150
export RACNODE1_PUBLIC_HOSTNAME="racnode1"
export DEFAULT_GATEWAY="172.16.1.1"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export INSTALL_NODE=racnode1
export SCAN_NAME="racnode-scan"
export SCAN_IP=172.16.1.70
export ASM_DISCOVERY_DIR="/dev/"
export PWD_KEY="pwd.key"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ORACLE_SID="ORCLCDB"
export CMAN_HOSTNAME="racnode-cman1"
export CMAN_IP=172.16.1.15
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export CMAN_CONTAINER_NAME=racnode-cman
export CMAN_HOST_NAME=racnode-cman1
export CMAN_IMAGE_NAME="oracle/client-cman:21.3.0"
export CMAN_PUBLIC_IP=172.16.1.15
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnode-cman1"
```

## Section 3 : Deploy the RAC Container

Refer [Section 5.1 : Prerequisites for Running Oracle RAC on Podman](../../../OracleRealApplicationClusters/README.md) to complete the pre-requisite steps for Oracle RAC on Podman.

All containers will share a host file for name resolution.  The shared hostfile must be available to all container. Create the shared host file (if it doesn't exist) at `/opt/containers/rac_host_file`:

For example:

```bash
# mkdir /opt/containers
# touch /opt/containers/rac_host_file
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
# dd if=/dev/zero of=/dev/xvde  bs=8k count=100000
```

Repeat for each shared block device. In the example above, `/dev/xvde` is a shared Xen virtual block device.

### Section 3.1: Deploy the RAC Container with Block Devices

Once pre-requisites and above necessary variables are exported, copy `podman-compose.yml` file from [this location](./samples/racpodmancompose/compose-files/blockdevices/)

After copying compose file, you can bring up DNS Container, RAC Container and CMAN container in order by following below commands-
```bash
#---------Bring up DNS------------
podman-compose up -d ${DNS_CONTAINER_NAME}

01-21-2024 18:03:46 UTC : : ################################################
01-21-2024 18:03:46 UTC : : DNS Server IS READY TO USE!
01-21-2024 18:03:46 UTC : : ################################################
```

```bash
#-----Bring up racnode1----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up --no-deps -d ${RACNODE1_CONTAINER_NAME}
podman-compose stop ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE1_PRIV_IP} ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE1_CONTAINER_NAME}

podman-compose logs -f ${RACNODE1_CONTAINER_NAME}
racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
racnode1  | 01-19-2024 16:34:24 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
racnode1  | 01-19-2024 16:34:24 UTC :  : ####################################
```

```bash
#-----Bring up CMAN----------
podman-compose up --no-deps -d ${CMAN_CONTAINER_NAME}

podman-compose logs ${CMAN_CONTAINER_NAME}
01-21-2024 17:32:55 UTC :  : ################################################
01-21-2024 17:32:55 UTC :  :  CONNECTION MANAGER IS READY TO USE!           
01-21-2024 17:32:55 UTC :  : ################################################
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
export INSTALL_NODE=racnode1
export SCAN_NAME="racnode-scan"
export SCAN_IP=172.16.1.70
export ASM_DISCOVERY_DIR="/dev/"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export RACNODE2_CONTAINER_NAME=racnode2
export RACNODE2_HOST_NAME=racnode2
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE2_NODE_VIP=172.16.1.161
export RACNODE2_VIP_HOSTNAME="racnode2-vip"
export RACNODE2_PRIV_IP=192.168.17.151
export RACNODE2_PRIV_HOSTNAME="racnode2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.151
export RACNODE2_PUBLIC_HOSTNAME="racnode2"
export ORACLE_DBNAME="ORCLCDB"
```
Once necessary variables are exported, copy `podman-compose-additional.yml` file from [this location](./samples/racpodmancompose/compose-files/blockdevices/) and rename it as `podman-compose.yml`

After copying compose file, you can bring up additional RAC Container by following below commands-

```bash
#-----Bring up racnode2----------
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up --no-deps -d ${RACNODE2_CONTAINER_NAME}
podman-compose stop ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE_NETWORK_NAME} --ip ${RACNODE2_PRIV_IP} ${RACNODE2_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}

podman-compose logs -f ${RACNODE2_CONTAINER_NAME}
01-21-2024 18:41:55 UTC :  : ####################################
01-21-2024 18:41:55 UTC :  : ORACLE RAC DATABASE IS READY TO USE!
01-21-2024 18:41:55 UTC :  : ####################################
```

#### Connect to the RAC container

To connect to the container execute following command:

```bash
# podman exec -i -t racnode1 /bin/bash
```

If the install fails for any reason, log in to container using the above command and check `/tmp/orod.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.


## Copyright

Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.