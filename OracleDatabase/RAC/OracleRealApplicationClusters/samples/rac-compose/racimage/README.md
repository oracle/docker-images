# Oracle RAC on Podman Compose using Oracle RAC Image
===============================================================

Refer below instructions for setup of Oracle RAC on Podman using Oracle RAC Image for various scenarios.

- [Oracle RAC on Podman Compose using Oracle RAC Image](#oracle-rac-on-podman-compose-using-oracle-rac-image)
  - [Section 1 : Prerequisites for Setting up Oracle RAC on Container using Oracle RAC Image](#section-1-prerequisites-for-setting-up-oracle-rac-on-container-using-oracle-rac-image)
  - [Section 2: Setup Oracle RAC Containers with Oracle RAC Image using Podman Compose Files](#section-2-setup-oracle-rac-containers-with-oracle-rac-image-using-podman-compose-files)
    - [Section 2.1: Deploying With BlockDevices](#section-21-deploying-with-blockdevices)
      - [Section 2.1.1: Setup Without Using User Defined Response files](#section-211-setup-without-using-user-defined-response-files)
      - [Section 2.1.2: Setup Using User Defined Response files](#section-212-setup-using-user-defined-response-files)
    - [Section 2.2: Deploying With NFS Storage Devices](#section-22-deploying-with-nfs-storage-devices)
      - [Section 2.2.1: Setup Without Using User Defined Response files](#section-221-setup-without-using-user-defined-response-files)
      - [Section 2.2.2: Setup Using User Defined Response files](#section-222-setup-using-user-defined-response-files)
  - [Section 3: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Image](#section-3-sample-of-addition-of-nodes-to-oracle-rac-containers-based-on-oracle-rac-image)
    - [Section 3.1: Sample of Addition of Nodes to Oracle RAC Containers using Podman Compose based on Oracle RAC Image with BlockDevices](#section-31-sample-of-addition-of-nodes-to-oracle-rac-containers-using-podman-compose-based-on-oracle-rac-image-with-blockdevices)
    - [Section 3.2: Sample of Addition of Nodes to Oracle RAC Containers using Podman Compose based on Oracle RAC Image with NFS Storage Devices](#section-32-sample-of-addition-of-nodes-to-oracle-rac-containers-using-podman-compose-based-on-oracle-rac-image-with-nfs-storage-devices)
  - [Section 4: Environment Variables for Oracle RAC on Podman Compose](#section-4-environment-variables-for-oracle-rac-on-podman-compose)
  - [Section 5: Validating Oracle RAC Environment](#section-5-validating-oracle-rac-environment)
  - [Section 6: Connecting to Oracle RAC Environment](#section-6-connecting-to-oracle-rac-environment)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Oracle RAC Setup on Podman Compose using Oracle RAC Image

You can deploy multi node Oracle RAC Setup using Oracle RAC Image either on Block Devices or NFS storage Devices by using User Defined Response Files or without using same. All these scenarios are discussed in detail as you proceed further below.

## Section 1: Prerequisites for Setting up Oracle RAC on Container using Oracle RAC Image
**IMPORTANT :** Execute all the steps specified in this section (customized for your environment) before you proceed to the next section. Completing prerequisite steps is a requirement for successful configuration.


* Execute the [Preparation Steps for running Oracle RAC database in containers](../../../README.md#preparation-steps-for-running-oracle-rac-database-in-containers)
* Create Oracle Connection Manager on Container image and container if the IPs are not available on user network.Please refer [RAC Oracle Connection Manager README.MD](../../../../OracleConnectionManager/README.md).
* Ensure the Oracle RAC Image is present. You can either pull ru image from the Oracle Container Registry by following [Building Oracle RAC Database Container Images](../../../README.md#getting-oracle-rac-database-container-images), or you can create the Oracle RAC Container Patched image by following [Building Oracle RAC Database Container Images](../../../README.md#building-a-patched-oracle-rac-container-image)
```bash
# podman images|grep database-rac
localhost/oracle/database-rac        21c          41239091d2ac  16 minutes ago  20.2 GB
```
* Execute the [Network](../../../README.md#network-management).
* Execute the [Password Management](../../../README.md#password-management).
* `podman-compose` is part of [ol8_developer_EPEL](https://yum.oracle.com/repo/OracleLinux/ol8/developer/EPEL/x86_64/index.html). Enable `ol8_developer_EPEL` repository and install `podman-compose` as below-
  ```bash
  sudo dnf config-manager --enable ol8_developer_EPEL
  sudo dnf install -y podman-compose
  ```
In order to setup 2 Node RAC containers using Podman compose, please make sure pre-requisites are completed before proceeding further -

## Section 2: Setup Oracle RAC Containers with Oracle RAC Image using Podman Compose Files
### Section 2.1: Deploying With BlockDevices
#### Section 2.1.1: Setup Without Using User Defined Response files
Export the required environment variables required by `podman-compose.yml` file -
```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE1_PUBLIC_IP=10.0.20.170
export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
export INSTALL_NODE=racnodep1
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
export SCAN_NAME=racnodepc1-scan
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export CRS_ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE2_PUBLIC_IP=10.0.20.171
export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXD="racnoded"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export DNS_PRIVATE1_IP=192.168.17.25
export DNS_PRIVATE2_IP=192.168.18.25
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_HOST_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="localhost/oracle/client-cman:23.5.0"
export CMAN_PUBLIC_IP=10.0.20.166
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
export DB_SERVICE=service:soepdb
```

Create compose file named [podman-compose.yml](./withoutresponsefiles/blockdevices/podman-compose.yml) in your working directory.

Create podman networks-
```bash
podman network create --driver=bridge --subnet=${PUBLIC_NETWORK_SUBNET} ${PUBLIC_NETWORK_NAME}
podman network create --driver=bridge --subnet=${PRIVATE1_NETWORK_SUBNET} ${PRIVATE1_NETWORK_NAME} --disable-dns
podman network create --driver=bridge --subnet=${PRIVATE2_NETWORK_SUBNET} ${PRIVATE2_NETWORK_NAME} --disable-dns
```

Bring up DNS Containers-
```bash
podman-compose up -d ${DNS_CONTAINER_NAME}
podman-compose logs ${DNS_CONTAINER_NAME}
```
DNS Container Logs-
```bash
podman-compose logs ${DNS_CONTAINER_NAME}
03-28-2024 07:46:59 UTC :  : ################################################
03-28-2024 07:46:59 UTC :  :  DNS Server IS READY TO USE!            
03-28-2024 07:46:59 UTC :  : ################################################

```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up  -d ${RACNODE1_CONTAINER_NAME} 
podman-compose stop ${RACNODE1_CONTAINER_NAME}

podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME}
podman-compose stop ${RACNODE2_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP1}  ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP2}  ${RACNODE1_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP1}  ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP2}  ${RACNODE2_CONTAINER_NAME}

podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
===================================
ORACLE RAC DATABASE IS READY TO USE
===================================
```

(Optionally) Bring up CMAN Container-
```bash
podman-compose up -d ${CMAN_CONTAINER_NAME}

podman-compose logs -f ${CMAN_CONTAINER_NAME}
################################################
  CONNECTION MANAGER IS READY TO USE!            
################################################
```
#### Section 2.1.2: Setup Using User Defined Response files
Make sure you completed pre-requisites step to install Podman Compose on required Podman Host Machines.

On the shared folder between both RAC nodes, copy file named [grid_setup_new_21c.rsp](withresponsefiles/nfsdevices/grid_setup_new_21c.rsp)  to shared location e.g `/scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp`.  You can skip this step if you are planing to not to use **User Defined Response Files for RAC**.

If SELinux host is enable on machine then execute the following as well -
```bash
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
```
Now, Export the required environment variables required by `podman-compose.yml` file -
```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE1_PUBLIC_IP=10.0.20.170
export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
export INSTALL_NODE=racnodep1
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
export SCAN_NAME=racnodepc1-scan
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export CRS_ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE2_PUBLIC_IP=10.0.20.171
export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export DNS_PRIVATE1_IP=192.168.17.25
export DNS_PRIVATE2_IP=192.168.18.25
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_HOST_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="localhost/oracle/client-cman:23.5.0"
export CMAN_PUBLIC_IP=10.0.20.166
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
export GRID_RESPONSE_FILE="/scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp"
export DB_SERVICE=service:soepdb
```
Create podman networks-
```bash
podman network create --driver=bridge --subnet=${PUBLIC_NETWORK_SUBNET} ${PUBLIC_NETWORK_NAME}
podman network create --driver=bridge --subnet=${PRIVATE1_NETWORK_SUBNET} ${PRIVATE1_NETWORK_NAME} --disable-dns
podman network create --driver=bridge --subnet=${PRIVATE2_NETWORK_SUBNET} ${PRIVATE2_NETWORK_NAME} --disable-dns
```

Create compose file named [podman-compose.yml](./withresponsefiles/blockdevices/podman-compose.yml) in your working directory.

Bring up DNS Containers-
```bash
podman-compose up -d ${DNS_CONTAINER_NAME}
podman-compose stop ${DNS_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
podman-compose start ${DNS_CONTAINER_NAME}
```

Successful logs when DNS container comes up-
```bash
podman-compose logs ${DNS_CONTAINER_NAME}
################################################
 DNS Server IS READY TO USE!            
################################################
```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE1_CONTAINER_NAME} 
podman-compose stop ${RACNODE1_CONTAINER_NAME}

podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME}
podman-compose stop ${RACNODE2_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP1}  ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP2}  ${RACNODE1_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP1}  ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP2}  ${RACNODE2_CONTAINER_NAME}

podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
===================================
ORACLE RAC DATABASE IS READY TO USE
===================================
```

Bring up CMAN Container-
```bash
podman-compose up -d ${CMAN_CONTAINER_NAME}

podman-compose logs -f ${CMAN_CONTAINER_NAME}
################################################
  CONNECTION MANAGER IS READY TO USE!            
################################################
```

### Section 2.2: Deploying With NFS Storage Devices
#### Section 2.2.1: Setup Without Using User Defined Response files
Make sure you completed pre-requisites step to install Podman Compose on required Podman Host Machines.

Create placeholder for NFS storage and make sure it is empty -

```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /scratch/stage/rac-storage/$ORACLE_DBNAME
rm -rf /scratch/stage/rac-storage/ORCLCDB/asm_disk0*
```

Now, Export the required environment variables required by `podman-compose.yml` file -

```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE1_PUBLIC_IP=10.0.20.170
export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
export INSTALL_NODE=racnodep1
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
export SCAN_NAME=racnodepc1-scan
export CRS_ASM_DISCOVERY_STRING="/oradata"
export CRS_ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE2_PUBLIC_IP=10.0.20.171
export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export DNS_PRIVATE1_IP=192.168.17.25
export DNS_PRIVATE2_IP=192.168.18.25
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_HOST_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="localhost/oracle/client-cman:23.5.0"
export CMAN_PUBLIC_IP=10.0.20.166
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
export STORAGE_CONTAINER_NAME="racnode-storage"
export STORAGE_HOST_NAME="racnode-storage"
export STORAGE_IMAGE_NAME="localhost/oracle/rac-storage-server:latest"
export ORACLE_DBNAME="ORCLCDB"
export STORAGE_PUBLIC_IP=10.0.20.80
export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
export DB_SERVICE=service:soepdb
```
Create podman networks-
```bash
podman network create --driver=bridge --subnet=${PUBLIC_NETWORK_SUBNET} ${PUBLIC_NETWORK_NAME}
podman network create --driver=bridge --subnet=${PRIVATE1_NETWORK_SUBNET} ${PRIVATE1_NETWORK_NAME} --disable-dns
podman network create --driver=bridge --subnet=${PRIVATE2_NETWORK_SUBNET} ${PRIVATE2_NETWORK_NAME} --disable-dns
```

Create compose file named [podman-compose.yml](./withoutresponsefiles/nfsdevices/podman-compose.yml) in your working directory.


Bring up DNS Containers-
```bash
podman-compose up -d ${DNS_CONTAINER_NAME}
podman-compose logs ${DNS_CONTAINER_NAME}
```
Logs-
```bash
04-03-2024 13:22:54 UTC :  : ################################################
04-03-2024 13:22:54 UTC :  :  DNS Server IS READY TO USE!            
04-03-2024 13:22:54 UTC :  : #####################################
```

Bring up Storage Container-
```bash
podman-compose --podman-run-args="-t -i --systemd=always" up -d ${STORAGE_CONTAINER_NAME}
podman-compose exec ${STORAGE_CONTAINER_NAME} tail -f /tmp/storage_setup.log
```
Logs-
```bash
Export list for racnode-storage:
/oradata *
#################################################
 Setup Completed                                 
#################################################
```

Create NFS volume-
```bash
podman volume create --driver local \
--opt type=nfs \
--opt   o=addr=10.0.20.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=10.0.20.80:/oradata \
racstorage
```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up  -d ${RACNODE1_CONTAINER_NAME} 
podman-compose stop ${RACNODE1_CONTAINER_NAME}

podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME}
podman-compose stop ${RACNODE2_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP1}  ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP2}  ${RACNODE1_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP1}  ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP2}  ${RACNODE2_CONTAINER_NAME}

podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
===================================
ORACLE RAC DATABASE IS READY TO USE
===================================
```

(Optionally) Bring up CMAN Container-
```bash
podman-compose up -d ${CMAN_CONTAINER_NAME}

podman-compose logs -f ${CMAN_CONTAINER_NAME}
################################################
  CONNECTION MANAGER IS READY TO USE!            
################################################
```
#### Section 2.2.2: Setup Using User Defined Response files
Make sure you completed pre-requisites step to install Podman Compose on required Podman Host Machines.

If SELinux  is enabled in your host machine then execute the following as well -
```bash
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
```
Create placeholder for NFS storage and make sure it is empty -

```bash
export ORACLE_DBNAME=ORCLCDB
mkdir -p /scratch/stage/rac-storage/$ORACLE_DBNAME
rm -rf /scratch/stage/rac-storage/ORCLCDB/asm_disk0*
```

On the shared folder between both RAC nodes, copy file name [grid_setup_new_21c.rsp](withresponsefiles/nfsdevices/grid_setup_new_21c.rsp) to shared location e.g `/scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp`. You can skip this step if you are planing to not to use **User Defined Response Files for RAC**.
If SELinux host is enable on machine then execute the following as well -
```bash
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp
semanage fcontext -a -t container_file_t /scratch/common_scripts/podman/rac/dbca_21c.rsp
restorecon -v /scratch/common_scripts/podman/rac/dbca_21c.rsp
```
Now, Export the required environment variables required by `podman-compose.yml` file -
```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE1_PUBLIC_IP=10.0.20.170
export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
export INSTALL_NODE=racnodep1
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
export SCAN_NAME=racnodepc1-scan
export CRS_ASM_DISCOVERY_STRING="/oradata"
export CRS_ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE2_PUBLIC_IP=10.0.20.171
export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export DNS_PRIVATE1_IP=192.168.17.25
export DNS_PRIVATE2_IP=192.168.18.25
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_HOST_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="localhost/oracle/client-cman:23.5.0"
export CMAN_PUBLIC_IP=10.0.20.166
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
export STORAGE_CONTAINER_NAME="racnode-storage"
export STORAGE_HOST_NAME="racnode-storage"
export STORAGE_IMAGE_NAME="localhost/oracle/rac-storage-server:latest"
export ORACLE_DBNAME="ORCLCDB"
export STORAGE_PUBLIC_IP=10.0.20.80
export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
export GRID_RESPONSE_FILE="/scratch/common_scripts/podman/rac/grid_setup_new_21c.rsp"
export DB_SERVICE=service:soepdb
```

Create podman networks-
```bash
podman network create --driver=bridge --subnet=${PUBLIC_NETWORK_SUBNET} ${PUBLIC_NETWORK_NAME}
podman network create --driver=bridge --subnet=${PRIVATE1_NETWORK_SUBNET} ${PRIVATE1_NETWORK_NAME} --disable-dns
podman network create --driver=bridge --subnet=${PRIVATE2_NETWORK_SUBNET} ${PRIVATE2_NETWORK_NAME} --disable-dns
```

Create compose file named [podman-compose.yml](./withresponsefiles/nfsdevices/podman-compose.yml) in your working directory.  

Bring up DNS Containers-
```bash
podman-compose up -d ${DNS_CONTAINER_NAME}
podman-compose stop ${DNS_CONTAINER_NAME}
podman network disconnect ${PUBLIC_NETWORK_NAME} ${DNS_CONTAINER_NAME}
podman network connect ${PUBLIC_NETWORK_NAME} --ip ${DNS_PUBLIC_IP} ${DNS_CONTAINER_NAME}
podman-compose start ${DNS_CONTAINER_NAME}
```

Successful logs when DNS container comes up-
```bash
podman-compose logs ${DNS_CONTAINER_NAME}
################################################
 DNS Server IS READY TO USE!            
################################################
```

Bring up Storage Container-
```bash
podman-compose --podman-run-args="-t -i --systemd=always" up -d ${STORAGE_CONTAINER_NAME}
podman-compose exec ${STORAGE_CONTAINER_NAME} tail -f /tmp/storage_setup.log

Export list for racnode-storage:
/oradata *
#################################################
 Setup Completed                                 
#################################################
```

Create NFS volume-
```bash
podman volume create --driver local \
--opt type=nfs \
--opt   o=addr=10.0.20.80,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=10.0.20.80:/oradata \
racstorage
```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE1_CONTAINER_NAME} 
podman-compose stop ${RACNODE1_CONTAINER_NAME}

podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME}
podman-compose stop ${RACNODE2_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP1}  ${RACNODE1_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP2}  ${RACNODE1_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP1}  ${RACNODE2_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP2}  ${RACNODE2_CONTAINER_NAME}

podman-compose start ${RACNODE1_CONTAINER_NAME}
podman-compose start ${RACNODE2_CONTAINER_NAME}
podman exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
===================================
ORACLE RAC DATABASE IS READY TO USE
===================================
```

(Optionally) Bring up CMAN Container-
```bash
podman-compose up -d ${CMAN_CONTAINER_NAME}
podman-compose logs -f ${CMAN_CONTAINER_NAME}
################################################
  CONNECTION MANAGER IS READY TO USE!            
################################################
```
## Section 3: Sample of Addition of Nodes to Oracle RAC Containers based on Oracle RAC Image

### Section 3.1: Sample of Addition of Nodes to Oracle RAC Containers using Podman Compose based on Oracle RAC Image with BlockDevices

Below is an example to add one more node to existing Oracle RAC 2 node cluster using Oracle RAC Image and with user defined files using podman compose file -

Create compose file named [podman-compose.yml](./withoutresponsefiles/blockdevices/addition/podman-compose.yml) in your working directory.

Export the required environment variables required by `podman-compose.yml` file -
```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE3_CONTAINER_NAME=racnodep3
export RACNODE3_HOST_NAME=racnodep3
export RACNODE3_PUBLIC_IP=10.0.20.172
export RACNODE3_CRS_PRIVATE_IP1=192.168.17.172
export RACNODE3_CRS_PRIVATE_IP2=192.168.18.172
export INSTALL_NODE=racnodep3
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep3,viphost:racnodep3-vip\""
export EXISTING_CLS_NODE="racnodep1,racnodep2"
export SCAN_NAME=racnodepc1-scan
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export CRS_ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXD="racnoded"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export DB_SERVICE=service:soepdb
```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE3_CONTAINER_NAME} 
podman-compose stop ${RACNODE3_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE3_PUBLIC_IP} ${RACNODE3_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE3_CRS_PRIVATE_IP1}  ${RACNODE3_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE3_CRS_PRIVATE_IP2}  ${RACNODE3_CONTAINER_NAME}

podman-compose start ${RACNODE3_CONTAINER_NAME}
podman exec ${RACNODE3_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
========================================================
Oracle Database ORCLCDB3 is up and running on racnodep3.
========================================================
```

### Section 3.2: Sample of Addition of Nodes to Oracle RAC Containers using Podman Compose based on Oracle RAC Image with NFS Storage Devices
Below is the example to add one more node to existing Oracle RAC 2 node cluster using Oracle RAC Image and with user defined files using podman compose file -

Create compose file named [podman-compose.yml](./withoutresponsefiles/nfsdevices/addition/podman-compose.yml) in your working directory.


Export the required environment variables required by `podman-compose.yml` file -
```bash
export HEALTHCHECK_INTERVAL=60s
export HEALTHCHECK_TIMEOUT=120s
export HEALTHCHECK_RETRIES=240
export RACNODE3_CONTAINER_NAME=racnodep3
export RACNODE3_HOST_NAME=racnodep3
export RACNODE3_PUBLIC_IP=10.0.20.172
export RACNODE3_CRS_PRIVATE_IP1=192.168.17.172
export RACNODE3_CRS_PRIVATE_IP2=192.168.18.172
export INSTALL_NODE=racnodep3
export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
export DEFAULT_GATEWAY="10.0.20.1"
export CRS_NODES="\"pubhost:racnodep3,viphost:racnodep3-vip\""
export EXISTING_CLS_NODE="racnodep1,racnodep2"
export SCAN_NAME=racnodepc1-scan
export CRS_ASM_DISCOVERY_STRING="/oradata"
export CRS_ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=racdns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_DOMAIN=example.info
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
export DNS_PUBLIC_IP=10.0.20.25
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_HOST_NAME=racnodepc1-cman
export CMAN_PUBLIC_IP=10.0.20.166
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export DB_SERVICE=service:soepdb
```
Bring up RAC Containers-
```bash
podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE3_CONTAINER_NAME} 
podman-compose stop ${RACNODE3_CONTAINER_NAME}

podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}
podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}
podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE3_CONTAINER_NAME}

podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE3_PUBLIC_IP} ${RACNODE3_CONTAINER_NAME}
podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE3_CRS_PRIVATE_IP1}  ${RACNODE3_CONTAINER_NAME}
podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE3_CRS_PRIVATE_IP2}  ${RACNODE3_CONTAINER_NAME}

podman-compose start ${RACNODE3_CONTAINER_NAME}
podman exec ${RACNODE3_CONTAINER_NAME} /bin/bash -c "tail -f /tmp/orod/oracle_rac_setup.log"
```

Successful Message when RAC container is setup properly-
```bash
========================================================
Oracle Database ORCLCDB3 is up and running on racnodep3.
========================================================
```
## Section 4: Environment Variables for Oracle RAC on Podman Compose
Refer [Environment Variables Explained for Oracle RAC on Podman Compose](../../../docs/ENVVARIABLESCOMPOSE.md) for explanation of all the environment variables related to Oracle RAC on Podman Compose. Change or Set these environment variables as per your environment.

## Section 5: Validating Oracle RAC Environment
You can validate if Oracle Container environment is healthy by running below command-
```bash
podman ps -a
CONTAINER ID  IMAGE                                  COMMAND               CREATED         STATUS                   PORTS       NAMES
f1345fd4047b  localhost/oracle/rac-dnsserver:latest  /bin/sh -c exec $...  8 hours ago     Up 8 hours (healthy)                 rac-dnsserver
2f42e49758d1  localhost/oracle/database-rac:21c                        46 minutes ago  Up 37 minutes (healthy)              racnodep1
a27fceea9fe6  localhost/oracle/database-rac:21c                        46 minutes ago  Up 37 minutes (healthy)              racnodep2
```
Note:
- Look for `(healthy)` next to container names under `STATUS` section.

## Section 6: Connecting to Oracle RAC Environment

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.
Refer [README](../../../docs/CONNECTING.md) for instructions on how to connect to Oracle RAC Database.

## Cleanup
Refer [README](../../../docs/CLEANUP.md) for instructions on how to connect to cleanup Oracle RAC Database Container Environment.

## Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 8.10 later. To see current Linux support certifications, refer [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
