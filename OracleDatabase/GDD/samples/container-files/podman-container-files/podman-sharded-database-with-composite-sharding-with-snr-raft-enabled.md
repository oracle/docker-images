# Deploy Oracle GDD with Composite Sharding and Raft Replication

This guide provides detailed instructions for manually deploying a sample Oracle Globally Distributed Database with Composite Sharding and Raft Replication using Podman containers. The deployment uses Extended Oracle Single Instance Database images with Oracle Database Enterprise Edition.

- [Deploy Oracle GDD with Composite Sharding and Raft Replication](#deploy-oracle-gdd-with-composite-sharding-and-raft-replication)
  - [Deployment Overview](#deployment-overview)
  - [Prerequisites](#prerequisites)
    - [Optional: Use a Seed Database](#optional-use-a-seed-database)
  - [Deploying Catalog Container](#deploying-catalog-container)
    - [Create Directory](#create-directory)
    - [Create Container](#create-container)
  - [Deploying Shard Containers](#deploying-shard-containers)
    - [Create Directories](#create-directories)
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
    - [Prepare the Host for the New Shard](#prepare-the-host-for-the-new-shard)
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

**Note:** Raft Replication requires at least three shards. The Oracle Database and GSM versions must also support Raft Replication.

**Note:** This sample uses Oracle AI Database 26ai and GSM Podman images.

## Prerequisites

Before using this guide to create a sample Oracle Globally Distributed Database, complete the prerequisite steps in [Oracle Globally Distributed database containers on Podman](./README.md#prerequisites)

For Oracle AI Database 26ai, you can pull the required database and GSM images from Oracle Container Registry:

```bash
podman pull container-registry.oracle.com/database/enterprise_ru:latest
podman pull container-registry.oracle.com/database/gsm_ru:latest
```

To use a specific image version, replace the `latest` tag with the required version tag. For more information, see [Getting Container Images](../../../README.md#getting-container-images).

The examples in this guide use the following images:

```text
oracle/database-ext-sharding:23.26.0-ee
oracle/database-gsm:23.26.0
```

### Optional: Use a Seed Database

To expedite database creation, you can initialize the catalog and shard databases from existing cold database backups.

When using a seed database, append the following setup script to the `podman run` command:

`/opt/oracle/scripts/setup/runOraShardSetup.sh`

The corresponding data directory must contain the uncompressed cold database backup.

For example:

| Container | Data Directory |
| --- | --- |
| Catalog | `/scratch/oradata/dbfiles/CATALOG` |
| Shard 1 | `/scratch/oradata/dbfiles/ORCL1CDB` |
| Shard 2 | `/scratch/oradata/dbfiles/ORCL2CDB` |
| Shard 3 | `/scratch/oradata/dbfiles/ORCL3CDB` |
| Shard 4 | `/scratch/oradata/dbfiles/ORCL4CDB` |

Deploy the catalog and shard containers before creating the GSM containers. Complete the following steps in order:

## Deploying Catalog Container

The shard catalog is a special-purpose Oracle Database that is a persistent store for SDB configuration data and plays a key role in the automated deployment and centralized management of an Oracle Globally Distributed Database. It also hosts the gold schema of the application and the master copies of common reference data (duplicated tables).

### Create Directory

Create a directory on the Podman host to store the catalog database files. Mount this directory at `/opt/oracle/oradata` in the catalog container. The directory can reside on local storage or supported shared storage. This sample uses `/scratch/oradata/dbfiles/CATALOG`.

```bash
mkdir -p /scratch/oradata/dbfiles/CATALOG
chown -R 54321:54321 /scratch/oradata/dbfiles/CATALOG
```

**Note:**

The catalog data directory must be writable by the `oracle` user (`UID 54321`) inside the container. If the ownership is incorrect, database creation will fail. For more information, see [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance).

### Create Container

Before creating the `catalog` container, review the following notes:

**Notes:**

- Change `ORACLE_SID` and `ORACLE_PDB` as required for your environment.
- Change `/scratch/oradata/dbfiles/CATALOG` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable.
- If SELinux is enabled on the Podman host, run the following commands:

  ```bash
  semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/CATALOG
  restorecon -v /scratch/oradata/dbfiles/CATALOG
  semanage fcontext -a -t container_file_t /opt/containers/shard_host_file
  restorecon -v /opt/containers/shard_host_file
  ```

```bash
podman run -d --hostname oshard-catalog-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.102 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=CATCDB \
 -e ORACLE_PDB=CAT1PDB \
 -e OP_TYPE=catalog \
 -e COMMON_OS_PWD_FILE=pwdsecret \
 -e PWD_KEY=keysecret \
 -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
 -e SHARD_SETUP="true" \
 -e ENABLE_ARCHIVELOG=true \
 --secret pwdsecret \
 --secret keysecret \
 -v /scratch/oradata/dbfiles/CATALOG:/opt/oracle/oradata \
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name catalog oracle/database-ext-sharding:23.26.0-ee
```

Monitor the Oracle database setup:

```bash
podman logs -f catalog
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
    #########################
    DATABASE IS READY TO USE!
    #########################
```

Then monitor the `catalog` setup:

```bash
podman exec catalog /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following message:

```text
==============================================
      GSM Catalog Setup Completed
==============================================
```

## Deploying Shard Containers

A database shard is a horizontal partition of data in an Oracle Globally Distributed Database. Create a directory on the Podman host to store the database files for each shard and mount the directory at `/opt/oracle/oradata` in the corresponding shard container. The directory can reside on local storage or supported shared storage.

This sample uses `/scratch/oradata/dbfiles/ORCL1CDB` for `shard1`, `/scratch/oradata/dbfiles/ORCL2CDB` for `shard2`, and `/scratch/oradata/dbfiles/ORCL3CDB` for `shard3`.

### Create Directories

```bash
mkdir -p /scratch/oradata/dbfiles/ORCL1CDB
mkdir -p /scratch/oradata/dbfiles/ORCL2CDB
mkdir -p /scratch/oradata/dbfiles/ORCL3CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL1CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL2CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL3CDB
```

If SELinux is enabled on the Podman host, run the following commands:

```bash
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/ORCL1CDB
restorecon -v /scratch/oradata/dbfiles/ORCL1CDB
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/ORCL2CDB
restorecon -v /scratch/oradata/dbfiles/ORCL2CDB
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/ORCL3CDB
restorecon -v /scratch/oradata/dbfiles/ORCL3CDB
```

**Note:**

The shard data directories must be writable by the `oracle` user (`UID 54321`) inside the containers. Incorrect ownership will cause database creation to fail. For more information, see [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance).

### Shard1 Container

Before creating the `shard1` container, review the following notes:

**Notes:**

- Change `ORACLE_SID` and `ORACLE_PDB` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL1CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable.

```bash
podman run -d --hostname oshard1-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.103 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=ORCL1CDB \
 -e ORACLE_PDB=ORCL1PDB \
 -e OP_TYPE=primaryshard \
 -e COMMON_OS_PWD_FILE=pwdsecret \
 -e PWD_KEY=keysecret \
 -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
 -e SHARD_SETUP="true" \
 -e ENABLE_ARCHIVELOG=true \
 --secret pwdsecret \
 --secret keysecret \
 -v /scratch/oradata/dbfiles/ORCL1CDB:/opt/oracle/oradata \
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name shard1 oracle/database-ext-sharding:23.26.0-ee
```

Monitor the Oracle database setup:

```bash
podman logs -f shard1
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
    #########################
    DATABASE IS READY TO USE!
    #########################
```

Then monitor the `shard1` setup:

```bash
podman exec shard1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following message:

```text
==============================================
     GSM Shard Setup Completed                
==============================================
```

### Shard2 Container

Before creating the `shard2` container, review the following notes:

**Notes:**

- Change `ORACLE_SID` and `ORACLE_PDB` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL2CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable.

```bash
podman run -d --hostname oshard2-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.104 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=ORCL2CDB \
 -e ORACLE_PDB=ORCL2PDB \
 -e OP_TYPE=primaryshard \
 -e COMMON_OS_PWD_FILE=pwdsecret \
 -e PWD_KEY=keysecret \
 -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
 -e SHARD_SETUP="true" \
 -e ENABLE_ARCHIVELOG=true \
 --secret pwdsecret \
 --secret keysecret \
 -v /scratch/oradata/dbfiles/ORCL2CDB:/opt/oracle/oradata \
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name shard2 oracle/database-ext-sharding:23.26.0-ee
```

Monitor the Oracle database setup:

```bash
podman logs -f shard2
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
    #########################
    DATABASE IS READY TO USE!
    #########################
```

Then monitor the `shard2` setup:

```bash
podman exec shard2 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following message:

```text
==============================================
     GSM Shard Setup Completed                
==============================================
```

### Shard3 Container

Before creating the `shard3` container, review the following notes:

**Notes:**

- Change `ORACLE_SID` and `ORACLE_PDB` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL3CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable.

```bash
podman run -d --hostname oshard3-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.105 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=ORCL3CDB \
 -e ORACLE_PDB=ORCL3PDB \
 -e OP_TYPE=primaryshard \
 -e COMMON_OS_PWD_FILE=pwdsecret \
 -e PWD_KEY=keysecret \
 -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
 -e SHARD_SETUP="true" \
 -e ENABLE_ARCHIVELOG=true \
 --secret pwdsecret \
 --secret keysecret \
 -v /scratch/oradata/dbfiles/ORCL3CDB:/opt/oracle/oradata \
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name shard3 oracle/database-ext-sharding:23.26.0-ee
```

**Note:** You can add more shards based on your requirements.

Monitor the Oracle database setup:

```bash
podman logs -f shard3
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
    #########################
    DATABASE IS READY TO USE!
    #########################
```

Then monitor the `shard3` setup:

```bash
podman exec shard3 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following message:

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
podman run -d --hostname oshard-gsm1 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.100 \
 -e DOMAIN=example.com \
 -e SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522" \
 -e SHARD1_SPACE_PARAMS='sspace_name=gold;chunks=120;repfactor=3;repunits=2' \
 -e SHARD1_GROUP_PARAMS='group_name=shardgroup1;group_region=region1;shardspace=gold;repfactor=3' \
 -e CATALOG_PARAMS='catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_comp_raft;catalog_region=region1,region2;sharding_type=composite;repl_type=NATIVE;shard_space=gold' \
 -e SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
 -e SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
 -e SHARD3_PARAMS="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1" \
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
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name gsm1 oracle/database-gsm:23.26.0
```

**Note:** Change environment variables such as `DOMAIN`, `CATALOG_PARAMS`, `SHARD1_SPACE_PARAMS`, `SHARD1_GROUP_PARAMS`, `COMMON_OS_PWD_FILE`, and `PWD_KEY` as required for your environment.

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
podman run -d --hostname oshard-gsm2 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.101 \
 -e DOMAIN=example.com \
 -e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
 -e CATALOG_PARAMS='catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_comp_raft;catalog_region=region1,region2;sharding_type=composite;repl_type=NATIVE;shard_space=gold' \
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
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name gsm2 oracle/database-gsm:23.26.0
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

### Prepare the Host for the New Shard

Create the data directory for the new shard (`shard4` in this example), as you did for the initial shards:

```bash
mkdir -p /scratch/oradata/dbfiles/ORCL4CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL4CDB
```

If SELinux is enabled on the Podman host, run the following commands:

```bash
semanage fcontext -a -t container_file_t /scratch/oradata/dbfiles/ORCL4CDB
restorecon -v /scratch/oradata/dbfiles/ORCL4CDB
```

**Note:**

The shard data directory must be writable by the `oracle` user (`UID 54321`) inside the container. Incorrect ownership will cause database creation to fail. For more information, see [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance).

### Create the New Shard Container

Before creating the new shard container (`shard4` in this example), review the following notes:

**Notes:**

- Change `ORACLE_SID` and `ORACLE_PDB` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL4CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable.

```bash
podman run -d --hostname oshard4-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.106 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=ORCL4CDB \
 -e ORACLE_PDB=ORCL4PDB \
 -e OP_TYPE=primaryshard \
 -e COMMON_OS_PWD_FILE=pwdsecret \
 -e PWD_KEY=keysecret \
 -e PKEYOPT="rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256" \
 -e SHARD_SETUP="true" \
 -e ENABLE_ARCHIVELOG=true \
 --secret pwdsecret \
 --secret keysecret \
 -v /scratch/oradata/dbfiles/ORCL4CDB:/opt/oracle/oradata \
 -v /opt/containers/shard_host_file:/etc/hosts \
 --privileged=false \
 --name shard4 oracle/database-ext-sharding:23.26.0-ee
```

Monitor the Oracle database setup:

```bash
podman logs -f shard4
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
    #########################
    DATABASE IS READY TO USE!
    #########################
```

Then monitor the `shard4` setup:

```bash
podman exec shard4 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following message:

```text
==============================================
     GSM Shard Setup Completed                
==============================================
```

### Add the Shard to the Existing GDD Topology

Run the following command to add `shard4` to the GDD topology:

```bash
podman exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py --addshard="shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
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

Verify that the shard to be removed is registered, and check its current RU and task status:

```bash
podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl status ru

podman exec -it gsm1 $(podman exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config task
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
podman exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py  --deleteshard="shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1"
```

**Note:** In this example, `oshard4-0`, `ORCL4CDB`, and `ORCL4PDB` are the host, CDB, and PDB names for `shard4`, respectively.

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

- Remove the corresponding data directory:

```bash
rm -rf /scratch/oradata/dbfiles/ORCL4CDB
```

## Environment Variables

**For catalog and shard containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `COMMON_OS_PWD_FILE` | Podman secret containing the encrypted password file. | Mandatory |
| `PWD_KEY` | Podman secret containing the key used to decrypt the password file. | Mandatory |
| `PKEYOPT` | RSA encryption options used to decrypt the password file. | Mandatory |
| `OP_TYPE` | Operation type for the catalog or shard container. Set to `catalog`, `primaryshard`, or `standbyshard`. | Mandatory |
| `SHARD_SETUP` | Set to `true` to initiate the sharding scripts. | Mandatory |
| `DOMAIN` | Domain name for the container. | Mandatory |
| `ORACLE_SID` | CDB name. | Mandatory |
| `ORACLE_PDB` | PDB name. | Mandatory |
| `CUSTOM_SHARD_SCRIPT_DIR` | Directory containing custom scripts to run after shard setup. | Optional |
| `CUSTOM_SHARD_SCRIPT_FILE` | Custom script file available in `CUSTOM_SHARD_SCRIPT_DIR` to run after shard setup. | Optional |
| `CLONE_DB` | Set to `true` to create the database from an existing cold backup instead of using DBCA. | Optional |
| `OLD_ORACLE_SID` | Original CDB name when cloning from an existing cold database backup. | Optional |
| `OLD_ORACLE_PDB` | Original PDB name when cloning from an existing cold database backup. | Optional |

**For GSM Containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `CATALOG_SETUP` | When set to `True`, creates the GSM director and adds the catalog without adding shards. Used when configuring the standby GSM. | Optional |
| `CATALOG_PARAMS` | Semicolon-separated catalog configuration parameters, including `catalog_host`, `catalog_db`, `catalog_pdb`, `catalog_port`, `catalog_name`, `catalog_region`, `sharding_type`, `repl_type`, `shard_space`, and `force`. | Mandatory |
| `SHARD_DIRECTOR_PARAMS` | Semicolon-separated shard director parameters: `director_name`, `director_region`, and `director_port`. | Mandatory |
| `SHARD[1-9]_SPACE_PARAMS` | Semicolon-separated shardspace parameters, including `sspace_name`, `chunks`, `repfactor`, and `repunits`. | Mandatory |
| `SHARD[1-9]_GROUP_PARAMS` | Semicolon-separated shard group parameters, including `group_name`, `deploy_as`, `group_region`, `shardspace`, and `repfactor`, as applicable. | Mandatory |
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