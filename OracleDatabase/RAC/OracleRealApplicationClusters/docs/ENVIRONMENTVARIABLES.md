# Environment Variables Explained for Oracle RAC on Podman

| Environment Variable     | Mandatory/Optional | Usage      | Description                                                  |
|--------------------------|---------------------|------------|--------------------------------------------------------------|
| DNS_SERVERS              | Mandatory           | All        | Specify the comma-separated list of DNS server IP addresses where both Oracle RAC nodes are resolved. |
| OP_TYPE                  | Mandatory           | All        | Specify the operation type. It can accept setuprac/setupgrid/addgridnode/racaddnode/setupracstandby. |
| CRS_NODES                | Mandatory           | All        | Specify the CRS nodes in the format pubhost:pubhost1,viphost:viphost1;pubhost:pubhost2,viphost:viphost2. You can add as many hosts separated by semicolon. pubhost and viphost are separated by comma. When passing this through the shell, quote the whole value, for example `CRS_NODES="pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip"`. |
| SCAN_NAME                | Mandatory           | All        | Specify the SCAN name. |
| CRS_ASM_DEVICE_LIST      | Mandatory           | All        | Specify the ASM disk lists. |
| PUBLIC_HOSTS_DOMAIN      | Optional            | All        | Specify public domain where RAC containers are resolving to. |
| CRS_ASM_DISCOVERY_STRING | Optional            | All        | Specify the discovery string for ASM. |
| ORACLE_SID               | Optional            | All        | Default value set to ORCLCDB. |
| ORACLE_PDB               | Optional            | All        | Default value set to ORCLPDB. |
| ORACLE_CHARACTERSET      | Optional            | All        | Default value set to AL32UTF8. |
| RAC_SECRET               | Mandatory only for `setup_rac_host.sh -prepare-rac-env` | Host preparation | Password value used by the host preparation script to create Podman secrets. Not passed to RAC containers. |
| RAC_SECRET_MODE          | Optional            | Host preparation | Secret creation mode for `setup_rac_host.sh -prepare-rac-env`. Supported values are `openssl` and `base64`. Default value is `openssl`. Not passed to RAC containers. |
| ORACLE_PWD               | Optional            | All        | Plain password value for the Oracle RAC database users. If set, DB password secret files are not required. |
| ENCRYPTION_TYPE          | Optional            | All        | Password secret decryption type. Supported values are `pkeyutl`, `aes256`, and `rsautl`. Default value is `pkeyutl`. |
| PKEYOPT                  | Optional            | All        | Semicolon-separated OpenSSL `pkeyutl` options. Used only when `ENCRYPTION_TYPE=pkeyutl`. Default value is `rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256`. |
| PWD_KEY                  | Mandatory only for OpenSSL encrypted password secrets | All | Pass the Podman secret name for the private key used to decrypt `DB_PWD_FILE`. Default value is `pwd.key`. Not required when using `PASSWORD_FILE` or `ORACLE_PWD`. |
| DB_PWD_FILE              | Mandatory only for OpenSSL encrypted password secrets | All | Pass the Podman secret name for the encrypted Oracle RAC database password file. Default value is `common_os_pwdfile.enc`. Not required when using `PASSWORD_FILE` or `ORACLE_PWD`. |
| PASSWORD_FILE            | Mandatory only for Base64 password secrets | All | Pass the Podman secret name for the Base64 encoded Oracle RAC database password file. Default value is `dbpasswd.file`. Not required when using `DB_PWD_FILE` with `PWD_KEY` or `ORACLE_PWD`. |
| KEY_SECRET_VOLUME        | Optional            | All        | Secret volume for `PWD_KEY`. Defaults to `SECRET_VOLUME` when not set. |
| SECRET_VOLUME            | Optional            | All        | Secret volume for password files. Default value is `/run/secrets`. |
| PWD_VOLUME               | Optional            | All        | Temporary directory used while decrypting or decoding password files. Default value is `/var/tmp`. |
| TDE_ENCRYPTION_TYPE      | Optional            | TDE setup  | TDE password secret decryption type. Supported values are `pkeyutl`, `aes256`, and `rsautl`. If not set, TDE password decryption uses `ENCRYPTION_TYPE` behavior. |
| TDE_PKEYOPT              | Optional            | TDE setup  | Semicolon-separated OpenSSL `pkeyutl` options for the TDE password secret. Default value is `rsa_padding_mode:oaep;rsa_oaep_md:sha256;rsa_mgf1_md:sha256`. |
| TDE_PWD_KEY              | Mandatory only for encrypted TDE password secrets | TDE setup | Pass the Podman secret name for the private key used to decrypt `TDE_PWD_FILE`. Not required when using `TDE_PASSWORD_FILE`. |
| TDE_PASSWORD_FILE        | Mandatory only for Base64 TDE password secrets | TDE setup | Pass the Podman secret name for the Base64 encoded TDE password file. Default value is `tdepwdfile`. |
| INIT_SGA_SIZE            | Optional            | All        | Set this environment variable when you want to set the size of SGA for RAC containers. |
| INIT_PGA_SIZE            | Optional            | All        | Set this environment variable when you want to set the size of PGA for RAC containers. |
| CRS_PRIVATE_IP1          | Mandatory           | All        | Set this environment variable when you want to set the private IP for the first private network for RAC container. |
| CRS_PRIVATE_IP2          | Mandatory           | All        | Set this environment variable when you want to set the private IP for the second private network for RAC container. |
| INSTALL_NODE             | Mandatory           | All        | Set this environment variable to the Oracle node where the actual RAC cluster installation will happen. e.g. During deploying two node RAC database with racnodep1 and racnodep2, you can set it to racnodep1. In case of addition third node named racnodep3, set it to the new node name i.e. racnodep3 |
| EXISTING_CLS_NODE        | Mandatory only during Node Addition | Node Addition | This is set during addition of node to Existing RAC Cluster. Set this environment variable to existing Oracle RAC node e.g., racnodep1, racnodep2. |
| DB_ASM_DEVICE_LIST       | Optional            | All        | Comma-separated list of ASM disk names with full paths. |
| RECO_ASM_DEVICE_LIST     | Optional            | All        | Comma-separated list of ASM disk names with full paths. |
| DB_DATA_FILE_DEST        | Optional            | All        | Name of the diskgroup where database data files will be stored. |
| DB_RECOVERY_FILE_DEST    | Optional            | All        | Name of the diskgroup for Fast Recovery Area usage. |
| CMAN_HOST                | Optional            | All        | Specify the host for Oracle Connection Manager (CMAN). Default value is set to racnodepc1-cman. |
| CMAN_PORT                | Optional            | All        | Specify the port for Oracle Connection Manager (CMAN). Default port is set to 1521. |
| DB_UNIQUE_NAME           | Mandatory           | Standby (DG Setup) | Specify the unique name for the standby database. |
| PRIMARY_DB_SCAN_NAME     | Mandatory           | Standby (DG Setup) | Specify the SCAN name of the primary database. |
| CRS_ASM_DISKGROUP        | Mandatory           | Standby (DG Setup) | Specify the ASM diskgroup for the standby database. |
| PRIMARY_DB_UNIQUE_NAME   | Mandatory           | Standby (DG Setup) | Specify the unique name of the primary database. |
| PRIMARY_DB_NAME          | Mandatory           | Standby (DG Setup) | Specify the name of the primary database. |
| DB_BLOCK_CHECKSUM        | Mandatory           | Primary and Standby (DG Setup) | Specify the type of DB block checksum to use. |
| DB_SERVICE               | Optional            | All        | Specify the database service. Format: service:soepdb. |
| GRID_HOME                | Mandatory           | Setup using Slim Image | Path to Oracle Grid Infrastructure home directory. Default value is `/u01/app/26ai/grid`. |
| GRID_BASE                | Mandatory           | Setup using Slim Image | Path to the base directory of Oracle Grid Infrastructure. Default value is `/u01/app/grid`. |
| DB_HOME                  | Mandatory           | Setup using Slim Image | Path to Oracle Database home directory. Default value is `/u01/app/oracle/product/26ai/dbhome_1`. |
| DB_BASE                  | Mandatory           | Setup using Slim Image | Path to the base directory of Oracle Database. Default value is `/u01/app/oracle`. |
| INVENTORY                | Mandatory           | Setup using Slim Image | Path to the Oracle Inventory directory. Default value is `/u01/app/oraInventory`. |
| STAGING_SOFTWARE_LOC     | Mandatory           | Setup using Slim Image | Location where the Oracle software zip files are staged. Default value is `/scratch/software/23.26ai/goldimages`. |
| GRID_SW_ZIP_FILE         | Mandatory           | Setup using Slim Image | Name of the Oracle Grid Infrastructure software zip file. Default value is `LINUX.X64_260000_grid_home.zip`. |
| DB_SW_ZIP_FILE           | Mandatory           | Setup using Slim Image | Name of the Oracle Database software zip file. Default value is `LINUX.X64_260000_db_home.zip`. |
| GRID_RESPONSE_FILE       | Mandatory           | Setup using User Defined Response Files | Path to the Oracle Grid Infrastructure response file. Default value is `/tmp/grid_23.26ai.rsp`. |
| DBCA_RESPONSE_FILE       | Mandatory           | Setup using User Defined Response Files | Path to the Oracle Database Configuration Assistant (DBCA) response file. Default value is `/tmp/dbca_23.26ai.rsp`. |

## License

All scripts and files hosted in this repository which are required to build the container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
