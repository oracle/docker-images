#!/bin/bash

# Variables to be exported before using podman-compose to deploy Globally Distributed Database using podman with Enterprise Images    
export PODMANVOLLOC='/scratch/oradata'
export NETWORK_INTERFACE='ens3'
export NETWORK_SUBNET="10.0.20.0/20"
export SIDB_IMAGE='container-registry.oracle.com/database/enterprise:latest'
export GSM_IMAGE='container-registry.oracle.com/database/gsm:latest'
export LOCAL_NETWORK=10.0.20
export healthcheck_interval=30s
export healthcheck_timeout=3s
export healthcheck_retries=40
export CATALOG_OP_TYPE="catalog"
export ALLSHARD_OP_TYPE="primaryshard"
export GSM_OP_TYPE="gsm"
export CAT_SHARD_SETUP="true"
export CATALOG_ARCHIVELOG="true"
export SHARD_ARCHIVELOG="true"
export SHARD1_SHARD_SETUP="true"
export SHARD2_SHARD_SETUP="true"
export SHARD3_SHARD_SETUP="true"
export SHARD4_SHARD_SETUP="true"
export PRIMARY_GSM_SHARD_SETUP="true"
export STANDBY_GSM_SHARD_SETUP="true"

export CONTAINER_RESTART_POLICY="always"
export CONTAINER_PRIVILEGED_FLAG="false"
export DOMAIN="example.com"
export DNS_SEARCH="example.com"
export CAT_CDB="CATCDB"
export CAT_PDB="CAT1PDB"
export CAT_HOSTNAME="oshard-catalog-0"
export CAT_CONTAINER_NAME="catalog"

export SHARD1_CONTAINER_NAME="shard1"
export SHARD1_HOSTNAME="oshard1-0"
export SHARD1_CDB="ORCL1CDB"
export SHARD1_PDB="ORCL1PDB"

export SHARD2_CONTAINER_NAME="shard2"
export SHARD2_HOSTNAME="oshard2-0"
export SHARD2_CDB="ORCL2CDB"
export SHARD2_PDB="ORCL2PDB"

export SHARD3_CONTAINER_NAME="shard3"
export SHARD3_HOSTNAME="oshard3-0"
export SHARD3_CDB="ORCL3CDB"
export SHARD3_PDB="ORCL3PDB"

export SHARD4_CONTAINER_NAME="shard4"
export SHARD4_HOSTNAME="oshard4-0"
export SHARD4_CDB="ORCL4CDB"
export SHARD4_PDB="ORCL4PDB"

export PRIMARY_GSM_CONTAINER_NAME="gsm1"
export PRIMARY_GSM_HOSTNAME="oshard-gsm1"
export STANDBY_GSM_CONTAINER_NAME="gsm2"
export STANDBY_GSM_HOSTNAME="oshard-gsm2"


export PRIMARY_SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522"
export PRIMARY_SHARD1_GROUP_PARAMS="group_name=shardgroup1;deploy_as=primary;group_region=region1"
export PRIMARY_CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2"    
export PRIMARY_SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1"
export PRIMARY_SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1"
export PRIMARY_SHARD3_PARAMS="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1"
export PRIMARY_SHARD4_PARAMS="shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1"
export PRIMARY_SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary"
export PRIMARY_SERVICE2_PARAMS="service_name=oltp_rw_svc;service_role=primary"

export STANDBY_SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region1;director_port=1522   "
export STANDBY_SHARD1_GROUP_PARAMS="group_name=shardgroup1;deploy_as=active_standby;group_region=region1"
export STANDBY_CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2"
export STANDBY_SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1"
export STANDBY_SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1"
export STANDBY_SHARD3_PARAMS="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1"
export STANDBY_SHARD4_PARAMS="shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1"
export STANDBY_SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=standby"
export STANDBY_SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=standby"

# Create network host file
mkdir -p  /opt/containers
rm -f /opt/containers/shard_host_file && touch /opt/containers/shard_host_file
sh -c "cat << EOF > /opt/containers/shard_host_file
127.0.0.1        localhost.localdomain           localhost
${LOCAL_NETWORK}.100     oshard-gsm1.example.com         oshard-gsm1
${LOCAL_NETWORK}.102     oshard-catalog-0.example.com    oshard-catalog-0
${LOCAL_NETWORK}.103     oshard1-0.example.com           oshard1-0
${LOCAL_NETWORK}.104     oshard2-0.example.com           oshard2-0
${LOCAL_NETWORK}.105     oshard3-0.example.com           oshard3-0
${LOCAL_NETWORK}.106     oshard4-0.example.com           oshard4-0
${LOCAL_NETWORK}.101     oshard-gsm2.example.com         oshard-gsm2

EOF
"

# Create required directries
mkdir -p ${PODMANVOLLOC}/scripts
chown -R 54321:54321 ${PODMANVOLLOC}/scripts
chmod 755 ${PODMANVOLLOC}/scripts

mkdir -p ${PODMANVOLLOC}/dbfiles/CATALOG
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/CATALOG

mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL1CDB
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL1CDB
mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL2CDB
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL2CDB
mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL3CDB
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL3CDB
mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL4CDB
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL4CDB

mkdir -p ${PODMANVOLLOC}/dbfiles/GSMDATA
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/GSMDATA

mkdir -p ${PODMANVOLLOC}/dbfiles/GSM2DATA
chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/GSM2DATA

chmod 755 ${PODMANVOLLOC}/dbfiles/CATALOG
chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL1CDB
chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL2CDB
chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL3CDB
chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL4CDB
chmod 755 ${PODMANVOLLOC}/dbfiles/GSMDATA
chmod 755 ${PODMANVOLLOC}/dbfiles/GSM2DATA