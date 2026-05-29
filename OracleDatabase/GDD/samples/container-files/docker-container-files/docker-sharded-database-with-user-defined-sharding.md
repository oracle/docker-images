# Deploy Oracle Globally Distributed Database with User-Defined Sharding using Docker Containers

This page covers the steps to manually deploy a sample Oracle Globally Distributed Database with User-Defined Sharding using Docker Containers.

- [Setup Details](#setup-details)
- [Prerequisites](#prerequisites)
- [Deploying Catalog Container](#deploying-catalog-container)
  - [Create Directory](#create-directory)
  - [Create Container](#create-container)
- [Deploying Shard Containers](#deploying-shard-containers)
  - [Create Directories](#create-directories)
  - [Shard1 Container](#shard1-container)
  - [Shard2 Container](#shard2-container)
- [Deploying GSM Container](#deploying-gsm-container)
  - [Create Directory for Master GSM Container](#create-directory-for-master-gsm-container)
  - [Create Master GSM Container](#create-master-gsm-container)
- [Deploying Standby GSM Container](#deploying-standby-gsm-container)  
  - [Create Directory for Standby GSM Container](#create-directory-for-standby-gsm-container)
  - [Create Standby GSM Container](#create-standby-gsm-container)
- [Scale-out an existing Oracle Globally Distributed Database](#scale-out-an-existing-oracle-globally-distributed-database)
  - [Complete the prerequisite steps before creating Docker Container for new shard](#complete-the-prerequisite-steps-before-creating-docker-container-for-new-shard)
  - [Create Docker Container for new shard](#create-docker-container-for-new-shard)
  - [Add the new shard Database to the existing Oracle Globally Distributed Database](#add-the-new-shard-database-to-the-existing-oracle-globally-distributed-database)
  - [Deploy the new shard](#deploy-the-new-shard)
  - [Move chunks](#move-chunks)  
- [Scale-in an existing Oracle Globally Distributed Database](#scale-in-an-existing-oracle-globally-distributed-database)
  - [Confirm the shard to be deleted is present in the list of shards in the Oracle Globally Distributed Database](#confirm-the-shard-to-be-deleted-is-present-in-the-list-of-shards-in-the-oracle-globally-distributed-database)
  - [Move the chunks out of the shard database which you want to delete](#move-the-chunks-out-of-the-shard-database-which-you-want-to-delete)
  - [Delete the shard database from the Oracle Globally Distributed Database](#delete-the-shard-database-from-the-oracle-globally-distributed-database)
  - [Confirm the shard has been successfully deleted from the Oracle Globally Distributed Database](#confirm-the-shard-has-been-successfully-deleted-from-the-oracle-globally-distributed-database)
  - [Remove the Docker Container](#remove-the-docker-container)
- [Environment Varibles  Explained](#environment-variables-explained)
- [Support](#support)
- [License](#license)
- [Copyright](#copyright)

## Setup Details

This setup involves deploying docker containers for:

- Catalog Database
- Two Shard Databases
- Primary GSM
- Standby GSM

**NOTE:** You can use Oracle 19c or Oracle 21c RDBMS and GSM Docker Images for this sample deployment.

**NOTE:** In the current Sample Oracle Globally Distributed Database Deployment, we have used Oralce 21c RDBMS and GSM Docker Images.

## Prerequisites

Before using this page to create a sample Oracle Globally Distributed Database, please complete the prerequisite steps mentioned in [Oracle Globally Distributed Database Containers on Docker](./README.md#prerequisites)

Before creating the GSM container, you need to build the catalog and shard containers. Execute the following steps to create containers:

## Deploying Catalog Container

The shard catalog is a special-purpose Oracle Database that is a persistent store for SDB configuration data and plays a key role in the automated deployment and centralized management of an Oracle Globally Distributed Database. It also hosts the gold schema of the application and the master copies of common reference data (duplicated tables)

### Create Directory

You need to create mountpoint on the docker host to save datafiles for Oracle Sharding Catalog DB and expose as a volume to catalog container. This volume can be local on a docker host or exposed from your central storage. It contains a file system such as EXT4. During the setup of this sample Oracle Globally Distributed Database, we used `/scratch/oradata/dbfiles/CATALOG` directory and exposed as volume to catalog container.

```bash
mkdir -p /scratch/oradata/dbfiles/CATALOG
chown -R 54321:54321 /scratch/oradata/dbfiles/CATALOG
```

**Notes:**:

- Change the ownership for data volume `/scratch/oradata/dbfiles/CATALOG` exposed to catalog container as it has to be writable by oracle "oracle" (uid: 54321) user inside the container.
- If this is not changed then database creation will fail. For details, please refer, [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance).

### Create Container

Before creating catalog container, review the following notes carefully:

**Notes:**

- Change environment variable such as ORACLE_SID, ORACLE_PDB based on your env.
- Change /scratch/oradata/dbfiles/CATALOG based on your enviornment.
- By default, Oracle Globally Distributed Database setup creates new database under `/opt/oracle/scratch/oradata` based on ORACLE_SID enviornment variable.
- If you are planing to perform seed cloning to expedite the Oracle Globally Distributed Database setup using existing cold DB backup, you need to replace `--name catalog oracle/database:21.3.0-ee` with `--name catalog oracle/database:21.3.0-ee /opt/oracle/scripts/setup/runOraShardSetup.sh`
  - In this case,   /scratch/oradata/dbfiles/CATALOG` must contain the DB backup and it must not be in zipped format. E.g. `/scratch/oradata/dbfiles/CATALOG/SEEDCDB` where SEEDCDB is the cold backup and contains datafiles and PDB.

```bash
docker run -d --hostname oshard-catalog-0 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.102 \
-e DOMAIN=example.com \
-e ORACLE_SID=CATCDB \
-e ORACLE_PDB=CAT1PDB \
-e OP_TYPE=catalog \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-v /scratch/oradata/dbfiles/CATALOG:/opt/oracle/oradata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--privileged=false \
--name catalog oracle/database-ext-sharding:21.3.0-ee
```

To check the catalog container/services creation logs, please tail docker logs. It will take 20 minutes to create the catalog container service.

```bash
docker logs -f catalog
```

**IMPORTANT:** The Database Container Image used in this case is having the Oracle Database binaries installed. On first startup of the container, a new database will be created and the following lines highlight when the Catalog database is ready to be used:

```bash
==============================================
      GSM Catalog Setup Completed
==============================================
```  

## Deploying Shard Containers

A database shard is a horizontal partition of data in a database or search engine. Each individual partition is referred to as a shard or database shard. You need to create mountpoint on docker host to save datafiles for Oracle Globally Distributed Database and expose as a volume to shard container. This volume can be local on a docker host or exposed from your central storage. It contains a file system such as EXT4.

For Example: During the setup of this README.md, we used `/scratch/oradata/dbfiles/ORCL1CDB` directory and exposed as volume to shard container `shard1`.

### Create Directories

```bash
mkdir -p /scratch/oradata/dbfiles/ORCL1CDB
mkdir -p /scratch/oradata/dbfiles/ORCL2CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL1CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL2CDB
```

**Notes:**:

- Change the ownership for data volume `/scratch/oradata/dbfiles/ORCL1CDB` and `/scratch/oradata/dbfiles/ORCL2CDB` exposed to shard container as it has to be writable by oracle "oracle" (uid: 54321) user inside the container.
- If this is not changed then database creation will fail. For details, please refer, [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance).

### Shard1 Container

Before creating shard1 container, review the following notes carefully:

**Notes:**

- Change environment variable such as ORACLE_SID, ORACLE_PDB based on your env.
- Change /scratch/oradata/dbfiles/ORCL1CDB based on your environment.
- By default, Oracle Globally Distributed Database setup creates new database under `/opt/oracle/scratch/oradata` based on ORACLE_SID environment variable.
- If you are planing to perform seed cloning to expedite the Oracle Globally Distributed Database setup using existing cold DB backup, you need to replace `--name shard1 oracle/database:21.3.0-ee` with `--name shard1 oracle/database:21.3.0-ee /opt/oracle/scripts/setup/runOraShardSetup.sh`
  - In this case, `/scratch/oradata/dbfiles/ORCL1CDB` must contain the DB backup and it must not be zipped. E.g. `/scratch/oradata/dbfiles/ORCL1CDB/SEEDCDB` where `SEEDCDB` is the cold backup and contains datafiles and PDB.

```bash
docker run -d --hostname oshard1-0 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.103 \
-e DOMAIN=example.com \
-e ORACLE_SID=ORCL1CDB \
-e ORACLE_PDB=ORCL1PDB \
-e OP_TYPE=primaryshard \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-v /scratch/oradata/dbfiles/ORCL1CDB:/opt/oracle/oradata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--privileged=false \
--name shard1 oracle/database-ext-sharding:21.3.0-ee
```

To check the shard1 container/services creation logs, please tail docker logs. It will take 20 minutes to create the shard1 container service.

```bash
docker logs -f shard1
```

### Shard2 Container

Before creating shard1 container, review the following notes carefully:

**Notes:**

- Change environment variable such as ORACLE_SID, ORACLE_PDB based on your env.
- Change /scratch/oradata/dbfiles/ORCL2CDB based on your environment.
- By default, Oracle Globally Distributed Database setup creates new database under `/opt/oracle/scratch/oradata` based on ORACLE_SID environment variable.
- If you are planing to perform seed cloning to expedite the Oracle Globally Distributed Database setup using existing cold DB backup, you need to replace `--name shard2 oracle/database:21.3.0-ee` with `--name shard2 oracle/database:21.3.0-ee /opt/oracle/scripts/setup/runOraShardSetup.sh`
  - In this case, `/scratch/oradata/dbfiles/ORCL2CDB` must contain the DB backup and it must not be zipped. E.g. `/scratch/oradata/dbfiles/ORCL2CDB/SEEDCDB` where `SEEDCDB` is the cold backup and contains datafiles and PDB.

```bash
docker run -d --hostname oshard2-0 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.104 \
-e DOMAIN=example.com \
-e ORACLE_SID=ORCL2CDB \
-e ORACLE_PDB=ORCL2PDB \
-e OP_TYPE=primaryshard \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-v /scratch/oradata/dbfiles/ORCL2CDB:/opt/oracle/oradata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--privileged=false \
--name shard2 oracle/database-ext-sharding:21.3.0-ee
```

**Note**: You can add more shards based on your requirement.

To check the shard2 container/services creation logs, please tail docker logs. It will take 20 minutes to create the shard2 container service

```bash
docker logs -f shard2
```

**IMPORTANT:** The Database Container Image used in this case is having the Oracle Database binaries installed. On first startup of the container, a new database will be created and the following lines highlight when the Shard database is ready to be used:

```bash
==============================================
      GSM Shard Setup Completed
==============================================
```

## Deploying GSM Container

The Global Data Services framework consists of at least one global service manager, a Global Data Services catalog, and the GDS configuration databases. You need to create mountpoint on docker host to save gsm setup related file for Oracle Global Service Manager and expose as a volume to GSM container. This volume can be local on a docker host or exposed from your central storage. It contains a file system such as EXT4. During the setup of this README.md, we used /scratch/oradata/dbfiles/GSMDATA directory and exposed as volume to GSM container.

### Create Directory for Master GSM Container

```bash
mkdir -p /scratch/oradata/dbfiles/GSMDATA
chown -R 54321:54321 /scratch/oradata/dbfiles/GSMDATA
```

### Create Master GSM Container

```bash
docker run -d --hostname oshard-gsm1 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.100 \
-e DOMAIN=example.com \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522" \
-e CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;sharding_type=USER;shard_space=shardspace1,shardspace2" \
-e SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_space=shardspace1;shard_region=region1"  \
-e SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_space=shardspace2;shard_region=region1"  \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary" \
-e GSM_TRACE_LEVEL="OFF" \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="True" \
-e OP_TYPE=gsm \
-e MASTER_GSM="TRUE" \
-v /scratch/oradata/dbfiles/GSMDATA:/opt/oracle/gsmdata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--privileged=false \
--name gsm1 oracle/gsm:21.3.0
```

**Note:** Change environment variables such as DOMAIN, CATALOG_PARAMS, PRIMARY_SHARD_PARAMS, COMMON_OS_PWD_FILE and PWD_KEY according to your environment.

To check the gsm1 container/services creation logs, please tail docker logs. It will take 2 minutes to create the gsm container service.

```bash
docker logs -f gsm1
```

## Deploying Standby GSM Container

You need standby GSM container to serve the connection when master GSM fails.

### Create Directory for Standby GSM Container

```bash
mkdir -p /scratch/oradata/dbfiles/GSM2DATA
chown -R 54321:54321 /scratch/oradata/dbfiles/GSM2DATA
```

### Create Standby GSM Container

```bash
docker run -d --hostname oshard-gsm2 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.101 \
-e DOMAIN=example.com \
-e SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region2;director_port=1522" \
-e CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;sharding_type=USER;shard_space=shardspace1,shardspace2" \
-e SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_space=shardspace1;"  \
-e SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_space=shardspace2;"  \
-e SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=standby" \
-e SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=standby" \
-e GSM_TRACE_LEVEL="OFF" \
-e CATALOG_SETUP="True" \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="True" \
-e OP_TYPE=gsm \
--privileged=false \
-v /scratch/oradata/dbfiles/GSM2DATA:/opt/oracle/gsmdata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--name gsm2 oracle/gsm:21.3.0
```

**Notes:** Change environment variables such as DOMAIN, CATALOG_PARAMS, COMMON_OS_PWD_FILE and PWD_KEY according to your environment.

To check the gsm2 container/services creation logs, please tail docker logs. It will take 2 minutes to create the gsm container service.

```bash
docker logs -f gsm2
```

**IMPORTANT:** The GSM Container Image used in this case is having the Oracle GSM installed. On first startup of the container, a new GSM setup will be created and the following lines highlight when the GSM setup is ready to be used:

```bash
==============================================
      GSM Setup Completed
==============================================
```

## Scale-out an existing Oracle Globally Distributed Database

If you want to Scale-Out an existing Oracle Globally Distributed Database already deployed using the Docker Containers, then you will to complete the steps in below order:

- Complete the prerequisite steps before creating the Docker Container for the new shard to be added to the Oracle Globally Distributed Database
- Create the Docker Container for the new shard
- Add the new shard Database to the existing Oracle Globally Distributed Database
- Deploy the new shard

The below example covers the steps to add a new shard (shard3) to an existing Oracle Globally Distributed Database which was deployed earlier in this page with two shards (shard1 and shard2).

### Complete the prerequisite steps before creating Docker Container for new shard

Create the required directories for the new shard (shard3 in this case) container just like they were created for the earlier Shards (shard1 and shard2):

```bash
mkdir -p /scratch/oradata/dbfiles/ORCL3CDB
chown -R 54321:54321 /scratch/oradata/dbfiles/ORCL3CDB
```

**Notes:**:

- Change the ownership for data volume `/scratch/oradata/dbfiles/ORCL3CDB` and `/scratch/oradata/dbfiles/ORCL3CDB` exposed to shard container as it has to be writable by oracle "oracle" (uid: 54321) user inside the container.
- If this is not changed then database creation will fail. For details, please refer, [oracle/docker-images for Single Instance Database](https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance).

### Create Docker Container for new shard

Before creating new shard (shard3 in this case) container, review the following notes carefully:

**Notes:**

- Change environment variable such as ORACLE_SID, ORACLE_PDB based on your env.
- Change /scratch/oradata/dbfiles/ORCL3CDB based on your environment.
- By default, Oracle Globally Distributed Database setup creates new database under `/opt/oracle/scratch/oradata` based on ORACLE_SID environment variable.
- If you are planing to perform seed cloning to expedite the Oracle Globally Distributed Database setup using existing cold DB backup, you need to replace `--name shard3 oracle/database:21.3.0-ee` with `--name shard3 oracle/database:21.3.0-ee /opt/oracle/scripts/setup/runOraShardSetup.sh`
  - In this case, `/scratch/oradata/dbfiles/ORCL3CDB` must contain the DB backup and it must not be zipped. E.g. `/scratch/oradata/dbfiles/ORCL3CDB/SEEDCDB` where `SEEDCDB` is the cold backup and contains datafiles and PDB.

```bash
docker run -d --hostname oshard3-0 \
--dns-search=example.com \
--network=shard_pub1_nw \
--ip=10.0.20.105 \
-e DOMAIN=example.com \
-e ORACLE_SID=ORCL3CDB \
-e ORACLE_PDB=ORCL3PDB \
-e OP_TYPE=primaryshard \
-e COMMON_OS_PWD_FILE=pwdfile.enc \
-e PWD_KEY=key.pem \
-e SHARD_SETUP="true" \
-e ENABLE_ARCHIVELOG=true \
-v /scratch/oradata/dbfiles/ORCL3CDB:/opt/oracle/oradata \
-v /opt/containers/shard_host_file:/etc/hosts \
--volume /opt/.secrets:/run/secrets:ro \
--privileged=false \
--name shard3 oracle/database-ext-sharding:21.3.0-ee
```

To check the shard3 container/services creation logs, please tail docker logs. It will take 20 minutes to create the shard1 container service.

```bash
docker logs -f shard3
```

**IMPORTANT:** Like the earlier shards (shard1 and shard2), wait for the following lines highlight when the Shard3 database is ready to be used:

```bash
==============================================
      GSM Shard Setup Completed
==============================================
```

### Add the new shard Database to the existing Oracle Globally Distributed Database

Use the below command to add the new shard3:

```bash
docker exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py --addshard="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_space=shardspace3;shard_region=region1"
```

Use the below command to check the status of the newly added shard:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard
```

### Deploy the new shard

Deploy the newly added shard (shard3):

```bash
docker exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py --deployshard=true
```

Use the below command to check the status of the newly added shard and the chunks distribution:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Move chunks

In case you want to move some chunks to the newly added Shard from an existing Shard, you can use the below command:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK $CHUNK_ID -SOURCE $SOURCE_SHARD -TARGET $TARGET_SHARD
```

Example: If you want to move the chunk with chunk id `3` from source shard `ORCL1CDB_ORCL1PDB` to target shard `ORCL3CDB_ORCL3PDB`, then you can use the below command:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK 3 -SOURCE ORCL1CDB_ORCL1PDB -TARGET ORCL3CDB_ORCL3PDB
```

Use the below command to check the status of the chunks distribution:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
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
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Move the chunks out of the shard database which you want to delete

In the current example, if you want to delete the shard3 database from the Oracle Globally Distributed Database, then you need to use the below command to move the chunks out of shard3 database:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK $CHUNK_ID -SOURCE $SOURCE_SHARD -TARGET $TARGET_SHARD
```

Example: If you want to move the chunk with chunk id `3` from source shard `ORCL3CDB_ORCL3PDB` to target shard `ORCL1CDB_ORCL1PDB`, then you can use the below command:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl MOVE CHUNK -CHUNK 3 -SOURCE ORCL3CDB_ORCL3PDB -TARGET ORCL1CDB_ORCL1PDB
```

**NOTE:** To move more than 1 chunk, you can specify comma separated chunk ids.

After moving the chunks out, use the below command to confirm there is no chunk present in the shard database which you want to delete:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

**NOTE:** You will need to wait for some time for all the chunks to move out of the shard database which you want to delete.

### Delete the shard database from the Oracle Globally Distributed Database

Once you have confirmed that no chunk is present in the shard to be deleted in earlier step, you can use the below command to delete that shard(shard3 in this case):

```bash
docker exec -it gsm1 python /opt/oracle/scripts/sharding/scripts/main.py  --deleteshard="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_space=shardspace3;shard_region=region1"
```

**NOTE:** In this case, `oshard3-0`, `ORCL3CDB` and `ORCL3PDB` are the names of host, CDB and PDB for the shard3 respectively.

### Confirm the shard has been successfully deleted from the Oracle Globally Distributed Database

Once the shard is deleted from the Oracle Globally Distributed Database, use the below commands to check the status of the shards and chunk distribution in the Oracle Globally Distributed Database:

```bash
docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config shard

docker exec -it gsm1 $(docker exec -it gsm1 env | grep ORACLE_HOME | cut -d= -f2 | tr -d '\r')/bin/gdsctl config chunks
```

### Remove the Docker Container

Once the shard is deleted from the Oracle Globally Distributed Database, you can remove the Docker Container which was deployed earlier for the deleted shard database.

If the deleted shard was `shard3`, to remove its Docker Container, please use the below steps:

- Stop and remove the Docker Container for shard3:

```bash
docker stop shard3
docker rm shard3
```

- Remove the directory containing the files for this deleted Docker Container:

```bash
rm -rf /scratch/oradata/dbfiles/ORCL3CDB
```

## Environment Variables Explained

**For Catalog and Shard Containers:**

| Mandatory Parameters      | Description                                                                                               |
|---------------------------|-----------------------------------------------------------------------------------------------------------|
| COMMON_OS_PWD_FILE        | Specify the encrypted password file to be read inside the container                                       |
| PWD_KEY                   | Specify password key file to decrypt the encrypted password file and read the password                    |
| OP_TYPE                   | Specify the operation type. For Shards it has to be set to catalog or primaryshard/standbyshard           |
| DOMAIN                    | Specify the domain name                                                                                   |
| ORACLE_SID                | CDB name                                                                                                  |
| ORACLE_PDB                | PDB name                                                                                                  |

| Optional Parameters       | Description                                                                                               |
|---------------------------|-----------------------------------------------------------------------------------------------------------|
| CUSTOM_SHARD_SCRIPT_DIR   | Specify the location of custom scripts that you want to run after setting up the catalog or shard setup   |
| CUSTOM_SHARD_SCRIPT_FILE  | Specify the file name which must be available on CUSTOM_SHARD_SCRIPT_DIR location to be executed          |
| CLONE_DB                  | Specify value "true" if you want to avoid db creation and clone it from cold backup of existing Oracle DB |
| OLD_ORACLE_SID            | Specify the OLD_ORACLE_SID if you are performing db seed clonging using existing cold backup of Oracle DB |
| OLD_ORACLE_PDB            | Specify the OLD_ORACLE_PDB if you are performing db seed cloning using existing cold backup of Oracle DB  |

**For GSM Containers:**

| Mandatory Parameters            | Description                                                                                                                            |
|---------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| SHARD_DIRECTOR_PARAMS           | Accepts key=value pairs for shard director configuration.                                                                              |
|                                 |   - director_name: Shard director name                                                                                                 |
|                                 |   - director_region: Shard director region                                                                                             |
|                                 |   - director_port: Shard director port                                                                                                 |
| SHARD[1-9]_GROUP_PARAMS         | Accepts key=value pairs for shard group configuration.                                                                                 |
|                                 |   - group_name: Shard group name                                                                                                       |
|                                 |   - deploy_as: Deploy shard group as primary or active_standby                                                                         |
|                                 |   - group_region: Shard group region name                                                                                              |
| CATALOG_PARAMS                  | Accepts key=value pairs for catalog configuration.                                                                                     |
|                                 |   - catalog_host: Catalog hostname                                                                                                     |
|                                 |   - catalog_db: Catalog CDB name                                                                                                       |
|                                 |   - catalog_pdb: Catalog PDB name                                                                                                      |
|                                 |   - catalog_port: Catalog DB port name                                                                                                 |
|                                 |   - catalog_name: Catalog name in GSM                                                                                                  |
|                                 |   - catalog_region: Comma-separated region name for catalog DB deployment                                                              |
| SHARD[1-9]_PARAMS               | Accepts key=value pairs for shard configuration.                                                                                       |
|                                 |   - shard_host: Shard hostname                                                                                                         |
|                                 |   - shard_db: Shard CDB name                                                                                                           |
|                                 |   - shard_pdb: Shard PDB name                                                                                                          |
|                                 |   - shard_port: Shard DB port                                                                                                          |
|                                 |   - shard_group: Shard group name                                                                                                      |
| SERVICE[1-9]_PARAMS             | Accepts key=value pairs for service configuration.                                                                                     |
|                                 |   - service_name: Service name                                                                                                         |
|                                 |   - service_role: Service role (e.g., primary or physical_standby)                                                                     |
| COMMON_OS_PWD_FILE              | Specifies the encrypted password file to be read inside the container.                                                                 |
| PWD_KEY                         | Specifies the password key file to decrypt the encrypted password file and read the password.                                          |
| OP_TYPE                         | Specifies the operation type. For GSM, it has to be set to gsm.                                                                        |
| DOMAIN                          | Specifies the domain of the container.                                                                                                 |
| MASTER_GSM                      | Set to "TRUE" if you want the GSM to be a master GSM; otherwise, do not set it.                                                        |

| Optional Parameters             | Description                                                                                                                            |
|---------------------------------|-------------------------------------------------------------------------------------------------------------                           |
| GSM_TRACE_LEVEL                 | Specify tacing level for the GSM(Specify USER or ADMIN or SUPPORT or OFF, default value as OFF)                                        |
| SAMPLE_SCHEMA                   | Specify a value to "DEPLOY" if you want to deploy a sample app schema in the catalog DB during GSM setup.                              |
| CUSTOM_SHARD_SCRIPT_DIR         | Specify the location of custom scripts that you want to run after setting up GSM.                                                      |
| CUSTOM_SHARD_SCRIPT_FILE        | Specify the filename that must be available on CUSTOM_SHARD_SCRIPT_DIR location to be executed after GSM setup.                        |
| BASE_DIR                        | Specify BASE_DIR if you want to change the base location of the scripts to set up GSM. Default is set to $INSTALL_DIR/startup/scripts. |
| SCRIPT_NAME                     | Specify the script name which will be executed from BASE_DIR. Default set to main.py.                                                  |
| EXECUTOR                        | Specify the script executor such as /bin/python or /bin/bash. Default set to /bin/python.                                              |
| CATALOG_SETUP                   | Accepts True. If set, it will only restrict till catalog connection and setup.                                                         |
| CATALOG_PARAMS                  | Accepts key-value pairs for catalog configuration. Refer to the Mandatory Parameters section.                                          |

## Support

Oracle Globally Distributed Database on Docker is supported on Oracle Linux 7.
Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and onwards.

## License

To run Oracle Globally Distributed Database, regardless whether inside or outside a Container, ensure to download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
