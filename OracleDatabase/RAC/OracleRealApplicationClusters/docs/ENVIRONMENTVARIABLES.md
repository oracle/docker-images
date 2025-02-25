# Environment Variables Explained for Oracle RAC on Podman

This section provides information about the environment variables that can be used when creating Oracle RAC on Containers.

| Environment Variable     | Mandatory/Optional | Usage      | Description                                                  |
|--------------------------|---------------------|------------|--------------------------------------------------------------|
| DNS_SERVERS              | Mandatory           | All        | Specify the comma-separated list of DNS server IP addresses where both Oracle RAC nodes are resolved. |
| OP_TYPE                  | Mandatory           | All        | Specify the operation type. It can accept setuprac/setupgrid/addgridnode/racaddnode/setupracstandby. |
| CRS_NODES                | Mandatory           | All        | Specify the CRS nodes in the format pubhost:pubhost1,viphost:viphost1;pubhost:pubhost2,viphost:viphost2. You can add as many hosts separated by semicolon. publhost and viphost are separated by comma. |
| SCAN_NAME                | Mandatory           | All        | Specify the SCAN name.                                        |
| CRS_ASM_DEVICE_LIST      | Mandatory           | All        | Specify the ASM disk lists.                                   |
| PUBLIC_HOSTS_DOMAIN      | Optional            | All        | Specify public domain where RAC Containers are resolving to. |
| CRS_ASM_DISCOVERY_STRING | Optional           | All        | Specify the discovery string for ASM.                        |
| ORACLE_SID               | Optional            | All        | Default value set to ORCLCDB.                                 |
| ORACLE_PDB               | Optional            | All        | Default value set to ORCLPDB.                                 |
| ORACLE_CHARACTERSET      | Optional            | All        | Default value set to AL32UTF8.                                |
| PWD_KEY                  | Mandatory           | All        | Pass the podman secret name for the key used while generating podman secrets. Default set to keysecret. |
| DB_PWD_FILE              | Mandatory           | All        | Pass the podman secret name for the Oracle RAC Database to be used while generating podman secrets. Default set to pwdsecret. |
| INIT_SGA_SIZE            | Optional            | All        | Set this environment variable when you want to set the size of SGA for RAC containers. |
| INIT_PGA_SIZE            | Optional            | All        | Set this environment variable when you want to set the size of PGA for RAC containers. |
| CRS_PRIVATE_IP1          | Mandatory           | All        | Set this environment variable when you want to set the private IP for the first private network for RAC container. |
| CRS_PRIVATE_IP2          | Mandatory           | All        | Set this environment variable when you want to set the private IP for the second private network for RAC container. |
| INSTALL_NODE             | Mandatory           | All        | Set this environment variable to the new Oracle node where the actual RAC cluster installation will happen. e.g., racnodep1/racnodep3 etc. |
| EXISTING_CLS_NODE        | Mandatory           | Mandatory only during Node Addition to existing RAC Cluster | This is set during addition of node to Existing RAC Cluster. Set this environment variable to existing Oracle RAC node e.g., racnodep1, racnodep2. |
| DB_ASM_DEVICE_LIST       | Optional           | All        | Comma-separated list of ASM disk names with their full paths.  |
| RECO_ASM_DEVICE_LIST     | Optional           | All        | Comma-separated list of ASM disk names with their full paths.  |
| DB_DATA_FILE_DEST        | Optional           | All        | Name of the diskgroup where database data files will be stored. |
| DB_RECOVERY_FILE_DEST    | Optional           | All        | Name of the diskgroup where database recovery files (archivelogs) will be stored. |
| CMAN_HOST                | Optional           | All        | Specify the host for Oracle Connection Manager (CMAN). Default value is set to racnodepc1-cman. |
| CMAN_PORT                | Optional           | All        | Specify the port for Oracle Connection Manager (CMAN). Default port is set to 1521. |
| DB_UNIQUE_NAME           | Mandatory           | Standby (DG Setup) | Specify the unique name for the standby database. |
| PRIMARY_DB_SCAN_NAME     | Mandatory           | Standby (DG Setup) | Specify the SCAN name of the primary database. |
| CRS_ASM_DISKGROUP        | Mandatory           | Standby (DG Setup) | Specify the ASM diskgroup for the standby database. |
| PRIMARY_DB_UNIQUE_NAME   | Mandatory           | Standby (DG Setup) | Specify the unique name of the primary database. |
| PRIMARY_DB_NAME          | Mandatory           | Standby (DG Setup) | Specify the name of the primary database. |
| DB_BLOCK_CHECKSUM        | Mandatory           | Primary and Standby (DG Setup) | Specify the type of DB block checksum to use. |
| DB_SERVICE               | Optional           | All        | Specify the database service. Format: service:soepdb. |
| GRID_HOME                | Mandatory           | Setup using Slim Image | Path to Oracle Grid Infrastructure home directory. Default value is `/u01/app/21c/grid`. |
| GRID_BASE                | Mandatory           | Setup using Slim Image | Path to the base directory of Oracle Grid Infrastructure. Default value is `/u01/app/grid`. |
| DB_HOME                  | Mandatory           | Setup using Slim Image | Path to Oracle Database home directory. Default value is `/u01/app/oracle/product/21c/dbhome_1`. |
| DB_BASE                  | Mandatory           | Setup using Slim Image | Path to the base directory of Oracle Database. Default value is `/u01/app/oracle`. |
| INVENTORY                | Mandatory           | Setup using Slim Image | Path to the Oracle Inventory directory. Default value is `/u01/app/oraInventory`. |
| STAGING_SOFTWARE_LOC     | Mandatory           | Setup using Slim Image | Location where the Oracle software zip files are staged. Default value is `/scratch/software/21c/goldimages/`. |
| GRID_SW_ZIP_FILE         | Mandatory           | Setup using Slim Image | Name of the Oracle Grid Infrastructure software zip file. Default value is `LINUX.X64_213000_grid_home.zip`. |
| DB_SW_ZIP_FILE           | Mandatory           | Setup using Slim Image | Name of the Oracle Database software zip file. Default value is `LINUX.X64_213000_db_home.zip`. |
| GRID_RESPONSE_FILE       | Mandatory           | Setup using User Defined Response Files | Path to the Oracle Grid Infrastructure response file. Default value is `/tmp/grid_21c.rsp`. |
| DBCA_RESPONSE_FILE       | Mandatory           | Setup using User Defined Response Files | Path to the Oracle Database Configuration Assistant (DBCA) response file. Default value is `/tmp/dbca_21c.rsp`. |

## License

All scripts and files hosted in this repository which are required to build the container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
