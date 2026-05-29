# ENVIRONMENT VARIABLE DETAILS FOR ORACLE GLOBALLY DISTRIBUTED DATABASE USING PODMAN COMPOSE

| Environment Variable           | Description                                                        | Default Value                                                                |
|--------------------------------|--------------------------------------------------------------------|------------------------------------------------------------------------------|
| PODMANVOLLOC                   | Location of podman volume for storing Database Files               | /scratch/oradata                                                             |
| NETWORK_INTERFACE              | Network interface name on host machines                            | ens3                                                                         |
| NETWORK_SUBNET                 | Network subnet                                                     | 10.0.20.0/20                                                                 |
| SIDB_IMAGE                     | Podman Image with sharding extension for SIDB container            |                                                                              |
| GSM_IMAGE                      | Podman Image for GSM container                                     |                                                                              |
| LOCAL_NETWORK                  | Local network address                                              | 10.0.20                                                                      |
| healthcheck_interval           | Interval for health check                                          | 30s                                                                          |
| healthcheck_timeout            | Timeout for health check                                           | 3s                                                                           |
| healthcheck_retries            | Number of retries for health check                                 | 40                                                                           |
| CATALOG_OP_TYPE                | Operation type for catalog                                         | catalog                                                                      |
| ALLSHARD_OP_TYPE               | Operation type for all shards                                      | primaryshard                                                                 |
| GSM_OP_TYPE                    | Operation type for GSM                                             | gsm                                                                          |
| PWD_SECRET_FILE                | Path to the encrypted password file                                | /opt/.secrets/pwdfile.enc                                                    |
| KEY_SECRET_FILE                | Path to the secret key file to decrypt the encrypted password file | /opt/.secrets/key.pem                                                        |
| CAT_SHARD_SETUP                | Set to "true" to enable catalog shard setup                        | true                                                                         |
| CATALOG_ARCHIVELOG             | Set to "true" to enable catalog archivelog mode                    | true                                                                         |
| SHARD_ARCHIVELOG               | Set to "true" to enable shard archivelog mode                      | true                                                                         |
| SHARD[1-4]_SHARD_SETUP         | Set to "true" to enable shard setup for each shard                 | true                                                                         |
| PRIMARY_GSM_SHARD_SETUP        | Set to "true" to enable primary GSM shard setup                    | true                                                                         |
| STANDBY_GSM_SHARD_SETUP        | Set to "true" to enable standby GSM shard setup                    | true                                                                         |
| CONTAINER_RESTART_POLICY       | Container restart policy                                           | always                                                                       |
| CONTAINER_PRIVILEGED_FLAG      | Set to "true" for container privileged mode, "false" otherwise     | false                                                                        |
| DOMAIN                         | Domain name                                                        | example.com                                                                  |
| DNS_SEARCH                     | DNS search domain                                                  | example.com                                                                  |
| CAT_CDB                        | Catalog CDB name                                                   | CATCDB                                                                       |
| CAT_PDB                        | Catalog PDB name                                                   | CAT1PDB                                                                      |
| CAT_HOSTNAME                   | Catalog hostname                                                   | oshard-catalog-0                                                             |
| CAT_CONTAINER_NAME             | Catalog container name                                             | catalog                                                                      |
| SHARD[1-4]_CONTAINER_NAME      | Shard container name                                               | shard1, shard2, shard3, shard4                                               |
| SHARD[1-4]_HOSTNAME            | Shard hostname                                                     | oshard1-0, oshard2-0, oshard3-0, oshard4-0                                   |
| SHARD[1-4]_CDB                 | Shard CDB name                                                     | ORCL1CDB, ORCL2CDB, ORCL3CDB, ORCL4CDB                                       |
| SHARD[1-4]_PDB                 | Shard PDB name                                                     | ORCL1PDB, ORCL2PDB, ORCL3PDB, ORCL4PDB                                       |
| PRIMARY_GSM_CONTAINER_NAME     | Primary GSM container name                                         | gsm1                                                                         |
| PRIMARY_GSM_HOSTNAME           | Primary GSM hostname                                               | oshard-gsm1                                                                  |
| STANDBY_GSM_CONTAINER_NAME     | Standby GSM container name                                         | gsm2                                                                         |
| STANDBY_GSM_HOSTNAME           | Standby GSM hostname                                               | oshard-gsm2                                                                  |
| PRIMARY_SHARD_DIRECTOR_PARAMS  | Parameters for primary shard director                              | director_name=sharddirector1;director_region=region1;director_port=1522      |
| PRIMARY_SHARD[1-2]_GROUP_PARAMS| Parameters for primary shard groups                                | group_name=shardgroup1;deploy_as=primary/active_standby;group_region=region1 |
| PRIMARY_CATALOG_PARAMS         | Parameters for primary catalog                                     | catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;         |
|                                |                                                                    | catalog_port=1521;catalog_name=shardcatalog1;                                |
|                                |                                                                    | catalog_region=region1,region2;catalog_chunks=30;repl_type=Native            |
| PRIMARY_SHARD[1-2]_PARAMS      | Parameters for primary shards                                      | shard_host=oshard1-0/oshard2-0;shard_db=ORCL1CDB/ORCL2CDB;                   |
|                                |                                                                    | shard_pdb=ORCL1PDB/ORCL2PDB;shard_port=1521;shard_group=shardgroup1          |
| PRIMARY_SERVICE[1-2]_PARAMS    | Parameters for primary services                                    | service_name=oltp_rw_svc;service_role=primary                                |
| STANDBY_SHARD_DIRECTOR_PARAMS  | Parameters for standby shard director                              | director_name=sharddirector2;director_region=region1;director_port=1522      |
| STANDBY_SHARD[1-4]_GROUP_PARAMS| Parameters for standby shard groups                                | group_name=shardgroup1;deploy_as=active_standby;group_region=region1         |
| STANDBY_CATALOG_PARAMS         | Parameters for standby catalog                                     | catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;         |
|                                |                                                                    | catalog_port=1521;catalog_name=shardcatalog1;                                |
|                                |                                                                    | catalog_region=region1,region2;catalog_chunks=30;repl_type=Native            |
| STANDBY_SHARD[1-4]_PARAMS      | Parameters for standby shards                                      | shard_host=oshard1-0/oshard2-0/oshard3-0/oshard4-0;                          |
|                                |                                                                    | shard_db=ORCL1CDB/ORCL2CDB/ORCL3CDB/ORCL4CDB;                                |
|                                |                                                                    | shard_pdb=ORCL1PDB/ORCL2PDB/ORCL3PDB/ORCL4PDB;                               |
|                                |                                                                    | shard_port=1521;shard_group=shardgroup1                                      |
| STANDBY_SERVICE[1-2]_PARAMS    | Parameters for standby services                                    | service_name=oltp_rw_svc/oltp_ro_svc;service_role=standby                    |
