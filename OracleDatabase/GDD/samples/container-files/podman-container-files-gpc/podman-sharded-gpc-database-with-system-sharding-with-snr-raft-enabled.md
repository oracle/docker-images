# Deploy Oracle GDD with System-Managed Sharding and Raft Replication using Oracle Restart

This guide provides detailed instructions for manually deploying a sample Oracle Globally Distributed Database with System-Managed Sharding and Raft Replication using Podman containers. The deployment uses Extended Oracle RAC Database Container Image.

- [Deploy Oracle GDD with System-Managed Sharding and Raft Replication using Oracle Restart](#deploy-oracle-gdd-with-system-managed-sharding-and-raft-replication-using-oracle-restart)
  - [Deployment Overview](#deployment-overview)
  - [Prerequisites](#prerequisites)
  - [Deploying Catalog Container](#deploying-catalog-container)
    - [Storage for ASM Disks for Catalog Container](#storage-for-asm-disks-for-catalog-container)
    - [Create Container](#create-container)
  - [Deploying Shard Containers](#deploying-shard-containers)
    - [Storage for ASM Disks for Shard Containers](#storage-for-asm-disks-for-shard-containers)
    - [Shard1 Container](#shard1-container)
    - [Shard2 Container](#shard2-container)
    - [Shard3 Container](#shard3-container)
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
    - [Move RUs from the Shard](#move-rus-from-the-shard)
    - [Delete the Shard](#delete-the-shard)
    - [Verify Shard Removal](#verify-shard-removal)
    - [Remove the Shard Container](#remove-the-shard-container)
  - [Environment Variables](#environment-variables)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Deployment Overview

This setup initially involves deploying Podman containers for:

- one catalog database container
- three shard database containers
- one primary GSM container
- one standby GSM container

**Note:** This sample uses Oracle AI Database 26ai RAC and GSM Podman images which support Raft Replication.

## Prerequisites

Before using this guide to create a sample Oracle Globally Distributed Database, complete the prerequisite steps in [Oracle Globally Distributed Database using Oracle Restart in Podman Containers](./README.md#prerequisites).

Deploy the catalog and shard containers before creating the GSM containers. Complete the following steps in order:

## Deploying Catalog Container

The shard catalog is a special-purpose Oracle Database that is a persistent store for SDB configuration data and plays a key role in the automated deployment and centralized management of an Oracle Globally Distributed Database. It also hosts the gold schema of the application and the master copies of common reference data (duplicated tables). In this case, the Catalog Database will be deployed using Oracle Restart and will be using ASM Storage.

### Storage for ASM Disks for Catalog Container

Ensure that you have created at least one block device with at least 50 GB of storage that is accessible to the catalog container. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/catalog_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

### Create Container

Before creating the `catalog` container, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,catalog"` and `CRS_GPC="true"` to use Oracle Restart to configure the catalog for the sharded database deployment.
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

  ```bash
  export DEVICE="--device=/dev/disk/by-partlabel/catalog_asm_disk:/dev/asm-disk1"
  export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

  podman create -t -i \
  --hostname dbmc1 \
  --dns-search example.info \
  --dns 172.20.1.250 \
  --shm-size 4G \
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
  -e DB_NAME=CATCDB \
  -e ORACLE_PDB_NAME=CAT1PDB \
  -e OP_TYPE="setuprac,catalog" \
  -e CRS_GPC="true" \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
  -e SHARD_SETUP="true" \
  -e ENABLE_ARCHIVELOG=true \
  -e INIT_SGA_SIZE=12G \
  -e INIT_PGA_SIZE=6G \
  -e INSTALL_NODE=dbmc1 \
  -e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
  -e DNS_SERVERS=172.20.1.250 \
  -e PUBLIC_HOSTS_DOMAIN=example.info \
  --secret pwdsecret \
  --secret keysecret \
  ${DEVICE} \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --privileged=false \
  --name catalog oracle/database-gpc-ext-sharding:23.26.0-ee

  podman network disconnect podman catalog
  podman network connect shard_rac_pub1_nw --ip 172.20.1.195 catalog
  podman start catalog
  ```

Monitor the Oracle Restart database setup:

```bash
  podman exec catalog /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

Then monitor the `catalog` setup:

```bash
podman exec catalog /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
      GSM Catalog Setup Completed
==============================================
```

## Deploying Shard Containers

A database shard is a horizontal partition of data in an Oracle Globally Distributed Database.

### Storage for ASM Disks for Shard Containers

Ensure that you have created at least one block device with at least 50 GB of storage for each shard container. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command. Each storage device must be accessible to the shard container to which it is assigned.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard1_asm_disk  bs=8k count=10000
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard2_asm_disk  bs=8k count=10000
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard3_asm_disk  bs=8k count=10000  
```

Repeat this command for each block device assigned to a shard container.

### Shard1 Container

Before creating the `shard1` container, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_GPC="true"` to use Oracle Restart to configure `shard1` for the sharded database deployment.
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

```bash
  export DEVICE="--device=/dev/disk/by-partlabel/shard1_asm_disk:/dev/asm-disk1"
  export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

  podman create -t -i \
  --hostname dbmc2 \
  --dns-search example.info \
  --dns 172.20.1.250 \
  --shm-size 4G \
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
  -e DB_NAME=ORCL1CDB \
  -e ORACLE_PDB_NAME=ORCL1PDB \
  -e OP_TYPE="setuprac,primaryshard" \
  -e CRS_GPC="true" \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
  -e SHARD_SETUP="true" \
  -e ENABLE_ARCHIVELOG=true \
  -e INIT_SGA_SIZE=12G \
  -e INIT_PGA_SIZE=6G \
  -e INSTALL_NODE=dbmc2 \
  -e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
  -e DNS_SERVERS=172.20.1.250 \
  -e PUBLIC_HOSTS_DOMAIN=example.info \
  --secret pwdsecret \
  --secret keysecret \
  ${DEVICE} \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --privileged=false \
  --name shard1 oracle/database-gpc-ext-sharding:23.26.0-ee

  podman network disconnect podman shard1
  podman network connect shard_rac_pub1_nw --ip 172.20.1.196 shard1
  podman start shard1
```

Monitor the Oracle Restart database setup:

```bash
  podman exec shard1 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

Then monitor the `shard1` setup:

```bash
podman exec shard1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Shard2 Container

Before creating the `shard2` container, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_GPC="true"` to use Oracle Restart to configure `shard2` for the sharded database deployment.
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

```bash
  export DEVICE="--device=/dev/disk/by-partlabel/shard2_asm_disk:/dev/asm-disk1"
  export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

  podman create -t -i \
  --hostname dbmc3 \
  --dns-search example.info \
  --dns 172.20.1.250 \
  --shm-size 4G \
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
  -e DB_NAME=ORCL2CDB \
  -e ORACLE_PDB_NAME=ORCL2PDB \
  -e OP_TYPE="setuprac,primaryshard" \
  -e CRS_GPC="true" \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
  -e SHARD_SETUP="true" \
  -e ENABLE_ARCHIVELOG=true \
  -e INIT_SGA_SIZE=12G \
  -e INIT_PGA_SIZE=6G \
  -e INSTALL_NODE=dbmc3 \
  -e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
  -e DNS_SERVERS=172.20.1.250 \
  -e PUBLIC_HOSTS_DOMAIN=example.info \
  --secret pwdsecret \
  --secret keysecret \
  ${DEVICE} \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --privileged=false \
  --name shard2 oracle/database-gpc-ext-sharding:23.26.0-ee

  podman network disconnect podman shard2
  podman network connect shard_rac_pub1_nw --ip 172.20.1.197 shard2
  podman start shard2
```

Monitor the Oracle Restart database setup:

```bash
  podman exec shard2 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

Then monitor the `shard2` setup:

```bash
podman exec shard2 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Shard3 Container

Before creating the `shard3` container, review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_GPC="true"` to use Oracle Restart to configure `shard3` for the sharded database deployment.
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
  --volume /scratch/rac/shard3:/u01 \
  --volume /stage:/stage \
  ```

  In this example:
  - `/scratch/rac/shard3` is the host directory mounted at `/u01` inside the container and is used as the software installation location. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have read and write access to this directory.
  - `/stage` is the host directory mounted at `/stage` inside the container and is used to stage the Grid and database software binaries. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have at least read access to this directory.

- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard3
  restorecon -v /scratch/rac/shard3
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

  ```bash
  export DEVICE="--device=/dev/disk/by-partlabel/shard3_asm_disk:/dev/asm-disk1"
  export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

  podman create -t -i \
  --hostname dbmc4 \
  --dns-search example.info \
  --dns 172.20.1.250 \
  --shm-size 4G \
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
  -e DB_NAME=ORCL3CDB \
  -e ORACLE_PDB_NAME=ORCL3PDB \
  -e OP_TYPE="setuprac,primaryshard" \
  -e CRS_GPC="true" \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
  -e SHARD_SETUP="true" \
  -e ENABLE_ARCHIVELOG=true \
  -e INIT_SGA_SIZE=12G \
  -e INIT_PGA_SIZE=6G \
  -e INSTALL_NODE=racnodep4 \
  -e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
  -e DNS_SERVERS=172.20.1.250 \
  -e PUBLIC_HOSTS_DOMAIN=example.info \
  --secret pwdsecret \
  --secret keysecret \
  ${DEVICE} \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --privileged=false \
  --name shard3 oracle/database-gpc-ext-sharding:23.26.0-ee

  podman network disconnect podman shard3
  podman network connect shard_rac_pub1_nw --ip 172.20.1.173 shard3
  podman start shard3
  ```

Monitor the Oracle Restart database setup:

```bash
  podman exec shard3 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

Then monitor the `shard3` setup:

```bash
podman exec shard3 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

## Deploy the Primary GSM Container

Create a directory on the Podman host to store the GSM configuration data and mount it at `/opt/oracle/gsmdata` in the primary GSM container. The directory can reside on local storage or supported shared storage. This sample uses `/scratch/oradata/dbfiles/GSM1DATA`.

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
 --dns 172.20.1.250 \
 -e DOMAIN=example.info \
 -e SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522" \
 -e SHARD1_GROUP_PARAMS="group_name=shardgroup1;group_region=region1;repfactor=3" \
 -e CATALOG_PARAMS="catalog_host=dbmc1;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_raft;catalog_region=region1,region2;sharding_type=system;catalog_chunks=30;repl_type=Native;repl_unit=2" \
 -e SHARD1_PARAMS="shard_host=dbmc2;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
 -e SHARD2_PARAMS="shard_host=dbmc3;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
 -e SHARD3_PARAMS="shard_host=dbmc4;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
 -e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary;service_mode=readwrite" \
 -e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary;service_mode=readonly" \
 -e GSM_TRACE_LEVEL="OFF" \
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
 --name gsm1 oracle/database-gsm:23.26.0

 podman network disconnect podman gsm1
 podman network connect shard_rac_pub1_nw --ip 172.20.1.26 gsm1
 podman start gsm1
```

**Note:** Change environment variables such as `DOMAIN`, `CATALOG_PARAMS`, `SHARD1_GROUP_PARAMS`, `COMMON_OS_PWD_FILE`, and `PWD_KEY` as required for your environment.

Monitor the primary GSM container logs:

```bash
podman exec gsm1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
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
 --dns 172.20.1.250 \
 -e DOMAIN=example.info \
 -e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
 -e CATALOG_PARAMS="catalog_host=dbmc1;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_raft;catalog_region=region1,region2;sharding_type=system;catalog_chunks=30;repl_type=Native;repl_unit=2" \
 -e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=standby;service_mode=readwrite" \
 -e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=standby;service_mode=readonly" \
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
 --name gsm2 oracle/database-gsm:23.26.0

  podman network disconnect podman gsm2
  podman network connect shard_rac_pub1_nw --ip 172.20.1.27 gsm2
  podman start gsm2
```

**Note:** Change environment variables such as `DOMAIN`, `CATALOG_PARAMS`, `COMMON_OS_PWD_FILE`, and `PWD_KEY` as required for your environment.

Monitor the standby GSM container logs:

```bash
podman exec gsm2 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
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
- Create the new shard container.
- Add the shard to the existing GDD topology.
- Deploy the shard.

The following example adds a new shard (`shard4`) to the existing three-shard deployment (`shard1`, `shard2`, and `shard3`) created earlier in this guide.

### Storage for ASM Disk for the New Shard Container

Ensure that you have created at least one block device with at least 50 GB of storage for the `shard4` container. You can create additional block devices as required and pass the corresponding devices and environment variables to the `podman create` command. Each storage device must be accessible to the shard container to which it is assigned.

Ensure that the ASM devices do not contain an existing filesystem. To clear an existing filesystem from the devices, run:

```bash
  dd if=/dev/zero of=/dev/disk/by-partlabel/shard4_asm_disk  bs=8k count=10000
```

Repeat this command on each shared block device.

### Create the New Shard Container

Before creating the new shard container (`shard4` in this example), review the following notes:

**Notes:**

- Change `DB_NAME` and `ORACLE_PDB_NAME` as required for your environment.
- Set `OP_TYPE="setuprac,primaryshard"` and `CRS_GPC="true"` to use Oracle Restart to configure `shard4` for the sharded database deployment.
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
  --volume /scratch/rac/shard4:/u01 \
  --volume /stage:/stage \
  ```

  In this example:
  - `/scratch/rac/shard4` is the host directory mounted at `/u01` inside the container and is used as the software installation location. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have read and write access to this directory.
  - `/stage` is the host directory mounted at `/stage` inside the container and is used to stage the Grid and database software binaries. Ensure that the `oracle` user (`UID 54321`) and `grid` user (`UID 54322`) have at least read access to this directory.

- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/rac/shard4
  restorecon -v /scratch/rac/shard4
  semanage fcontext -a -t container_file_t /stage
  restorecon -v /stage
  ```

  ```bash
  export DEVICE="--device=/dev/disk/by-partlabel/shard4_asm_disk:/dev/asm-disk1"
  export CRS_ASM_DEVICE_LIST="/dev/asm-disk1"

  podman create -t -i \
  --hostname dbmc5 \
  --dns-search example.info \
  --dns 172.20.1.250 \
  --shm-size 4G \
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
  -e DB_NAME=ORCL4CDB \
  -e ORACLE_PDB_NAME=ORCL4PDB \
  -e OP_TYPE="setuprac,primaryshard" \
  -e CRS_GPC="true" \
  -e DB_PWD_FILE=pwdsecret \
  -e PWD_KEY=keysecret \
  -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
  -e SHARD_SETUP="true" \
  -e ENABLE_ARCHIVELOG=true \
  -e INIT_SGA_SIZE=12G \
  -e INIT_PGA_SIZE=6G \
  -e INSTALL_NODE=dbmc5 \
  -e CRS_ASM_DEVICE_LIST=${CRS_ASM_DEVICE_LIST} \
  -e DNS_SERVERS=172.20.1.250 \
  -e PUBLIC_HOSTS_DOMAIN=example.info \
  --secret pwdsecret \
  --secret keysecret \
  ${DEVICE} \
  --health-cmd "/bin/python3 /opt/scripts/startup/scripts/main.py --checkracstatus" \
  --restart=always \
  --ulimit rtprio=99  \
  --systemd=always \
  --privileged=false \
  --name shard4 oracle/database-gpc-ext-sharding:23.26.0-ee

  podman network disconnect podman shard4
  podman network connect shard_rac_pub1_nw --ip 172.20.1.199 shard4
  podman start shard4
  ```

Monitor the Oracle Restart database setup:

```bash
  podman exec shard4 /bin/bash -c "tail -f /var/tmp/oracle_db_setup.log"
```

Database creation can take approximately 20 minutes. Wait for the following message:

```text
          ===============================
          ORACLE DATABASE IS READY TO USE
          ===============================
```

Then monitor the `shard4` setup:

```bash
podman exec shard4 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
          ==============================================
                  GSM Shard Setup Completed
          ==============================================
```

### Add the Shard to the Existing GDD Topology

Run the following command to add `shard4` to the GDD topology:

```bash
podman exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py --addshard="shard_host=dbmc5;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
```

Run the following command to check the status of the newly added shard:

```bash
podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard
```

### Deploy the Shard

Deploy the newly added shard (`shard4`):

```bash
podman exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py --deployshard=true
```

Verify the newly added shard, replication unit (RU) status, and task status:

```bash
podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl status ru

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config task
```

**Note:** Chunk redistribution after deploying the new shard may take some time to complete.

## Scale-in an existing Oracle Globally Distributed Database

To scale in an existing Oracle Globally Distributed Database deployment by removing a shard, complete the following steps in order:

- Verify the shard.
- Move RUs from the shard.
- Delete the shard.
- Verify shard removal.
- Remove the shard container.

### Verify the Shard

Verify that the shard to be removed is registered and check its current RU status:

```bash
podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl status ru
```

### Move RUs from the Shard

To move the RUs from the shard being removed, complete the following steps from the `gsm1` container:

- Switch over all leader RU members from the shard being removed to other shards. For example, to switch the leader role for RU 4 to another shard, run:

  ```bash
  GDSCTL> switchover ru -ru 4 -shard target_shard [-timeout=n]
  ```

- Move all follower RU members from the shard being removed to other shards that do not already contain a member of the corresponding RU. For example, if the shard being removed contains a follower for RU 1, move that follower to an eligible target shard:

  ```bash
  GDSCTL> move ru -ru 1 -source shard_to_be_dropped -target target_shard_where_ru_follower_does_not_exist
  ```

### Delete the Shard

After confirming that no chunks remain on `shard4`, run the following command to remove it from the GDD topology:

```bash
podman exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py  --deleteshard="shard_host=dbmc5;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
```

**Note:** In this example, `dbmc5`, `ORCL4CDB`, and `ORCL4PDB` are the host, CDB, and PDB names for `shard4`, respectively.

### Verify Shard Removal

After removing the shard from the GDD topology, verify the remaining shards, chunk distribution, and RU status:

```bash
podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl status ru
```

### Remove the Shard Container

After removing the shard from the GDD topology, remove its Podman container and data directory:

- Stop and remove the `shard4` container:

```bash
podman stop shard4
podman rm shard4
```

- If you used the Extended Oracle RAC Database `SLIM` image, remove the corresponding software directory:

```bash
rm -rf /scratch/rac/shard4
```

## Environment Variables

**For catalog and shard containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `DB_NAME` | CDB name. | Mandatory |
| `ORACLE_PDB_NAME` | PDB name. | Mandatory |
| `OP_TYPE` | Operation type for the Oracle Restart catalog or shard container. | Mandatory |
| `CRS_GPC` | Set to `true` to enable Oracle Restart configuration for the Oracle Globally Distributed Database deployment. | Mandatory |
| `DB_PWD_FILE` | Podman secret containing the encrypted database password file. | Mandatory |
| `PWD_KEY` | Podman secret containing the key used to decrypt the password file. | Mandatory |
| `PKEYOPT` | RSA options used to decrypt the encrypted password file. | Mandatory |
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
| `CATALOG_PARAMS` | Semicolon-separated catalog configuration parameters, including `catalog_host`, `catalog_db`, `catalog_pdb`, `catalog_port`, `catalog_name`, `catalog_region`, `sharding_type`, `catalog_chunks`, `repl_type`, and `repl_unit`. | Mandatory |
| `SHARD[1-9]_GROUP_PARAMS` | Semicolon-separated shard group parameters, including `group_name`, `deploy_as`, `group_region`, and `repfactor`, as applicable. | Mandatory |
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
