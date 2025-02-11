# Environment Variables Explained for Oracle RAC on Podman Compose

Learn about the environment variables (env variables) that you can use when creating a two-node Oracle Real Application Clusters (Oracle RAC) cluster.

| Variable Name              | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| DNS_PUBLIC_IP              | Default set to `10.0.20.25`. Set this env variable when you want to set DNS container public IP address where both Oracle RAC nodes are resolved. |
| DNS_CONTAINER_NAME         | Default set to `rac-dnsserver`. Set this env variable when you want to set a name for the DNS container. |
| DNS_HOST_NAME              | Default set to `racdns`. Set this env variable when you want to set the DNS container host name. |
| DNS_IMAGE_NAME             | Default set to `"localhost/oracle/rac-dnsserver:latest"`. Set this env variable when you want to set the DNS image name. |
| RAC_NODE_NAME_PREFIXP      | Default set to `racnodep`. Set this env variable when you want to use a different prefix for DNS podman container resolutions. |
| DNS_DOMAIN                 | Default set to `example.info`. Set this env variable when you want to set the DNS domain. |
| PUBLIC_NETWORK_NAME        | Default set to `rac_pub1_nw`. Set this env variable when you want to set the public podman network name for the Oracle RAC cluster. |
| PUBLIC_NETWORK_SUBNET      | Default set to `10.0.20.0/24`. Set this env variable when you want to set the public network subnet. |
| PRIVATE1_NETWORK_NAME      | Default set to `rac_priv1_nw`. Set this env variable when you want to specify the first private network name. |
| PRIVATE1_NETWORK_SUBNET    | Default set to `192.168.17.0/24`. Set this env variable when you want to set the first private network subnet. |
| PRIVATE2_NETWORK_NAME      | Default set to `rac_priv2_nw`. Set this env variable when you want to specify the second private network name. |
| PRIVATE2_NETWORK_SUBNET    | Default set to `192.168.18.0/24`. Set this env variable when you want to set the second private network subnet. |
| RACNODE1_CONTAINER_NAME    | Default set to `racnodep1`. Set this env variable when you want to specify the container name for the first Oracle RAC container. |
| RACNODE1_HOST_NAME         | Default set to `racnodep1`. Set this env variable when you want to specify host name for the first RAC container. |
| RACNODE1_PUBLIC_IP         | Default set to `10.0.20.170`. Set this env variable when you want to set the public IP for the first Oracle RAC container. |
| RACNODE1_CRS_PRIVATE_IP1   | Default set to `192.168.17.170`. Set this env variable when you want to set the private IP for the first private network of the first Oracle RAC container. |
| RACNODE1_CRS_PRIVATE_IP2   | Default set to `192.168.18.170`. Set this env variable when you want to set the private IP for the second private network of the first Oracle RAC container. |
| INSTALL_NODE               | Default set to `racnodep1`. Set this env variable to any of the RAC containers. Note: This value will remain the same across the Oracle RAC Cluster for both nodes where the actual Oracle RAC cluster installation occurs. |
| RAC_IMAGE_NAME             | Default set to `localhost/oracle/database-rac:21.0.0`. Set this env variable when you want to specify the Oracle RAC Image name. |
| CRS_NODES                  | Default set to `"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip"`. Set this env variable to a value with the same format used here for all the Oracle RAC cluster node cluster setup. |
| SCAN_NAME                  | Default set to `racnodepc1-scan`. Set this env variable when you want to specify a resolvable scan name from the DNS. |
| CRS_ASM_DISCOVERY_STRING   | With NFS storage devices the default is set to `/oradata`. With block devices, the default is set to `/dev/asm-disk*`. This value specifies the discovery string for ASM. Do not change this unless you have modified `podman-compose.yml` to find a different discovery string. |
| CRS_ASM_DEVICE_LIST        | Default set to `/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img` This device list is used with NFS Storage Devices. Do not change this value. |
| ASM_DISK1                  | Default set to `/dev/oracleoci/oraclevdd`. Set this env variable for block device setup when you want to specify the first ASM disk. |
| ASM_DISK2                  | Default set to `/dev/oracleoci/oraclevde`. Set this env variable for block device setup when you want to specify the second ASM disk. |
| RACNODE2_CONTAINER_NAME    | Default set to `racnodep2`. Set this env variable when you want to set the container name for the second Oracle RAC container. |
| RACNODE2_HOST_NAME         | Default set to `racnodep2`. Set this env variable when you want to set the host name for the second Oracle RAC container. |
| RACNODE2_PUBLIC_IP         | Default set to `10.0.20.171`. Set this env variable when you want to set the public IP for tje second Oracle RAC container. |
| RACNODE2_CRS_PRIVATE_IP1   | Default set to `192.168.17.171`. Set this env variable when you want to set the first private IP for the second Oracle RAC container. |
| RACNODE2_CRS_PRIVATE_IP2   | Default set to 192.168.18.171. Set this env variable when you want to set the second private IP for the second Oracle RAC container. |
| PWD_SECRET_FILE            | Default set to `/opt/.secrets/pwdfile.enc`. Do not change this value. |
| KEY_SECRET_FILE            | Default set to `/opt/.secrets/key.pem`. Do not change this value. |
| CMAN_CONTAINER_NAME        | Default set to `racnodepc1-cman`. Set this env variable when you want to set a connection manager container name. |
| CMAN_HOST_NAME             | Default set to `racnodepc1-cman`. Set this env variable when you want to set the hostname for the connection manager container. |
| CMAN_IMAGE_NAME            | Default set to `"localhost/oracle/client-cman:21.0.0"`. Set this env variable when you want to set the connection manager image name. |
| CMAN_PUBLIC_IP             | Default set to 10.0.20.15. Set this env variable when you want to set public ip for connection manager container. |
| CMAN_PUBLIC_HOSTNAME       | Default set to `racnodepc1-cman`. Set this env variable when you want to set the public hostname for the connection manager container. |
| DB_HOSTDETAILS             | Default set to `HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170`. Set this env variable when you want to use connection manager container to set details for the database host. |
| STORAGE_CONTAINER_NAME     | Default set to `racnode-storage`. Set this env variable when you want to set the container name of the storage container. |
| STORAGE_HOST_NAME          | Default set to `racnode-storage`. Set this env variable when you want to set the host name for the storage container. |
| STORAGE_IMAGE_NAME         | Default set to `"localhost/oracle/rac-storage-server:latest"`. Set this env variable when you want to set the storage image name. |
| ORACLE_DBNAME              | Default set to `ORCLCDB`. Set this env variable when you want to set the Oracle RAC database name. |
| STORAGE_PRIVATE_IP         | Default set to `192.168.17.80`. Set this env variable when you want to set the private IP for the storage container. |
| NFS_STORAGE_VOLUME         | Default set to `/scratch/stage/rac-storage/$ORACLE_DBNAME`. Set this env variable when you want to specify the path used by the NFS storage container. The path location must contain at least 50 GB of space. |
| DB_SERVICE                 | Default set to `service:soepdb`. Set this env variable when you want to specify the database service you are creating, using the format of <_service_:_nameofservice_>. |
| EXISTING_CLS_NODE          | Default set to `"racnodep1,racnodep2"` This environment variable is used only during node addition. |

## License

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
