# Deploy Oracle GDD with System-Managed Sharding and Raft Replication using Oracle AI Database Free Images

This guide provides detailed instructions for manually deploying a sample Oracle Globally Distributed Database with System-Managed Sharding and Raft Replication using Podman containers. The deployment uses Oracle AI Database 26ai Free images.

- [Deploy Oracle GDD with System-Managed Sharding and Raft Replication using Oracle AI Database Free Images](#deploy-oracle-gdd-with-system-managed-sharding-and-raft-replication-using-oracle-ai-database-free-images)
  - [Before You Begin](#before-you-begin)
  - [Deployment Overview](#deployment-overview)
  - [Prerequisites](#prerequisites)
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
  - [Scenario Limitations](#scenario-limitations)
  - [Environment Variables](#environment-variables)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Before You Begin

- [Oracle Database Free Image Constraints](./README.md#oracle-database-free-image-constraints)

## Deployment Overview

This setup initially involves deploying Podman containers for:

- one catalog database container
- three shard database containers
- one primary GSM container
- one standby GSM container

**Note:** This sample uses Oracle AI Database 26ai Free and GSM Podman images.
**Note:** Oracle AI Database Free supports a maximum of three shards in this scenario.

## Prerequisites

Before using this guide to create a sample Oracle Globally Distributed Database, complete the prerequisite steps in [Oracle Globally Distributed database containers on Podman](./README.md#prerequisites).

For Oracle AI Database 26ai Free, you can pull the required database and GSM images from Oracle Container Registry:

```bash
podman pull container-registry.oracle.com/database/free:latest
podman pull container-registry.oracle.com/database/gsm_ru:latest
```

To use a specific image version, replace the `latest` tag with the required version tag. For more information, see [Getting Container Images](../../../README.md#getting-container-images).

The examples in this guide use the following images:

```text
container-registry.oracle.com/database/free:latest
container-registry.oracle.com/database/gsm_ru:latest
```

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

- For the Oracle AI Database Free image, set `ORACLE_SID` to `FREE` and `ORACLE_PDB` to `FREEPDB1`.
- Change `ORACLE_FREE_PDB` and `DB_UNIQUE_NAME` as required for your environment.
- Change `/scratch/oradata/dbfiles/CATALOG` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable (in this example, `FREE`).
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
 -e ORACLE_SID=FREE \
 -e ORACLE_PDB=FREEPDB1 \
 -e ORACLE_FREE_PDB=CAT1PDB \
 -e DB_UNIQUE_NAME=CATCDB \
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
 --name catalog container-registry.oracle.com/database/free:latest
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

- For the Oracle AI Database Free image, set `ORACLE_SID` to `FREE` and `ORACLE_PDB` to `FREEPDB1`.
- Change `ORACLE_FREE_PDB` and `DB_UNIQUE_NAME` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL1CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable (in this example, `FREE`).

```bash
podman run -d --hostname oshard1-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.103 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=FREE \
 -e ORACLE_PDB=FREEPDB1 \
 -e ORACLE_FREE_PDB=ORCL1PDB \
 -e DB_UNIQUE_NAME=ORCL1CDB \
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
 --name shard1 container-registry.oracle.com/database/free:latest
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

- For the Oracle AI Database Free image, set `ORACLE_SID` to `FREE` and `ORACLE_PDB` to `FREEPDB1`.
- Change `ORACLE_FREE_PDB` and `DB_UNIQUE_NAME` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL2CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable (in this example, `FREE`).

```bash
podman run -d --hostname oshard2-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.104 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=FREE \
 -e ORACLE_PDB=FREEPDB1 \
 -e ORACLE_FREE_PDB=ORCL2PDB \
 -e DB_UNIQUE_NAME=ORCL2CDB \
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
 --name shard2 container-registry.oracle.com/database/free:latest
```

**Note:** You can add more shards based on your requirements.

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

- For the Oracle AI Database Free image, set `ORACLE_SID` to `FREE` and `ORACLE_PDB` to `FREEPDB1`.
- Change `ORACLE_FREE_PDB` and `DB_UNIQUE_NAME` as required for your environment.
- Change `/scratch/oradata/dbfiles/ORCL3CDB` as required for your environment.
- By default, the Oracle Globally Distributed Database setup creates a new database under `/opt/oracle/oradata` based on the `ORACLE_SID` environment variable (in this example, `FREE`).

```bash
podman run -d --hostname oshard3-0 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.105 \
 -e DOMAIN=example.com \
 -e ORACLE_SID=FREE \
 -e ORACLE_PDB=FREEPDB1 \
 -e ORACLE_FREE_PDB=ORCL3PDB \
 -e DB_UNIQUE_NAME=ORCL3CDB \
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
 --name shard3 container-registry.oracle.com/database/free:latest
```

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
 -e SHARD1_GROUP_PARAMS="group_name=shardgroup1;group_region=region1;repfactor=3" \
 -e CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_raft;catalog_region=region1,region2;sharding_type=system;catalog_chunks=30;repl_type=Native;repl_unit=2" \
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
 --name gsm1 container-registry.oracle.com/database/gsm_ru:latest
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
podman run -d --hostname oshard-gsm2 \
 --dns-search=example.com \
 --network=shard_pub1_nw \
 --ip=10.0.20.101 \
 -e DOMAIN=example.com \
 -e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
 -e CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_raft;catalog_region=region1,region2;sharding_type=system;catalog_chunks=30;repl_type=Native;repl_unit=2" \
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
 --name gsm2 container-registry.oracle.com/database/gsm_ru:latest
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

## Scenario Limitations

This sample Raft deployment has the following limitations:

- Oracle AI Database 26ai Free supports a maximum of three shards in this scenario.
- Raft replication requires at least three shards.
- As a result, scale-out is not supported in this Free-image sample topology.
- Scale-in is also not supported because removing a shard would break the minimum shard count required for Raft Replication.

For licensing details, see the Oracle documentation: [Licensing Information](https://docs.oracle.com/en/database/oracle/oracle-database/26/dblic/Licensing-Information.html).

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
| `ORACLE_SID` | Oracle SID for the Free image. Set to `FREE`. | Mandatory |
| `ORACLE_PDB` | Default PDB for the Free image. Set to `FREEPDB1`. | Mandatory |
| `ORACLE_FREE_PDB` | PDB name to use for the Oracle Globally Distributed Database deployment. | Mandatory |
| `DB_UNIQUE_NAME` | Unique database name for the catalog or shard database. | Mandatory |
| `CUSTOM_SHARD_SCRIPT_DIR` | Directory containing custom scripts to run after shard setup. | Optional |
| `CUSTOM_SHARD_SCRIPT_FILE` | Custom script file available in `CUSTOM_SHARD_SCRIPT_DIR` to run after shard setup. | Optional |
| `CLONE_DB` | Set to `true` to create the database from an existing cold backup instead of using DBCA. | Optional |
| `OLD_ORACLE_SID` | Original CDB name when cloning from an existing cold database backup. | Optional |
| `OLD_ORACLE_PDB` | Original PDB name when cloning from an existing cold database backup. | Optional |

**For GSM containers:**

| Parameter | Description | Mandatory/Optional |
| --- | --- | --- |
| `CATALOG_SETUP` | When set to `True`, creates the GSM director and adds the catalog without adding shards. Used when configuring the standby GSM. | Optional |
| `CATALOG_PARAMS` | Semicolon-separated catalog configuration parameters, including `catalog_host`, `catalog_db`, `catalog_pdb`, `catalog_port`, `catalog_name`, `catalog_region`, `sharding_type`, `catalog_chunks`, `repl_type`, and `repl_unit`. | Mandatory |
| `SHARD_DIRECTOR_PARAMS` | Semicolon-separated shard director parameters: `director_name`, `director_region`, and `director_port`. | Mandatory |
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