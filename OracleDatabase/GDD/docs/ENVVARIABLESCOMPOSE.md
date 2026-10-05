# Oracle Globally Distributed Database Podman Compose Environment Variables

## Introduction

This document describes the environment variables used by the Oracle Globally Distributed Database Podman Compose deployment.

The default deployment values are configured by the host preparation script and consumed by the Podman Compose deployment. Review these variables before deployment if you need to customize storage, networking, container images, database names, container names, or the Oracle Globally Distributed Database topology.

## Host and Container Settings

| Environment Variable           | Description                                                                                               | Default Value      |
|--------------------------------|-----------------------------------------------------------------------------------------------------------|--------------------|
| `PODMANVOLLOC`                 | Host directory used to store persistent data for all Podman containers.                                   | `/scratch/oradata` |
| `NETWORK_INTERFACE`            | Network interface used for the Podman network. Change this value if your host uses a different interface. | `ens3`             |
| `NETWORK_SUBNET`               | Subnet used when creating the Podman network.                                                             | `10.0.20.0/20`     |
| `LOCAL_NETWORK`                | Network prefix used to generate container IP addresses.                                                   | `10.0.20`          |
| `CONTAINER_RESTART_POLICY`     | Restart policy applied to all Podman containers.                                                          | `always`           |
| `CONTAINER_PRIVILEGED_FLAG`    | Enables or disables privileged mode for the containers (`true` or `false`).                               | `false`            |
| `DOMAIN`                       | Domain name used by the containers.                                                                       | `example.com`      |
| `DNS_SEARCH`                   | DNS search domain                                                                                         | `example.com`      |

## Container Images

| Environment Variable | Description                                                        | Default Value                                                 |
|----------------------|--------------------------------------------------------------------|---------------------------------------------------------------|
| `SIDB_IMAGE`         | Oracle Database Podman image used for catalog and shard containers. | `container-registry.oracle.com/database/enterprise_ru:latest` |
| `GSM_IMAGE`          | Oracle GSM Podman image used for the GSM containers.               | `container-registry.oracle.com/database/gsm_ru:latest`        |

## Health Checks

| Environment Variable   | Description                                                                                          | Default Value |
|------------------------|------------------------------------------------------------------------------------------------------|---------------|
| `HEALTHCHECK_INTERVAL` | Interval between health checks.                                                                      | `30s`         |
| `HEALTHCHECK_TIMEOUT`  | Maximum time allowed for each health check to complete.                                              | `3s`          |
| `HEALTHCHECK_RETRIES`  | Number of consecutive failed health checks allowed before the container is marked unhealthy.         | `40`          |

## Secrets

| Environment Variable | Description                                                      | Default Value               |
|----------------------|------------------------------------------------------------------|-----------------------------|
| `PWD_SECRET_FILE`    | Path to the encrypted database password file.                    | `/opt/.secrets/pwdfile.enc` |
| `KEY_SECRET_FILE`    | Path to the key file used to decrypt the encrypted password file | `/opt/.secrets/key.pem`     |

## Catalog Configuration

| Environment Variable | Description                                                                       | Default Value      |
|----------------------|-----------------------------------------------------------------------------------|--------------------|
| `CAT_CDB`            | Catalog CDB name                                                                  | `CATCDB`           |
| `CAT_PDB`            | Catalog PDB name                                                                  | `CAT1PDB`          |
| `CAT_HOSTNAME`       | Catalog hostname                                                                  | `oshard-catalog-0` |
| `CAT_CONTAINER_NAME` | Catalog container name                                                            | `catalog`          |
| `CATALOG_OP_TYPE`    | Operation type passed to the catalog container initialization scripts.            | `catalog`          |
| `CAT_SHARD_SETUP`    | Enables or disables Oracle GDD catalog setup (`true` or `false`).                 | `true`             |
| `CATALOG_ARCHIVELOG` | Enables or disables ARCHIVELOG mode for the catalog database (`true` or `false`). | `true`             |

## Shard Configuration

