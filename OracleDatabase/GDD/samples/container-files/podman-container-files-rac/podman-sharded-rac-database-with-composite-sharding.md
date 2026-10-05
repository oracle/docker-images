# Deploy Oracle Globally Distributed Database (GDD) with Composite Sharding and Data Guard Replication on Oracle RAC

This guide provides detailed instructions for manually deploying a sample Oracle Globally Distributed Database with Composite Sharding and Data Guard Replication using Oracle RAC on Podman containers. The deployment uses Extended Oracle RAC Database Container Image.

- [Deploy Oracle Globally Distributed Database (GDD) with Composite Sharding and Data Guard Replication on Oracle RAC](#deploy-oracle-globally-distributed-database-gdd-with-composite-sharding-and-data-guard-replication-on-oracle-rac)
  - [Deployment Overview](#deployment-overview)
  - [Prerequisites](#prerequisites)
  - [Oracle Wallet Configuration for Oracle RAC](#oracle-wallet-configuration-for-oracle-rac)
  - [Deploy the Catalog Database](#deploy-the-catalog-database)
    - [Storage for ASM Disks for Catalog Containers](#storage-for-asm-disks-for-catalog-containers)
    - [Create Containers](#create-containers)
  - [Deploy the Shard Databases](#deploy-the-shard-databases)
    - [Storage for ASM Disks for Shard Containers](#storage-for-asm-disks-for-shard-containers)
    - [Shard1 Containers](#shard1-containers)
    - [Shard2 Containers](#shard2-containers)
  - [Deploy the Primary GSM Container](#deploy-the-primary-gsm-container)
    - [Create the Primary GSM Data Directory](#create-the-primary-gsm-data-directory)
    - [Create the Primary GSM Container](#create-the-primary-gsm-container)
  - [Deploy the Standby GSM Container](#deploy-the-standby-gsm-container)
    - [Create the Standby GSM Data Directory](#create-the-standby-gsm-data-directory)
    - [Create the Standby GSM Container](#create-the-standby-gsm-container)
  - [Scale-out an existing Oracle Globally Distributed Database](#scale-out-an-existing-oracle-globally-distributed-database)
    - [Storage for ASM Disk for the New Shard Container](#storage-for-asm-disk-for-the-new-shard-container)
    - [Create the New Shard Container](#create-the-new-shard-container)
    - [Add the Shard to the Existing GDD Topology](#add-the-shard-to-the-existing-gdd-topology)
    - [Deploy the Shard](#deploy-the-shard)
  - [Scale-in an existing Oracle Globally Distributed Database](#scale-in-an-existing-oracle-globally-distributed-database)
    - [Verify the Shard](#verify-the-shard)
    - [Move Chunks from the Shard](#move-chunks-from-the-shard)
    - [Delete the Shard](#delete-the-shard)
    - [Verify Shard Removal](#verify-shard-removal)
    - [Remove the Shard Containers](#remove-the-shard-containers)
  - [Environment Variables](#environment-variables)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Deployment Overview

The initial deployment consists of the following Podman containers:

- one catalog database container
- two shard database containers
- one primary GSM container
- one standby GSM container

**Note:** This sample uses Oracle AI Database 26ai RAC and GSM Podman images. You can also use supported Oracle Database 19c or 21c images.

## Prerequisites

Before using this guide to create a sample Oracle Globally Distributed Database, complete the prerequisite steps in [Oracle Globally Distributed Database using Oracle RAC Database on Podman Containers](./README.md#prerequisites)

## Oracle Wallet Configuration for Oracle RAC

Beginning with Oracle Database 21c, Oracle Globally Distributed Database uses Oracle wallets to establish trust between the shard catalog and shard databases. During deployment, these wallets are created automatically and are used to securely exchange metadata and configuration information between distributed database components. For more information, see the Oracle Database documentation: [Using Wallets for Oracle Globally Distributed Database](https://docs.oracle.com/en/database/oracle/oracle-database/26/shard/using-wallets.html).

- The shard catalog wallet is created when the `GDSCTL CREATE SHARDCATALOG` command is executed.
- Shard wallets are created when the `GDSCTL DEPLOY` command is executed.

For Oracle RAC deployments, the `WALLET_ROOT` parameter must reference a shared location that is accessible from every Oracle RAC instance belonging to the same database. The wallet location does **not** need to be shared across different databases (for example, between the catalog database and shard databases), but it **must** be shared by all Oracle RAC instances of the same database.

In this deployment, the shared wallet directories are hosted on an NFS filesystem mounted on both Podman hosts.

- `/mnt/shared_wallet_dir/catalog` is shared by both Oracle RAC instances of the catalog database.
- `/mnt/shared_wallet_dir/shard1` is shared by both Oracle RAC instances of the `shard1` database.
- `/mnt/shared_wallet_dir/shard2` is shared by both Oracle RAC instances of the `shard2` database.
- `/mnt/shared_wallet_dir/shard3` is shared by both Oracle RAC instances of the `shard3` database.

Each database container must configure the shared wallet location using the `WALLET_ROOT` environment variable and mount the corresponding shared directory into the container. The deployment examples in this guide include both the required environment variable and the associated volume mount.

Deploy the catalog and shard containers before creating the GSM containers. Complete the following steps in order:

## Deploy the Catalog Database

The shard catalog is a special-purpose Oracle Database that is a persistent store for SDB configuration data and plays a key role in the automated deployment and centralized management of an Oracle Globally Distributed Database. It also hosts the gold schema of the application and the master copies of common reference data (duplicated tables). In this example, the Catalog Database will be deployed as a two-node Oracle RAC database using two Podman containers on separate host machines.

### Storage for ASM Disks for Catalog Containers

Ensure that you have created at least one block device with at least 50 GB of storage that is accessible to the catalog containers. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
dd if=/dev/zero of=/dev/disk/by-partlabel/catalog_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

**NOTE:** The block device must be attached to both host machines because it is used as shared storage by the Oracle RAC database.

### Create Containers

Before creating the `catalog` container, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,catalog"` and `CRS_RACDB="true"` to use Oracle RAC to configure the catalog for the sharded database deployment.
- If you are using the Extended Oracle RAC Database `SLIM` image instead of the full image, use the following additional parameters during container creation. You may need to change these values for your environment:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/23.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/23.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/23.26.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/catalog:/u01 \
  --volume /stage:/stage \
  ```

  In this example:
  - `/scratch/rac/catalog` is the host directory mounted at `/u01` inside the container and is used as the software installation location. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have read and write access to this directory.
  - `/stage` is the host directory mounted at `/stage` inside the container and is used to stage the Grid and database software binaries. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have at least read access to this directory.

- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/catalog
  restorecon -v /scratch/rac/catalog
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

First, provision the Oracle RAC node 2 on the second host machine by running the following command:

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
--memory 24G \
--memory-swap 32G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=CATCDB \
-e DB_UNIQUE_NAME=CATCDB \
-e ORACLE_PDB_NAME=CAT1PDB \
-e OP_TYPE="setuprac,catalog" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=cataloga1 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/catalog" \
-v /mnt/shared_wallet_dir/catalog:/mnt/shared_wallet_dir/catalog \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name cataloga2 oracle/database-rac-ext-sharding:23.26.0-ee

podman network disconnect podman cataloga2
podman network connect shard_rac_pub1_nw --ip 10.0.15.29 cataloga2
podman network connect shard_rac_priv1_nw --ip 10.0.16.29 cataloga2
podman network connect shard_rac_priv2_nw --ip 10.0.17.29 cataloga2
podman start cataloga2
```

To check the cataloga2 container creation logs, please tail podman logs:

```bash
podman exec cataloga2 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from cataloga1 (Oracle RAC node 1), the container logs for cataloga2 container will display the following message:
  
```text
          =====================================
          Grid is not installed on this machine
          =====================================
```

- Now, provision the Oracle RAC node 1 on the first host machine by running the following command:

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
--memory 24G \
--memory-swap 32G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=CATCDB \
-e DB_UNIQUE_NAME=CATCDB \
-e ORACLE_PDB_NAME=CAT1PDB \
-e OP_TYPE="setuprac,catalog" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=cataloga1 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/catalog" \
-v /mnt/shared_wallet_dir/catalog:/mnt/shared_wallet_dir/catalog \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name cataloga1 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman cataloga1
podman network connect shard_rac_pub1_nw --ip 10.0.15.28 cataloga1
podman network connect shard_rac_priv1_nw --ip 10.0.16.28 cataloga1
podman network connect shard_rac_priv2_nw --ip 10.0.17.28 cataloga1
podman start cataloga1
```

To check the cataloga1 container creation logs, please tail podman logs:

```bash
podman exec cataloga1 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from cataloga1 (Oracle RAC node 1), the container logs for cataloga1 container will display the following message once the Oracle RAC Database Deployment completes:

```text
        ===================================
        ORACLE RAC DATABASE IS READY TO USE
        ===================================
```

Now, monitor the Oracle Shard creation using the following command on the first host machine:

```bash
podman exec cataloga1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
      GSM Catalog Setup Completed
==============================================
```

## Deploy the Shard Databases

A database shard is a horizontal partition of data in an Oracle Globally Distributed Database. In this example, each Shard Database will be deployed as a two-node Oracle RAC Database using two Podman containers on separate host machines.

### Storage for ASM Disks for Shard Containers

Ensure that you have created at least one block device with at least 50 GB of storage for each shard container. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command. Each storage device must be accessible to the shard container to which it is assigned.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
dd if=/dev/zero of=/dev/disk/by-partlabel/shard1_asm_disk  bs=8k count=10000
dd if=/dev/zero of=/dev/disk/by-partlabel/shard2_asm_disk  bs=8k count=10000
```

Repeat this command for each block device assigned to a shard container.

**NOTE:** The block device for each shard must be attached to both host machines because it is used as shared storage by the Oracle RAC database for that shard.

### Shard1 Containers

Before creating the containers for Shard1 Oracle RAC Database, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_RACDB="true"` to use Oracle RAC to configure the shard for the sharded database deployment.
- If you are using the Extended Oracle RAC Database `SLIM` image instead of the full image, use the following additional parameters during container creation. You may need to change these values for your environment:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/23.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/23.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/23.26.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard1:/u01 \
  --volume /stage:/stage \
  ```

  In this example:
  - `/scratch/rac/shard1` is the host directory mounted at `/u01` inside the container and is used as the software installation location. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have read and write access to this directory.
  - `/stage` is the host directory mounted at `/stage` inside the container and is used to stage the Grid and database software binaries. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have at least read access to this directory.

- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard1
  restorecon -v /scratch/rac/shard1
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```  

- First, provision the Oracle RAC node 2 on the second host machine by running the following command:

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
--memory 24G \
--memory-swap 32G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=ORCL1CDB \
-e DB_UNIQUE_NAME=ORCL1CDB \
-e ORACLE_PDB_NAME=ORCL1PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda11 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard1" \
-v /mnt/shared_wallet_dir/shard1:/mnt/shared_wallet_dir/shard1 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda12 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman sharda12
podman network connect shard_rac_pub1_nw --ip 10.0.15.31 sharda12
podman network connect shard_rac_priv1_nw --ip 10.0.16.31 sharda12
podman network connect shard_rac_priv2_nw --ip 10.0.17.31 sharda12
podman start sharda12
```

To check the sharda12 container creation logs, please tail podman logs:

```bash
podman exec sharda12 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from sharda11 (Oracle RAC node 1), the container logs for sharda12 container will display the following message:

```text
          =====================================
          Grid is not installed on this machine
          =====================================
```

- Now, provision the Oracle RAC node 1 on the first host machine by running the following command:

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
--memory 24G \
--memory-swap 36G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=ORCL1CDB \
-e DB_UNIQUE_NAME=ORCL1CDB \
-e ORACLE_PDB_NAME=ORCL1PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda11 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard1" \
-v /mnt/shared_wallet_dir/shard1:/mnt/shared_wallet_dir/shard1 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda11 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman sharda11
podman network connect shard_rac_pub1_nw --ip 10.0.15.30 sharda11
podman network connect shard_rac_priv1_nw --ip 10.0.16.30 sharda11
podman network connect shard_rac_priv2_nw --ip 10.0.17.30 sharda11
podman start sharda11
```

To check the sharda11 container creation logs, please tail podman logs on the first host machine:

```bash
podman exec sharda11 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from sharda11 (Oracle RAC node 1), the container logs for sharda11 container will display the following message once the Oracle RAC Database Deployment completes:

```text
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using the following command on the first host machine:

```bash
podman exec sharda11 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Shard2 Containers

Before creating the containers for Shard2 Oracle RAC Database, review the following notes carefully:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_RACDB="true"` to use Oracle RAC to configure the shard for the sharded database deployment.
- If you are using the Extended Oracle RAC Database `SLIM` image instead of the full image, use the following additional parameters during container creation. You may need to change these values for your environment:

  ```bash
  -e DB_BASE=/u01/app/oracle \
  -e DB_HOME=/u01/app/oracle/product/23.0.0/dbhome_1 \
  -e GRID_HOME=/u01/app/23.0.0/grid \
  -e GRID_BASE=/u01/app/grid \
  -e INVENTORY=/u01/app/oraInventory \
  -e COPY_GRID_SOFTWARE=true \
  -e COPY_DB_SOFTWARE=true \
  -e STAGING_SOFTWARE_LOC=/stage/software/23.26.0 \
  -e GRID_SW_ZIP_FILE=grid_home.zip \
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard2:/u01 \
  --volume /stage:/stage \
  ```

  In this example:
  - `/scratch/rac/shard2` is the host directory mounted at `/u01` inside the container and is used as the software installation location. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have read and write access to this directory.
  - `/stage` is the host directory mounted at `/stage` inside the container and is used to stage the Grid and database software binaries. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have at least read access to this directory.

- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard2
  restorecon -v /scratch/rac/shard2
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

- First, provision the Oracle RAC node 2 on the second host machine by running the following command:

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
--memory 24G \
--memory-swap 32G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=ORCL2CDB \
-e DB_UNIQUE_NAME=ORCL2CDB \
-e ORACLE_PDB_NAME=ORCL2PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda21 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard2" \
-v /mnt/shared_wallet_dir/shard2:/mnt/shared_wallet_dir/shard2 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda22 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman sharda22
podman network connect shard_rac_pub1_nw --ip 10.0.15.33 sharda22
podman network connect shard_rac_priv1_nw --ip 10.0.16.33 sharda22
podman network connect shard_rac_priv2_nw --ip 10.0.17.33 sharda22
podman start sharda22
```

To check the sharda22 container creation logs, please tail podman logs:

```bash
  podman exec sharda22 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from sharda21 (Oracle RAC node 1), the container logs for sharda22 container will display the following message:

```text
          =====================================
          Grid is not installed on this machine
          =====================================
```

- Now, provision the Oracle RAC node 1 on the first host machine by running the following command:

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
--memory 24G \
--memory-swap 36G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DEFAULT_GATEWAY="10.0.15.1" \
-e DB_NAME=ORCL2CDB \
-e DB_UNIQUE_NAME=ORCL2CDB \
-e ORACLE_PDB_NAME=ORCL2PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda21 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard2" \
-v /mnt/shared_wallet_dir/shard2:/mnt/shared_wallet_dir/shard2 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda21 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman sharda21
podman network connect shard_rac_pub1_nw --ip 10.0.15.32 sharda21
podman network connect shard_rac_priv1_nw --ip 10.0.16.32 sharda21
podman network connect shard_rac_priv2_nw --ip 10.0.17.32 sharda21
podman start sharda21
```

To check the sharda21 container creation logs, please tail podman logs on the first host machine:

```bash
  podman exec sharda21 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from sharda21 (Oracle RAC node 1), the container logs for sharda21 container will display the following message once the Oracle RAC Database Deployment completes:

```text
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using the following command on the first host machine:

```bash
podman exec sharda21 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

## Deploy the Primary GSM Container

Create a directory on the Podman host to store the GSM configuration data and mount it at `/opt/oracle/gsmdata` in the primary GSM container. The directory can reside on local storage or supported shared storage. This sample uses `/scratch/oradata/dbfiles/GSM1DATA`.

**Note:** In this setup, both the Master and Standby GSM containers are deployed on the first host machine. You can also deploy one GSM container on the first host machine and the other on the second host machine.

### Create the Primary GSM Data Directory

```bash
mkdir -p /scratch/oradata/dbfiles/GSM1DATA
chown -R 54321:54321 /scratch/oradata/dbfiles/GSM1DATA
```

If SELinux is enabled on the Podman host, run the following commands:

```bash
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/GSM1DATA
restorecon -v /scratch/oradata/dbfiles/GSM1DATA
```

### Create the Primary GSM Container

```bash
podman create -t -i \
--hostname gsma1 \
--dns-search=example.info \
--dns 10.0.15.25 \
-e DOMAIN=example.info \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522" \
-e SHARD1_SPACE_PARAMS='sspace_name=gold;chunks=120;protectmode=maxavailability' \
-e SHARD2_SPACE_PARAMS='sspace_name=silver;chunks=120;protectmode=maxavailability' \
-e SHARD1_GROUP_PARAMS="group_name=shardgroup1;deploy_as=primary;group_region=region1;shardspace=gold" \
-e CATALOG_PARAMS='catalog_host=cataloga-scan;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_comp_pri;catalog_region=region1,region2;sharding_type=composite;repl_type=DG;shard_space=gold,silver' \
-e SHARD1_PARAMS="shard_host=sharda1-scan;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
-e SHARD2_PARAMS="shard_host=sharda2-scan;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary;service_mode=readwrite" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary;service_mode=readonly" \
-e GSM_TRACE_LEVEL="OFF" \
-e INVITED_NODE_SUBNET_FLAG=TRUE \
-e COMMON_OS_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e OP_TYPE=gsm \
-e MASTER_GSM="TRUE" \
-e SHARD_SETUP="true" \
--secret pwdsecret \
--secret keysecret \
-v /scratch/oradata/dbfiles/GSM1DATA:/opt/oracle/gsmdata \
--restart=always \
--privileged=false \
--name gsma1 oracle/database-gsm:23.26.0
  
podman network disconnect podman gsma1
podman network connect shard_rac_pub1_nw --ip 10.0.15.26 gsma1
podman start gsma1
```

**Note:** Change environment variables such as `DOMAIN`, `CATALOG_PARAMS`, `SHARD1_SPACE_PARAMS`, `SHARD2_SPACE_PARAMS`, `SHARD1_GROUP_PARAMS`, `COMMON_OS_PWD_FILE`, and `PWD_KEY` as required for your environment.

Monitor the primary GSM container logs:

```bash
podman exec gsma1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
     GSM Setup Completed                      
==============================================
```

## Deploy the Standby GSM Container

Deploy a standby GSM container to provide connection availability if the primary GSM becomes unavailable.

### Create the Standby GSM Data Directory

```bash
mkdir -p /scratch/oradata/dbfiles/GSM2DATA
chown -R 54321:54321 /scratch/oradata/dbfiles/GSM2DATA
```

If SELinux is enabled on the Podman host, run the following commands:

```bash
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/GSM2DATA
restorecon -v /scratch/oradata/dbfiles/GSM2DATA
```

### Create the Standby GSM Container

```bash
podman create -i -t \
--hostname gsma2 \
--dns-search=example.info \
--dns 10.0.15.25 \
-e DOMAIN=example.info \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
-e CATALOG_PARAMS='catalog_host=cataloga-scan;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_comp_pri;catalog_region=region1,region2;sharding_type=composite;repl_type=DG;shard_space=gold,silver' \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=standby;service_mode=readwrite" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=standby;service_mode=readonly" \
-e INVITED_NODE_SUBNET_FLAG=TRUE \
-e GSM_TRACE_LEVEL="OFF" \
-e CATALOG_SETUP="True" \
-e COMMON_OS_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e OP_TYPE=gsm \
-e SHARD_SETUP="true" \
--secret pwdsecret \
--secret keysecret \
-v /scratch/oradata/dbfiles/GSM2DATA:/opt/oracle/gsmdata \
--privileged=false \
--name gsma2 oracle/database-gsm:23.26.0

podman network disconnect podman gsma2
podman network connect shard_rac_pub1_nw --ip 10.0.15.27 gsma2
podman start gsma2
```

**Note:** Change environment variables such as `DOMAIN`, `CATALOG_PARAMS`, `COMMON_OS_PWD_FILE`, and `PWD_KEY` as required for your environment.

Monitor the standby GSM container logs:

```bash
podman exec gsma2 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
     GSM Setup Completed                      
==============================================
```

## Scale-out an existing Oracle Globally Distributed Database

To scale out an existing Oracle Globally Distributed Database deployment, complete the following steps in order:

- Prepare the host for the new shard.
- Create Oracle RAC containers.
- Add the shard to the existing GDD topology.
- Deploy the shard.

The following example adds a new shard (`shard3`) to the existing two-shard deployment (`shard1` and `shard2`) created earlier in this guide.

### Storage for ASM Disk for the New Shard Container

Ensure that you have created at least one block device with at least 50 GB of storage for the Shard3 containers. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command. Each storage device must be accessible to the shard container to which it is assigned.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
dd if=/dev/zero of=/dev/disk/by-partlabel/shard3_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

### Create the New Shard Container

Before creating the new shard containers (shard3 in this example), review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_RACDB="true"` to use Oracle RAC to configure `sharda31` and `sharda32` for the sharded database deployment.
- If you are using the Extended Oracle RAC Database `SLIM` image instead of the full image, use the following additional parameters during container creation. You may need to change these values for your environment:

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
  -e DB_SW_ZIP_FILE=db_home.zip \
  --volume /scratch/rac/shard3:/u01 \
  --volume /stage:/stage \
  ```

  In this example,
  - `/scratch/rac/shard3` is the host location which will be mapped to `/u01` inside the container to use as the software installation home location. This host location should be having correct permissions set at the host level to be read/write enabled from the container by users oracle (uid: 54321) and grid (uid: 54322).
  - `/stage` is the host location mapped to `/stage` inside the container to use for staging the Grid and DB Software binaries. This location needs atleast read permission from the container by the users oracle (uid: 54321) and grid (uid: 54322).

- If SELinux is enabled on podman host, then execute following commands to set the contexts for the host locations you want to mount and use inside the container:
  
  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard3
  restorecon -v /scratch/rac/shard3
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

- First, provision Oracle RAC node 2 on the second host machine by running the following command:

```bash
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
--memory 24G \
--memory-swap 32G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DB_NAME=ORCL3CDB \
-e DB_UNIQUE_NAME=ORCL3CDB \
-e ORACLE_PDB_NAME=ORCL3PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda31 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard3" \
-v /mnt/shared_wallet_dir/shard3:/mnt/shared_wallet_dir/shard3 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda32 oracle/database-rac-ext-sharding:23.26.0-ee


podman network disconnect podman sharda32
podman network connect shard_rac_pub1_nw --ip 10.0.15.35 sharda32
podman network connect shard_rac_priv1_nw --ip 10.0.16.35 sharda32
podman network connect shard_rac_priv2_nw --ip 10.0.17.35 sharda32
podman start sharda32
```

To check the sharda32 container creation logs, please tail podman logs:

```bash
podman exec sharda32 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

- Now, provision the Oracle RAC node 1 on the first host machine by running the following command:

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
--memory 24G \
--memory-swap 36G \
--sysctl kernel.shmall=4194304 \
--sysctl "kernel.sem=250 32000 100 128" \
--sysctl kernel.shmmax=17179869184 \
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
-e DB_NAME=ORCL3CDB \
-e DB_UNIQUE_NAME=ORCL3CDB \
-e ORACLE_PDB_NAME=ORCL3PDB \
-e OP_TYPE="setuprac,primaryshard" \
-e CRS_RACDB="true" \
-e DB_PWD_FILE=pwdsecret \
-e PWD_KEY=keysecret \
-e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-e INIT_SGA_SIZE=12G \
-e INIT_PGA_SIZE=6G \
-e INSTALL_NODE=sharda31 \
-e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
-e CRS_ASM_DISCOVERY_DIR="/dev/asm-disk*" \
-e CRS_ASM_DISKGROUP='+CRSDATA' \
-e DNS_SERVERS=10.0.15.25 \
-e WALLET_ROOT="/mnt/shared_wallet_dir/shard3" \
-v /mnt/shared_wallet_dir/shard3:/mnt/shared_wallet_dir/shard3 \
--secret pwdsecret \
--secret keysecret \
${DEVICE} \
--health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
--restart=always \
--ulimit rtprio=99  \
--systemd=always \
--privileged=false \
--name sharda31 oracle/database-rac-ext-sharding:23.26.0-ee
  
podman network disconnect podman sharda31
podman network connect shard_rac_pub1_nw --ip 10.0.15.34 sharda31
podman network connect shard_rac_priv1_nw --ip 10.0.16.34 sharda31
podman network connect shard_rac_priv2_nw --ip 10.0.17.34 sharda31
podman start sharda31
```

To check the sharda31 container creation logs, please tail podman logs on the first host machine:

```bash
  podman exec sharda31 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Because the installation is performed from sharda31 (Oracle RAC node 1), the container logs for sharda31 container will display the following message once the Oracle RAC Database Deployment completes:

```text
          ===================================
          ORACLE RAC DATABASE IS READY TO USE
          ===================================
```

Now, monitor the Oracle Shard creation using the following command on the first host machine:

```bash
podman exec sharda31 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Add the Shard to the Existing GDD Topology

Run the following command to add `shard3` to the GDD topology:

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py --addshard="shard_host=sharda3-scan;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
```

Run the following command to check the status of the newly added shard:

``` bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard
```

### Deploy the Shard

Deploy the newly added shard (shard3):

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py --deployshard=true
```

Verify the newly added shard and its chunk distribution:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

**Note:** Chunk redistribution after deploying the new shard may take some time to complete.

Check if any chunk movement has gone into `Suspended` status apart from `Running` or `Scheduled` status in the output of the below command:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks -show_reshard
```

In case of `Suspended` status of any chunk movement, you can resume that running the following command:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl alter move -resume
```

## Scale-in an existing Oracle Globally Distributed Database

To scale in an existing Oracle Globally Distributed Database deployment by removing a shard, complete the following steps in order:

- Verify the shard.
- Move chunks from the shard.
- Delete the shard.
- Verify shard removal.
- Remove the shard container.

### Verify the Shard

Verify that the shard to be removed is registered and check its current chunk distribution:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Move Chunks from the Shard

In this example, run the following command to move all chunks from shard3 before removing the shard:

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py --movechunks="shard_db=ORCL3CDB;shard_pdb=ORCL3PDB"
```

**Note:** In this example, `ORCL3CDB` and `ORCL3PDB` are the CDB and PDB names, respectively, for  shard3.

**NOTE:** You may need to repeat the above command until all the chunks are moved out of the Shard to be deleted.

Check if any chunk movement has gone into `Suspended` status apart from `Running` or `Scheduled` status and resume it using the commands described in the previous section.

Verify that no chunks remain on `shard3`:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

**Note:** Chunk redistribution may take some time. Rerun the `gdsctl config chunks` command periodically until no chunks remain on the shard being removed.

### Delete the Shard

After confirming that no chunks remain on shard3, run the following command to remove it from the GDD topology:

```bash
podman exec -it gsma1 python /opt/oracle/scripts/sharding/scripts/main.py  --deleteshard="shard_host=sharda3-scan;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
```

**NOTE:** In this example, `sharda3-scan`, `ORCL3CDB` and `ORCL3PDB` are the SCAN Name, CDB name and PDB name for the shard3 respectively.

### Verify Shard Removal

After removing the shard from the GDD topology, verify the remaining shards and chunk distribution:

```bash
podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsma1 $(podman exec -it gsma1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Remove the Shard Containers

After removing the shard from the GDD topology, remove its Podman containers and data directory:

If the deleted shard was shard3, to remove its Podman Containers, please use the below steps:

- Stop and remove the shard3 containers:

```bash
podman stop sharda32
podman rm sharda32

podman stop sharda31
podman rm sharda31
```

- If you have used Extended Oracle RAC Database `SLIM` Image instead of the full image, then remove the directory `/scratch/rac/shard3` containing the files for these deleted Podman Containers from the both host machines:

```bash
rm -rf /scratch/rac/shard3
```

## Environment Variables

**For catalog and shard containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `DB_NAME` | CDB name. | Mandatory |
| `ORACLE_PDB_NAME` | PDB name. | Mandatory |
| `CRS_RACDB` | Set to `true` to configure Oracle RAC Database. | Mandatory |
| `DB_PWD_FILE` | Podman secret containing the encrypted database password file. | Mandatory |
| `PWD_KEY` | Podman secret containing the key used to decrypt the password file. | Mandatory |
| `PKEYOPT` | RSA options used to decrypt the encrypted password file. | Mandatory |
| `OP_TYPE` | Operation type for the catalog or shard container. Set to `catalog`, `primaryshard`, or `standbyshard`. | Mandatory |
| `SHARD_SETUP` | Set to `true` to initiate the sharding scripts. | Mandatory |
| `ENABLE_ARCHIVELOG` | Set to `true` to enable ARCHIVELOG mode. | Mandatory |
| `INIT_SGA_SIZE` | Initial SGA size for the database. | Optional |
| `INIT_PGA_SIZE` | Initial PGA size for the database. | Optional |
| `INSTALL_NODE` | Hostname of the Oracle Restart installation node. | Mandatory |
| `CRS_ASM_DEVICE_LIST` | List of ASM devices available to Oracle Restart. | Mandatory |
| `DNS_SERVERS` | DNS server used by the container. | Mandatory |
| `PUBLIC_HOSTS_DOMAIN` | Public domain used for container host name resolution. | Mandatory |
| `CUSTOM_SHARD_SCRIPT_DIR` | Directory containing custom scripts to run after shard setup. | Optional |
| `CUSTOM_SHARD_SCRIPT_FILE` | Custom script file available in `CUSTOM_SHARD_SCRIPT_DIR` to run after shard setup. | Optional |

**For GSM containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `CATALOG_SETUP` | When set to `True`, creates the GSM director and adds the catalog without adding shards. Used when configuring the standby GSM. | Optional |
| `CATALOG_PARAMS` | Semicolon-separated catalog configuration parameters, including `catalog_host`, `catalog_db`, `catalog_pdb`, `catalog_port`, `catalog_name`, `catalog_region`, `sharding_type`, `repl_type`, `shard_space`, and `force`. | Mandatory |
| `SHARD_DIRECTOR_PARAMS` | Semicolon-separated shard director parameters: `director_name`, `director_region`, and `director_port`. | Mandatory |
| `SHARD[1-9]_SPACE_PARAMS` | Semicolon-separated shardspace parameters, including `sspace_name`, `chunks`, and `protectmode`. | Mandatory |
| `SHARD[1-9]_GROUP_PARAMS` | Semicolon-separated shard group parameters, including `group_name`, `deploy_as`, `group_region`, and `shardspace`. | Mandatory |
| `SHARD[1-9]_PARAMS` | Semicolon-separated shard parameters, including `shard_host`, `shard_db`, `shard_pdb`, `shard_port`, `shard_group`, and `shard_region`. | Mandatory |
| `SERVICE[1-9]_PARAMS` | Semicolon-separated service parameters, including `service_name`, `service_role`, and `service_mode`. | Mandatory |
| `GSM_TRACE_LEVEL` | GSM tracing level. Supported values are `USER`, `ADMIN`, `SUPPORT`, and `OFF`. The default is `OFF`. | Optional |
| `COMMON_OS_PWD_FILE` | Podman secret containing the encrypted password file. | Mandatory |
| `PWD_KEY` | Podman secret containing the key used to decrypt the encrypted password file. | Mandatory |
| `PKEYOPT` | RSA encryption options used to decrypt the password file. | Mandatory |
| `OP_TYPE` | Operation type for the GSM container. Set to `gsm`. | Mandatory |
| `SHARD_SETUP` | Set to `true` to initiate the sharding scripts. | Mandatory |
| `DOMAIN` | Domain of the container. | Mandatory |
| `MASTER_GSM` | Set to `TRUE` for the primary GSM. Leave unset for a standby GSM. | Optional |
| `SAMPLE_SCHEMA` | Set to `DEPLOY` to deploy the sample application schema in the catalog database during GSM setup. | Optional |
| `CUSTOM_SHARD_SCRIPT_DIR` | Directory containing custom scripts to run after GSM setup. | Optional |
| `CUSTOM_SHARD_SCRIPT_FILE` | Custom script file available in `CUSTOM_SHARD_SCRIPT_DIR` to run after GSM setup. | Optional |
| `BASE_DIR` | Base directory containing the GSM setup scripts. | Optional |
| `SCRIPT_NAME` | Setup script to execute. The default is `main.py`. | Optional |
| `EXECUTOR` | Interpreter used to execute the setup script. The default is `/bin/python`. | Optional |

## Support

- Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and later releases.

## License

To run Oracle Globally Distributed Database, regardless whether inside or outside a Container, ensure to download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
