# Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers with User-Defined Sharding

This page covers the steps to manually deploy a sample Oracle Globally Distributed Database with User-Defined Sharding using Oracle RAC Database on Podman Containers. **This deployment uses Extended Oracle RAC Database Container Image to deploy the Database Containers.**

- [Setup Details](#setup-details)
- [Prerequisites](#prerequisites)
- [Deploying Catalog Container](#deploying-catalog-container)
  - [Storage for ASM Disk for Catalog Container](#storage-for-asm-disk-for-catalog-container)
  - [Create Containers](#create-containers)
- [Deploying Shard Containers](#deploying-shard-containers)
  - [Storage for ASM Disks for Shard Containers](#storage-for-asm-disks-for-shard-containers)
  - [Shard1 Containers](#shard1-containers)
  - [Shard2 Containers](#shard2-containers)
- [Deploying GSM Container](#deploying-gsm-container)
  - [Create Directory for Master GSM Container](#create-directory-for-master-gsm-container)
  - [Create Master GSM Container](#create-master-gsm-container)
- [Deploying Standby GSM Container](#deploying-standby-gsm-container)  
  - [Create Directory for Standby GSM Container](#create-directory-for-standby-gsm-container)
  - [Create Standby GSM Container](#create-standby-gsm-container)
- [Scale-out an existing Oracle Globally Distributed Database](#scale-out-an-existing-oracle-globally-distributed-database)
  - [Storage for ASM Disk for New Shard Container](#storage-for-asm-disk-for-new-shard-container)
  - [Create Podman Containers for new shard](#create-podman-containers-for-new-shard)
  - [Add the new shard Database to the existing Oracle Globally Distributed Database](#add-the-new-shard-database-to-the-existing-oracle-globally-distributed-database)
  - [Deploy the new shard](#deploy-the-new-shard)
  - [Move chunks](#move-chunks)
- [Scale-in an existing Oracle Globally Distributed Database](#scale-in-an-existing-oracle-globally-distributed-database)
  - [Confirm the shard to be deleted is present in the list of shards in the Oracle Globally Distributed Database](#confirm-the-shard-to-be-deleted-is-present-in-the-list-of-shards-in-the-oracle-globally-distributed-database)
  - [Move the chunks out of the shard database which you want to delete](#move-the-chunks-out-of-the-shard-database-which-you-want-to-delete)
  - [Delete the shard database from the Oracle Globally Distributed Database](#delete-the-shard-database-from-the-oracle-globally-distributed-database)
  - [Confirm the shard has been successfully deleted from the Oracle Globally Distributed Database](#confirm-the-shard-has-been-successfully-deleted-from-the-oracle-globally-distributed-database)
  - [Remove the Podman Containers](#remove-the-podman-containers)
- [Environment Variables Explained](#environment-variables-explained)
- [Support](#support)
- [License](#license)
- [Copyright](#copyright)

## Setup Details

This setup involves deploying podman containers for:

- Catalog Database
- Two Shard Databases
- Primary GSM
- Standby GSM

**NOTE:** You can use Oracle 19c or 21c or Oracle AI Database 26ai RAC and GSM Podman Images for this sample deployment.

**NOTE:** In the current Sample Oracle Globally Distributed Database Deployment, we have used Oracle AI Database 26ai RAC and GSM Podman Images.

## Prerequisites

Before using this page to create a sample Oracle Globally Distributed Database, please complete the prerequisite steps mentioned in [Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers](./README.md#prerequisites)

Before creating the GSM container, you need to build the catalog and shard containers. Execute the following steps to create containers for the deployment:

## Deploying Catalog Container

The shard catalog is a special-purpose Oracle Database that is a persistent store for SDB configuration data and plays a key role in the automated deployment and centralized management of an Oracle Globally Distributed Database. It also hosts the gold schema of the application and the master copies of common reference data (duplicated tables). In this case, the Catalog Database will be deployed as 2 Node Oracle RAC Database using 2 Podman Containers on separate Host Machines.

### Storage for ASM Disk for Catalog Container

Ensure that you have created at least one Block Device with at least 50 Gb of storage space that can be accessed by the Catalog Container. You can create more block devices in accordance with your requirements and pass those environment variables and devices to the podman create command.

Ensure that the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/catalog_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

**NOTE:** The Block Device needs to be attached to both the host machines to be used as shared storage by both the containers for the RAC Database.

### Create Containers

Before creating catalog container, review the following notes carefully:

**Notes:**

- Change environment variable such as DB_NAME, ORACLE_PDB_NAME based on your env.
- Use the parameter `OP_TYPE="setuprac,catalog"`,`CRS_RACDB="true"` to use the Oracle RAC option to setup the Catalog for Sharded Database deployment.
- If you are using Extended Oracle RAC Database `SLIM` Image instead of the full image, then use the below additional parameters during the container creation:
  
  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/26.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/26.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/26.0.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e COPY_DB_SOFTWARE=true \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/catalog:/u01 \
  --volume /stage:/stage \
  ```

  In this case,
  - `/scratch/rac/catalog` is the host location which will be mapped to `/u01` inside the container to use as the software installation home location. This host location should be having correct permissions set at the host level to be read/write enabled from the container by users oracle (uid: 54321) and grid (uid: 54322).
  - `/stage` is the host location mapped to `/stage` inside the container to use for staging the Grid and DB Software binaries. This location needs atleast read permission from the container by the users oracle (uid: 54321) and grid (uid: 54322).

- If SELinux is enabled on podman hosts, then execute following commands to set the contexts for the host locations you want to mount and use inside the container:
  
  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/catalog
  restorecon -v /scratch/rac/catalog
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

- First, provision the RAC Node 2 on Second Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/catalog_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

podman create -t -i \
--hostname cataloga2 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.29 \
-e CRS_PRIVATE_IP2=10.0.17.29 \
-e CRS_NODES="\"pubhost:cataloga1,viphost:cataloga1-vip;pubhost:cataloga2,viphost:cataloga2-vip\"" \
-e SCAN_NAME=cataloga-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=CATCDB \
-e DB_UNIQUE_NAME=CATCDB \
-e ORACLE_PDB_NAME=CAT1PDB \
-e OP_TYPE="setuprac,catalog" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=cataloga1 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name cataloga2 oracle/database-rac-ext-sharding:26.0.0-ee

podman network disconnect podman cataloga2
podman network connect shard_rac_pub1_nw --ip 10.0.15.29 cataloga2
podman network connect shard_rac_priv1_nw --ip 10.0.16.29 cataloga2
podman network connect shard_rac_priv2_nw --ip 10.0.17.29 cataloga2
podman start cataloga2
```

To check the cataloga2 container creation logs, please tail podman logs:

```bash
podman exec cataloga2 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the cataloga1 (RAC Node 1), the container logs for cataloga2 container will show message like below:

```bash
  02/06/2025 06:15:32 PM     INFO:  orasetupenv  -     setbanner      :
            =====================================
            Grid is not installed on this machine
            =====================================

  02/06/2025 06:15:32 PM     INFO:  orasetupenv  -       setup        :Total time for setup() = [ 5.087 ] seconds
  02/06/2025 06:15:32 PM     INFO:  oramachine   -       setup        :Total time for setup() = [ 5.088 ] seconds
```

- Now, provision the RAC Node 1 on First Host Machine using the below command:

```bash
```bash
export DEVICE="--device=/dev/disk/by-partlabel/catalog_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname cataloga1 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.28 \
-e CRS_PRIVATE_IP2=10.0.17.28 \
-e CRS_NODES="\"pubhost:cataloga1,viphost:cataloga1-vip;pubhost:cataloga2,viphost:cataloga2-vip\"" \
-e SCAN_NAME=cataloga-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=CATCDB \
-e DB_UNIQUE_NAME=CATCDB \
-e ORACLE_PDB_NAME=CAT1PDB \
-e OP_TYPE="setuprac,catalog" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=cataloga1 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name cataloga1 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman cataloga1
podman network connect shard_rac_pub1_nw --ip 10.0.15.28 cataloga1
podman network connect shard_rac_priv1_nw --ip 10.0.16.28 cataloga1
podman network connect shard_rac_priv2_nw --ip 10.0.17.28 cataloga1
podman start cataloga1
```

To check the catalog1 container creation logs, please tail podman logs on First Host Machine:

```bash
podman exec cataloga1 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the catalog1 (RAC Node 1), the container logs for catalog1 container will show message like below once the RAC Database Deployment completes :

```bash
        ===================================
        ORACLE RAC DATABASE IS READY TO USE
        ===================================
```

Now, monitor the Oracle Shard creation using below command on the First Host Machine:

```bash
podman exec cataloga1 /bin/bash -c "tail -f /tmp/sharding/oracle_sharding_setup.log"
```

You will get the message as below once the Oracle GDD Catalog is created:

```bash
          ==============================================
                  GSM Catalog Setup Completed
          ==============================================
```

## Deploying Shard Containers

A database shard is a horizontal partition of data in a database or search engine. Each individual partition is referred to as a shard or database shard.

### Storage for ASM Disks for Shard Containers

Ensure that you have created at least one Block Device with at least 50 Gb of storage space for each of the Shard Container. You can create more block devices in accordance with your requirements and pass those environment variables and devices to the podman create command. The Storage Device must be accessible to the Shard Container to which that is getting assigned.

Ensure that the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard1_asm_disk  bs=8k count=10000
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard2_asm_disk  bs=8k count=10000  
```

Repeat this command on each shared block device if you are assigning more than one Storage Device to Shard Container.

### Shard1 Containers

Before creating the containers for Shard1 RAC Database, review the following notes carefully:

**Notes:**

- Change environment variable such as DB_NAME, ORACLE_PDB_NAME based on your env.
- Use the parameter `OP_TYPE="setuprac,primaryshard"`,`CRS_RACDB="true"` to use the Oracle RAC Database option to setup the Shard1 for Sharded Database deployment.
- If you are using Extended Oracle RAC Database `SLIM` Image instead of the full image, then use the below additional parameters during the container creation:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/26.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/26.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/26.0.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e COPY_DB_SOFTWARE=true \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard1:/u01 \
  --volume /stage:/stage \
  ```

  In this case,
  - `/scratch/rac/shard1` is the host location which will be mapped to `/u01` inside the container to use as the software installation home location. This host location should be having correct permissions set at the host level to be read/write enabled from the container by users oracle (uid: 54321) and grid (uid: 54322).
  - `/stage` is the host location mapped to `/stage` inside the container to use for staging the Grid and DB Software binaries. This location needs atleast read permission from the container by the users oracle (uid: 54321) and grid (uid: 54322).

- If SELinux is enabled on podman host, then execute following commands to set the contexts for the host locations you want to mount and use inside the container:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard1
  restorecon -v /scratch/rac/shard1
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```  

- First, provision the RAC Node 2 on Second Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard1_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname sharda12 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.31 \
-e CRS_PRIVATE_IP2=10.0.17.31 \
-e CRS_NODES="\"pubhost:sharda11,viphost:sharda11-vip;pubhost:sharda12,viphost:sharda12-vip\"" \
-e SCAN_NAME=sharda1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL1CDB \
-e DB_UNIQUE_NAME=ORCL1CDB \
-e ORACLE_PDB_NAME=ORCL1PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda11 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda12 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman sharda12
podman network connect shard_rac_pub1_nw --ip 10.0.15.31 sharda12
podman network connect shard_rac_priv1_nw --ip 10.0.16.31 sharda12
podman network connect shard_rac_priv2_nw --ip 10.0.17.31 sharda12
podman start sharda12
```

To check the sharda12 container creation logs, please tail podman logs:

```bash
  podman exec sharda12 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the sharda11 (RAC Node 1), the container logs for sharda12 container will show message like below:

```bash
            =====================================
            Grid is not installed on this machine
            =====================================
```

- Now, provision the RAC Node 1 on First Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard1_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname sharda11 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.30 \
-e CRS_PRIVATE_IP2=10.0.17.30 \
-e CRS_NODES="\"pubhost:sharda11,viphost:sharda11-vip;pubhost:sharda12,viphost:sharda12-vip\"" \
-e SCAN_NAME=sharda1-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL1CDB \
-e DB_UNIQUE_NAME=ORCL1CDB \
-e ORACLE_PDB_NAME=ORCL1PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda11 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda11 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman sharda11
podman network connect shard_rac_pub1_nw --ip 10.0.15.30 sharda11
podman network connect shard_rac_priv1_nw --ip 10.0.16.30 sharda11
podman network connect shard_rac_priv2_nw --ip 10.0.17.30 sharda11
podman start sharda11
```

To check the sharda11 container creation logs, please tail podman logs on First Host Machine:

```bash
  podman exec sharda11 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the sharda11 (RAC Node 1), the container logs for sharda11 container will show message like below once the RAC Database Deployment completes:

```bash
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using below command on the First Host Machine:

```bash
podman exec sharda11 /bin/bash -c "tail -f /tmp/sharding/oracle_sharding_setup.log"
```

You will get the message as below once the Oracle Shard1 RAC Database is created:

```bash
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Shard2 Containers

Before creating the containers for Shard2 RAC Database, review the following notes carefully:

**Notes:**

- Change environment variable such as DB_NAME, ORACLE_PDB_NAME based on your env.
- Use the parameter `OP_TYPE="setuprac,primaryshard"`,`CRS_RACDB="true"` to use the Oracle RAC Database option to setup the Shard2 for Sharded Database deployment.
- If you are using Extended Oracle RAC Database `SLIM` Image instead of the full image, then use the below additional parameters during the container creation:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/26.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/26.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/26.0.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e COPY_DB_SOFTWARE=true \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard2:/u01 \
  --volume /stage:/stage \
  ```

  In this case,
  - `/scratch/rac/shard2` is the host location which will be mapped to `/u01` inside the container to use as the software installation home location. This host location should be having correct permissions set at the host level to be read/write enabled from the container by users oracle (uid: 54321) and grid (uid: 54322).
  - `/stage` is the host location mapped to `/stage` inside the container to use for staging the Grid and DB Software binaries. This location needs atleast read permission from the container by the users oracle (uid: 54321) and grid (uid: 54322).

- If SELinux is enabled on podman host, then execute following commands to set the contexts for the host locations you want to mount and use inside the container:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard2
  restorecon -v /scratch/rac/shard2
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```  

- First, provision the RAC Node 2 on Second Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard2_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname sharda22 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.33 \
-e CRS_PRIVATE_IP2=10.0.17.33 \
-e CRS_NODES="\"pubhost:sharda21,viphost:sharda21-vip;pubhost:sharda22,viphost:sharda22-vip\"" \
-e SCAN_NAME=sharda2-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL2CDB \
-e DB_UNIQUE_NAME=ORCL2CDB \
-e ORACLE_PDB_NAME=ORCL2PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda21 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda22 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman sharda22
podman network connect shard_rac_pub1_nw --ip 10.0.15.33 sharda22
podman network connect shard_rac_priv1_nw --ip 10.0.16.33 sharda22
podman network connect shard_rac_priv2_nw --ip 10.0.17.33 sharda22
podman start sharda22
```

To check the sharda22 container creation logs, please tail podman logs:

```bash
  podman exec sharda22 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the sharda21 (RAC Node 1), the container logs for sharda22 container will show message like below:

```bash
            =====================================
            Grid is not installed on this machine
            =====================================
```

- Now, provision the RAC Node 1 on First Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard2_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname sharda21 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.32 \
-e CRS_PRIVATE_IP2=10.0.17.32 \
-e CRS_NODES="\"pubhost:sharda21,viphost:sharda21-vip;pubhost:sharda22,viphost:sharda22-vip\"" \
-e SCAN_NAME=sharda2-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL2CDB \
-e DB_UNIQUE_NAME=ORCL2CDB \
-e ORACLE_PDB_NAME=ORCL2PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda21 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda21 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman sharda21
podman network connect shard_rac_pub1_nw --ip 10.0.15.32 sharda21
podman network connect shard_rac_priv1_nw --ip 10.0.16.32 sharda21
podman network connect shard_rac_priv2_nw --ip 10.0.17.32 sharda21
podman start sharda21
```

To check the sharda21 container creation logs, please tail podman logs on First Host Machine:

```bash
  podman exec sharda21 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the sharda21 (RAC Node 1), the container logs for sharda21 container will show message like below once the RAC Database Deployment completes :

```bash
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using below command on the First Host Machine:

```bash
podman exec sharda21 /bin/bash -c "tail -f /tmp/sharding/oracle_sharding_setup.log"
```

You will get the message as below once the Oracle Shard2 RAC Database is created:

```bash
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

## Deploying GSM Container

The Global Data Services framework consists of at least one global service manager, a Global Data Services catalog, and the GDS configuration databases. You need to create mountpoint on podman host to save gsm setup related file for Oracle Global Service Manager and expose as a volume to GSM container. This volume can be local on a podman host or exposed from your central storage. It contains a file system such as EXT4. During the setup of this README.md, we used /oradata/dbfiles/GSMDATA_RAC directory and exposed as volume to GSM container.

**Note:** In this setup, **both** the Master and Standby GSM containers are deployed on the First Host Machine. You can deploy one GSM Container on First Host Machine and second on the Second Host Machine as well.

### Create Directory for Master GSM Container

```bash
  mkdir -p /scratch/oradata/dbfiles/GSMDATA_RAC
  chown -R 54321:54321 /scratch/oradata/dbfiles/GSMDATA_RAC
```

If SELinux is enabled on podman host, then execute following-

```bash
  semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/GSMDATA_RAC
  restorecon -v /scratch/oradata/dbfiles/GSMDATA_RAC
```

### Create Master GSM Container

```bash
podman create -t -i \
--hostname gsma1 \
--dns-search=example.info \
--dns 10.0.15.25 \
-e DOMAIN=example.info \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522" \
-e CATALOG_PARAMS="catalog_host=cataloga-scan;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;sharding_type=USER;shard_space=shardspace1,shardspace2" \
-e SHARD1_PARAMS="shard_host=sharda1-scan;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_space=shardspace1;deploy_as=primary;shard_region=region1" \
-e SHARD2_PARAMS="shard_host=sharda2-scan;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_space=shardspace2;deploy_as=primary;shard_region=region2" \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary" \
-e INVITED_NODE_SUBNET_FLAG=TRUE \
-e COMMON_OS_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--secret pwdsecret \
--secret keysecret \
-e SHARD_SETUP="True" \
-v /scratch/oradata/dbfiles/GSMDATA_RAC:/opt/oracle/gsmdata \
-e OP_TYPE=gsm \
-e MASTER_GSM="TRUE" \
--restart=always \
--privileged=false \
--name gsma1 \
oracle/database-gsm:26.0.0
  
podman network disconnect podman gsma1
podman network connect shard_rac_pub1_nw --ip 10.0.15.26 gsma1
podman start gsma1
```

**Note:** Change environment variables such as DOMAIN, CATALOG_PARAMS, PRIMARY_SHARD_PARAMS, COMMON_OS_PWD_FILE and PWD_KEY according to your environment.

To check the gsm1 container/services creation logs, please tail podman logs. It will take few minutes to create the gsm container service.

```bash
podman logs -f gsma1
==============================================
     GSM Setup Completed                      
==============================================
```

## Deploying Standby GSM Container

You need standby GSM container to serve the connection when master GSM fails.

### Create Directory for Standby GSM Container

```bash
mkdir -p /scratch/oradata/dbfiles/GSM2DATA_RAC
chown -R 54321:54321 /scratch/oradata/dbfiles/GSM2DATA_RAC
```

If SELinux is enabled on podman host, then execute following-

```bash
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/GSM2DATA_RAC
restorecon -v /scratch/oradata/dbfiles/GSM2DATA_RAC
```

### Create Standby GSM Container

```bash
podman create -i -t \
--hostname gsma2 \
--dns-search=example.info \
--dns 10.0.15.25 \
-e DOMAIN=example.info \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
-e CATALOG_PARAMS="catalog_host=cataloga-scan;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;sharding_type=USER;shard_space=shardspace1,shardspace2" \
-e SHARD1_PARAMS="shard_host=sharda1;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_space=shardspace1;" \
-e SHARD2_PARAMS="shard_host=sharda2;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_space=shardspace2;" \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary" \
-e INVITED_NODE_SUBNET_FLAG=TRUE \
-e CATALOG_SETUP="True" \
-e COMMON_OS_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
--secret pwdsecret \
--secret keysecret \
-v /scratch/oradata/dbfiles/GSM2DATA_RAC:/opt/oracle/gsmdata \
-e OP_TYPE=gsm \
--restart=always \
--privileged=false \
--name gsma2 \
oracle/database-gsm:26.0.0

podman network disconnect podman gsma2
podman network connect shard_rac_pub1_nw --ip 10.0.15.27 gsma2
podman start gsma2
```

**Note:** Change environment variables such as DOMAIN, CATALOG_PARAMS, COMMON_OS_PWD_FILE and PWD_KEY according to your environment.

To check the gsma2 container/services creation logs, please tail podman logs. It will take 2 minutes to create the gsm container service.

```bash
podman logs -f gsma2
```

**IMPORTANT:** The GSM Container Image used in this case is having the Oracle GSM installed. On first startup of the container, a new GSM setup will be created and the following lines highlight when the GSM setup is ready to be used:

```bash
==============================================
      GSM Setup Completed
==============================================
```

**NOTE:** Once the Oracle Globally Distributed Database Deployment is complete using Used-Defined Sharding, you can load the data into this Oracle Globally Distributed Database.

## Scale-out an existing Oracle Globally Distributed Database

If you want to Scale-Out an existing Oracle Globally Distributed Database already deployed using the Podman Containers, then you will to complete the steps in below order:

- Complete the prerequisite steps before creating the Podman Container for the new shard to be added to the Oracle Globally Distributed Database
- Create the Podman Container for the new shard
- Add the new shard Database to the existing Oracle Globally Distributed Database
- Deploy the new shard
- Move chunks

The below example covers the steps to add a new shard (shard3) to an existing Oracle Globally Distributed Database which was deployed earlier in this page with two shards (shard1 and shard2).

### Storage for ASM Disk for New Shard Container

Ensure that you have created at least one Block Device with at least 50 Gb of storage space that can be accessed by the Shard3 Container. You can create more block devices in accordance with your requirements and pass those environment variables and devices to the podman create command.

Ensure that the ASM devices do not have any existing file system. To clear any other file system from the devices, use the following command:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard3_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

### Create Podman Containers for new shard

Before creating new shard (shard3 in this case) container, review the following notes carefully:

**Notes:**

- Change environment variable such as DB_NAME, ORACLE_PDB_NAME based on your env.
- Use the parameter `OP_TYPE="setuprac,primaryshard"`,`CRS_RACDB="true"` to use the Oracle RAC Database option to setup the Shard3 for Sharded Database deployment.
- If you are using Extended Oracle RAC Database `SLIM` Image instead of the full image, then use the below additional parameters during the container creation:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/26.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/26.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/26.0.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e COPY_DB_SOFTWARE=true \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard3:/u01 \
  --volume /stage:/stage \
  ```

  In this case,
  - `/scratch/rac/shard3` is the host location which will be mapped to `/u01` inside the container to use as the software installation home location. This host location should be having correct permissions set at the host level to be read/write enabled from the container by users oracle (uid: 54321) and grid (uid: 54322).
  - `/stage` is the host location mapped to `/stage` inside the container to use for staging the Grid and DB Software binaries. This location needs atleast read permission from the container by the users oracle (uid: 54321) and grid (uid: 54322).

- If SELinux is enabled on podman host, then execute following commands to set the contexts for the host locations you want to mount and use inside the container:
  
  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard3
  restorecon -v /scratch/rac/shard3
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

- First, provision the RAC Node 2 on Second Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard3_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

export DEVICE="--device=/dev/disk/by-partlabel/shard3_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

podman create -t -i \
--hostname sharda32 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.35 \
-e CRS_PRIVATE_IP2=10.0.17.35 \
-e CRS_NODES="\"pubhost:sharda31,viphost:sharda31-vip;pubhost:sharda32,viphost:sharda32-vip\"" \
-e SCAN_NAME=sharda3-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL3CDB \
-e DB_UNIQUE_NAME=ORCL3CDB \
-e ORACLE_PDB_NAME=ORCL3PDB \
-e OP_TYPE=setuprac \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda31 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda32 oracle/database-rac-ext-sharding:26.0.0-ee


podman network disconnect podman sharda32
podman network connect shard_rac_pub1_nw --ip 10.0.15.35 sharda32
podman network connect shard_rac_priv1_nw --ip 10.0.16.35 sharda32
podman network connect shard_rac_priv2_nw --ip 10.0.17.35 sharda32
podman start sharda32
```

To check the sharda32 container creation logs, please tail podman logs:

```bash
  podman exec sharda32 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the shard31 (RAC Node 1), the container logs for shard32 container will show message like below:

```bash
  02/06/2025 06:15:32 PM     INFO:  orasetupenv  -     setbanner      :
            =====================================
            Grid is not installed on this machine
            =====================================

  02/06/2025 06:15:32 PM     INFO:  orasetupenv  -       setup        :Total time for setup() = [ 5.087 ] seconds
  02/06/2025 06:15:32 PM     INFO:  oramachine   -       setup        :Total time for setup() = [ 5.088 ] seconds
```

- Now, provision the RAC Node 1 on First Host Machine using the below command:

```bash
export DEVICE="--device=/dev/disk/by-partlabel/shard3_asm_disk:/dev/asm-disk1"
export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"
  
podman create -t -i \
--hostname sharda31 \
--dns-search example.info \
--dns 10.0.15.25 \
--shm-size 4G \
--sysctl 'net.ipv4.conf.eth1.rp_filter=2' \
--sysctl 'net.ipv4.conf.eth2.rp_filter=2' \
--cpuset-cpus 0-1 \
--memory 12G \
--memory-swap 24G \
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
-e CRS_PRIVATE_IP1=10.0.16.34 \
-e CRS_PRIVATE_IP2=10.0.17.34 \
-e CRS_NODES="\"pubhost:sharda31,viphost:sharda31-vip;pubhost:sharda32,viphost:sharda32-vip\"" \
-e SCAN_NAME=sharda3-scan \
-e INIT_SGA_SIZE=3G \
-e INIT_PGA_SIZE=2G \
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DNS_SERVERS=10.0.15.25 \
-e DB_NAME=ORCL3CDB \
-e DB_UNIQUE_NAME=ORCL3CDB \
-e ORACLE_PDB_NAME=ORCL3PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INSTALL_NODE=sharda31 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e CRS_RACDB="true" \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda31 oracle/database-rac-ext-sharding:26.0.0-ee
  
podman network disconnect podman sharda31
podman network connect shard_rac_pub1_nw --ip 10.0.15.34 sharda31
podman network connect shard_rac_priv1_nw --ip 10.0.16.34 sharda31
podman network connect shard_rac_priv2_nw --ip 10.0.17.34 sharda31
podman start sharda31
```

To check the sharda31 container creation logs, please tail podman logs on First Host Machine:

```bash
  podman exec sharda31 /bin/bash -c "tail -f /tmp/orod/oracle_db_setup.log"
```

As the installation will be done from the sharda31 (RAC Node 1), the container logs for sharda31 container will show message like below once the RAC Database Deployment completes:

```bash
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using below command on the First Host Machine:

```bash
podman exec sharda31 /bin/bash -c "tail -f /tmp/sharding/oracle_sharding_setup.log"
```

You will get the message as below once the Oracle Shard is created:

```bash
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Add the new shard Database to the existing Oracle Globally Distributed Database

Use the below command to add the new shard3:

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py --addshard="shard_host=sharda3-scan;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_space=shardspace3;shard_region=region3"
```

Use the below command to check the status of the newly added shard:

``` bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard
```

### Deploy the new shard

Deploy the newly added shard (shard3):

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py --deployshard=true
```

Use the below command to check the status of the newly added shard and the chunks distribution:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Move chunks

In case you want to move some chunks to the newly added Shard from an existing Shard, you can use the below command:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK $CHUNK_ID -SOURCE $SOURCE_SHARD -TARGET $TARGET_SHARD
```

Example: If you want to move the chunk with chunk id `3` from source shard `ORCL1CDB_ORCL1PDB` to target shard `ORCL3CDB_ORCL3PDB`, then you can use the below command:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK 3 -SOURCE ORCL1CDB_ORCL1PDB -TARGET ORCL3CDB_ORCL3PDB
```

Use the below command to check the status of the chunks distribution:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

## Scale-in an existing Oracle Globally Distributed Database

If you want to Scale-in an existing Oracle Globally Distributed Database by removing a particular shard database out of the existing shard databases, then you will to complete the steps in below order:

- Confirm the shard to be deleted is present in the list of shards in the Oracle Globally Distributed Database
- Move the chunks out of the shard database which you want to delete
- Delete the shard database from the Oracle Globally Distributed Database
- Confirm the shard has been successfully deleted from the Oracle Globally Distributed Database

### Confirm the shard to be deleted is present in the list of shards in the Oracle Globally Distributed Database

Use the below commands to check the status of the shard which you want to delete and status of chunks present in this shard:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Move the chunks out of the shard database which you want to delete

In the current example, if you want to delete the shard3 database from the Oracle Globally Distributed Database, then you need to use the below command to move the chunks out of shard3 database:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK $CHUNK_ID -SOURCE $SOURCE_SHARD -TARGET $TARGET_SHARD
```

Example: If you want to move the chunk with chunk id `3` from source shard `ORCL3CDB_ORCL3PDB` to target shard `ORCL1CDB_ORCL1PDB`, then you can use the below command:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK 3 -SOURCE ORCL3CDB_ORCL3PDB -TARGET ORCL1CDB_ORCL1PDB
```

**NOTE:** To move more than 1 chunk, you can specify comma separated chunk ids.

After moving the chunks out, use the below command to confirm there is no chunk present in the shard database which you want to delete:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

**NOTE:** You will need to wait for some time for all the chunks to move out of the shard database which you want to delete.

### Delete the shard database from the Oracle Globally Distributed Database

Once you have confirmed that no chunk is present in the shard to be deleted in earlier step, you can use the below command to delete that shard(shard3 in this case):

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py  --deleteshard="shard_host=sharda3-scan;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_space=shardspace3;shard_region=region3"
```

**NOTE:** In this case, `sharda3-scan`, `ORCL3CDB` and `ORCL3PDB` are the SCAN Name, CDB name and PDB name for the shard3 respectively.

### Confirm the shard has been successfully deleted from the Oracle Globally Distributed Database

Once the shard is deleted from the Oracle Globally Distributed Database, use the below commands to check the status of the shards and chunk distribution in the Oracle Globally Distributed Database:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Remove the Podman Containers

Once the shard is deleted from the Oracle Globally Distributed Database, you can remove the Podman Containers which were deployed earlier for the deleted shard database.

If the deleted shard was shard3, to remove its Podman Containers, please use the below steps:

- Stop and remove the Podman Containers for shard3:

```bash
podman stop sharda32
podman rm sharda32

podman stop sharda31
podman rm sharda31
```

- If you have used Extended Oracle RAC Database `SLIM` Image instead of the full image, then remove the directory `/scratch/rac/shard3` containing the files for these deleted Podman Containers from the both Host Machines:

```bash
rm -rf /scratch/rac/shard3
```

## Environment Variables Explained

**For catalog, shard containers:**

| Parameter                  | Description                                                                                                              | Mandatory/Optional  |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------|---------------------|
| COMMON_OS_PWD_FILE         | Specify the podman secret for the password file to be read inside the container                                          | Mandatory           |
| PWD_KEY                    | Specify the podman secret for the password key file to decrypt the encrypted password file and read the password         | Mandatory           |
| OP_TYPE                    | Specify the operation type. For Shards it has to be set to primaryshard or standbyshard                                  | Mandatory           |
| DOMAIN                     | Specify the domain name                                                                                                  | Mandatory           |
| ORACLE_SID                 | CDB name which has to be "FREE" for Oracle Database FREE                                                                 | Mandatory           |
| ORACLE_PDB                 | PDB name which has to be "FREEPDB1" for Oracle Database FREE                                                             | Mandatory           |
| ORACLE_FREE_PDB            | PDB name which you want to create for the setup                                                                          | Mandatory           |
| DB_NAME                    | CDB name                                                                                                                 | Mandatory           |
| DB_UNIQUE_NAME             | DB_UNIQUE_NAME name which you want to set                                                                                | Mandatory           |
| ORACLE_PDB_NAME            | PDB name                                                                                                                 | Mandatory           |
| CRS_GPC                    | Set to true along with OP_TYPE to use the Oracle Restart option for Catalog and Shard Database Containers                | Mandatory           |
| CRS_RACDB                  | Set to true along with OP_TYPE to use the Oracle RAC Database option for Catalog and Shard Database Containers           | Mandatory           |
| CUSTOM_SHARD_SCRIPT_DIR    | Specify the location of custom scripts which you want to run after setting up shard setup.                               | Optional            |
| CUSTOM_SHARD_SCRIPT_FILE   | Specify the file name that must be available on CUSTOM_SHARD_SCRIPT_DIR location to be executed after shard db setup.    | Optional            |
| CLONE_DB                   | Specify value "true" if you want to avoid db creation and clone it from cold backup of existing Oracle DB.               | Optional            |
|                            | This DB must not have shard setup. Shard script will look for the backup at /opt/oracle/oradata.                         |                     |
| OLD_ORACLE_SID             | Specify the OLD_ORACLE_SID if you are performing db seed cloning using existing cold backup of Oracle DB.                | Optional            |
| OLD_ORACLE_PDB             | Specify the OLD_ORACLE_PDB if you are performing db seed cloning using existing cold backup of Oracle DB.                | Optional            |

**For GSM Containers:**

| Parameter                  | Description                                                                                                              | Mandatory/Optional  |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------|---------------------|
| CATALOG_SETUP              | Accept True. if set then , it will only restrict till catalog connection and setup.                                      | Mandatory           |
| CATALOG_PARAMS             | Accept key value pair separated by semicolon e.g. key1=value1;key2=value2 for following key=value pairs:                 | Mandatory           |
|                            |   - key=catalog_host, value=catalog hostname                                                                             |                     |
|                            |   - key=catalog_db, value=catalog cdb name                                                                               |                     |
|                            |   - key=catalog_pdb, value=catalog pdb name                                                                              |                     |
|                            |   - key=catalog_port, value=catalog db port name                                                                         |                     |
|                            |   - key=catalog_name, value=catalog name in GSM                                                                          |                     |
|                            |   - key=catalog_region, value=specify comma separated region name for catalog db deployment                              |                     |
| SHARD_DIRECTOR_PARAMS      | Accept key value pair separated by semicolon e.g. key1=value1;key2=value2 for following key=value pairs:                 | Mandatory           |
|                            |   - key=director_name, value=shard director name                                                                         |                     |
|                            |   - key=director_region, value=shard director region                                                                     |                     |
|                            |   - key=director_port, value=shard director port                                                                         |                     |
| SHARD[1-9]_PARAMS          | Accept key value pair separated by semicolon e.g. key1=value1;key2=value2 for following key=value pairs:                 | Mandatory           |
|                            |   - key=shard_host, value=shard hostname                                                                                 |                     |
|                            |   - key=shard_db, value=shard cdb name                                                                                   |                     |
|                            |   - key=shard_pdb, value=shard pdb name                                                                                  |                     |
|                            |   - key=shard_port, value=shard db port                                                                                  |                     |
|                            |   - key=shard_space, value=shard space name                                                                              |                     |
|                            |   - key=deploy_as, value=primary or standby                                                                              |                     |
|                            |   - key=shard_region, value=region name                                                                                  |                     |
| SERVICE[1-9]_PARAMS        | Accept key value pair separated by semicolon e.g. key1=value1;key2=value2 for following key=value pairs:                 | Mandatory           |
|                            |   - key=service_name, value=service name                                                                                 |                     |
|                            |   - key=service_role, value=service role e.g. primary or physical_standby                                                |                     |
| GSM_TRACE_LEVEL            | Specify tacing level for the GSM(Specify USER or ADMIN or SUPPORT or OFF, default value as OFF)                          | Optional            |
| COMMON_OS_PWD_FILE         | Specify the encrypted password file to be read inside container                                                          | Mandatory           |
| PWD_KEY                    | Specify the podman secret for the password key file to decrypt the encrypted password file and read the password         | Mandatory           |
| OP_TYPE                    | Specify the operation type. For GSM it has to be set to gsm.                                                             | Mandatory           |
| DOMAIN                     | Domain of the container.                                                                                                 | Mandatory           |
| MASTER_GSM                 | Set value to "TRUE" if you want the GSM to be a master GSM. Otherwise, do not set it.                                    | Mandatory           |
| SAMPLE_SCHEMA              | Specify a value to "DEPLOY" if you want to deploy sample app schema in catalog DB during GSM setup.                      | Optional            |
| CUSTOM_SHARD_SCRIPT_DIR    | Specify the location of custom scripts that you want to run after setting up GSM.                                        | Optional            |
| CUSTOM_SHARD_SCRIPT_FILE   | Specify the file name which must be available on CUSTOM_SHARD_SCRIPT_DIR location to be executed after GSM setup.        | Optional            |
| BASE_DIR                   | Specify BASE_DIR if you want to change the base location of the scripts to setup GSM.                                    | Optional            |
| SCRIPT_NAME                | Specify the script name which will be executed from BASE_DIR. Default set to main.py.                                    | Optional            |
| EXECUTOR                   | Specify the script executor such as /bin/python or /bin/bash. Default set to /bin/python.                                | Optional            |

## Support

Oracle Globally Distributed Database on Docker is supported on Oracle Linux 7.
Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and onwards.

## License

To run Oracle Globally Distributed Database, regardless whether inside or outside a Container, ensure to download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