| Environment Variable     | Description                                                                   | Default Value  |
|--------------------------|-------------------------------------------------------------------------------|----------------|
| `ALLSHARD_OP_TYPE`       | Operation type passed to the shard container initialization scripts.          | `primaryshard` |
| `SHARD_ARCHIVELOG`       | Enables or disables shard `ARCHIVELOG` mode, accepts `true` or `false`        | `true`         |
| `SHARD1_SHARD_SETUP`     | Enables or disables Oracle GDD setup for shard 1 (`true` or `false`).         | `true`         |
| `SHARD2_SHARD_SETUP`     | Enables or disables Oracle GDD setup for shard 2 (`true` or `false`).         | `true`         |
| `SHARD3_SHARD_SETUP`     | Enables or disables Oracle GDD setup for shard 3 (`true` or `false`).         | `true`         |
| `SHARD4_SHARD_SETUP`     | Enables or disables Oracle GDD setup for shard 4 (`true` or `false`).         | `true`         |
| `SHARD1_CONTAINER_NAME`  | Shard 1 container name                                                        | `shard1`       |
| `SHARD2_CONTAINER_NAME`  | Shard 2 container name                                                        | `shard2`       |
| `SHARD3_CONTAINER_NAME`  | Shard 3 container name                                                        | `shard3`       |
| `SHARD4_CONTAINER_NAME`  | Shard 4 container name                                                        | `shard4`       |
| `SHARD1_HOSTNAME`        | Shard 1 hostname                                                              | `oshard1-0`    |
| `SHARD2_HOSTNAME`        | Shard 2 hostname                                                              | `oshard2-0`    |
| `SHARD3_HOSTNAME`        | Shard 3 hostname                                                              | `oshard3-0`    |
| `SHARD4_HOSTNAME`        | Shard 4 hostname                                                              | `oshard4-0`    |
| `SHARD1_CDB`             | Shard 1 CDB name                                                              | `ORCL1CDB`     |
| `SHARD2_CDB`             | Shard 2 CDB name                                                              | `ORCL2CDB`     |
| `SHARD3_CDB`             | Shard 3 CDB name                                                              | `ORCL3CDB`     |
| `SHARD4_CDB`             | Shard 4 CDB name                                                              | `ORCL4CDB`     |
| `SHARD1_PDB`             | Shard 1 PDB name                                                              | `ORCL1PDB`     |
| `SHARD2_PDB`             | Shard 2 PDB name                                                              | `ORCL2PDB`     |
| `SHARD3_PDB`             | Shard 3 PDB name                                                              | `ORCL3PDB`     |
| `SHARD4_PDB`             | Shard 4 PDB name                                                              | `ORCL4PDB`     |

## GSM Configuration

| Environment Variable | Description                                                        | Default Value |
|----------------------|--------------------------------------------------------------------|---------------|
| `GSM_OP_TYPE`        | Operation type passed to the GSM container initialization scripts. | `gsm`         |

## Primary GSM Configuration

The following variables define the catalog, shard directors, shard groups, shards, and services configured by the primary GSM container.

| Environment Variable            | Description                                                               | Default Value |
|---------------------------------|---------------------------------------------------------------------------|---------------|
| `PRIMARY_GSM_SHARD_SETUP`       | Enables or disables Oracle GDD setup for the primary GSM (`true` or `false`). | `true` |
| `PRIMARY_GSM_CONTAINER_NAME`    | Primary GSM container name                                                | `gsm1` |
| `PRIMARY_GSM_HOSTNAME`          | Primary GSM hostname                                                      | `oshard-gsm1` |
| `PRIMARY_SHARD_DIRECTOR_PARAMS` | Shard director configuration passed to the primary GSM container.         | `director_name=sharddirector1;director_region=region1;director_port=1522` |
| `PRIMARY_SHARD1_GROUP_PARAMS`   | Shard group configuration passed to the primary GSM container.            | `group_name=shardgroup1;deploy_as=primary;group_region=region1` |
| `PRIMARY_CATALOG_PARAMS`        | Catalog configuration passed to the primary GSM container.                | `catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_pri;catalog_region=region1,region2;sharding_type=SYSTEM;repl_type=DG` |
| `PRIMARY_SHARD1_PARAMS`         | Shard 1 configuration passed to the primary GSM container.                | `shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1` |
| `PRIMARY_SHARD2_PARAMS`         | Shard 2 configuration passed to the primary GSM container.                | `shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1` |
| `PRIMARY_SHARD3_PARAMS`         | Shard 3 configuration passed to the primary GSM container.                | `shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1` |
| `PRIMARY_SHARD4_PARAMS`         | Shard 4 configuration passed to the primary GSM container.                | `shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1;shard_region=region1` |
| `PRIMARY_SERVICE1_PARAMS`       | Configuration parameters for primary service 1.                           | `service_name=oltp_rw_svc;service_role=primary;service_mode=readwrite` |
| `PRIMARY_SERVICE2_PARAMS`       | Configuration parameters for primary service 2.                           | `service_name=oltp_ro_svc;service_role=primary;service_mode=readonly` |

## Standby GSM Configuration

The following variables define the catalog, shard directors, shard groups, shards, and services configured by the standby GSM container.

| Environment Variable            | Description                                                               | Default Value |
|---------------------------------|---------------------------------------------------------------------------|---------------|
| `STANDBY_GSM_SHARD_SETUP`       | Enables or disables Oracle GDD setup for the standby GSM (`true` or `false`). | `true` |
| `STANDBY_GSM_CONTAINER_NAME`    | Standby GSM container name                                                | `gsm2` |
| `STANDBY_GSM_HOSTNAME`          | Standby GSM hostname                                                      | `oshard-gsm2` |
| `STANDBY_SHARD_DIRECTOR_PARAMS` | Shard director configuration passed to the standby GSM container.         | `director_name=sharddirector2;director_region=region2;director_port=1522` |
| `STANDBY_CATALOG_PARAMS`        | Standby catalog configuration passed to the standby GSM container.        | `catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=sdb_sys_pri;catalog_region=region1,region2;sharding_type=SYSTEM;repl_type=DG` |
| `STANDBY_SERVICE1_PARAMS`       | Parameters for standby service 1                                          | `service_name=oltp_rw_svc;service_role=standby;service_mode=readwrite` |
| `STANDBY_SERVICE2_PARAMS`       | Parameters for standby service 2                                          | `service_name=oltp_ro_svc;service_role=standby;service_mode=readonly` |