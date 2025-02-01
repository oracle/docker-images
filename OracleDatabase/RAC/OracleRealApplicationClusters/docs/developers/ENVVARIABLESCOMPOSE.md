# Environment Variables Explained for Oracle RAC on Podman Compose

This section provides information about the environment variables that can be used when creating 2 Node RAC cluster.

| Variable Name              | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| DNS_PUBLIC_IP              | Default set to 10.0.20.25. Set this env variable when you want to set DNS container public ip address where both Oracle RAC nodes are resolved. |
| DNS_CONTAINER_NAME         | Default set to rac-dnsserver. Set this env variable when you want to set name for dns container. |
| DNS_HOST_NAME              | Default set to racdns. Set this env variable when you want to set dns container host name. |
| DNS_IMAGE_NAME             | Default set to "localhost/oracle/rac-dnsserver:latest". Set this env variable when you want to set dns image name. |
| RAC_NODE_NAME_PREFIXP      | Default set to racnodep. Set this env variable when you want to set different prefix being used for DNS podman container resolutions. |
| DNS_DOMAIN                 | Default set to example.info. Set this env variable when you want to set dns domain. |
| PUBLIC_NETWORK_NAME        | Default set to rac_pub1_nw. Set this env variable when you want to set public podman network name for RAC. |
| PUBLIC_NETWORK_SUBNET      | Default set to 10.0.20.0/24. Set this env variable when you want to set public network subnet. |
| PRIVATE1_NETWORK_NAME      | Default set to rac_priv1_nw. Set this env variable when you want to specify first private network name. |
| PRIVATE1_NETWORK_SUBNET    | Default set to 192.168.17.0/24. Set this env variable when you want to set first private network subnet. |
| PRIVATE2_NETWORK_NAME      | Default set to rac_priv2_nw. Set this env variable when you want to set second private network name. |
| PRIVATE2_NETWORK_SUBNET    | Default set to 192.168.18.0/24. Set this env variable when you want to set second private network subnet. |
| RACNODE1_CONTAINER_NAME    | Default set to racnodep1. Set this env variable when you want to set container name for first RAC container. |
| RACNODE1_HOST_NAME         | Default set to racnodep1. Set this env variable when you want to set host name for first RAC container. |
| RACNODE1_PUBLIC_IP         | Default set to 10.0.20.170. Set this env variable when you want to set public ip first RAC container. |
| RACNODE1_CRS_PRIVATE_IP1   | Default set to 192.168.17.170. Set this env variable when you want to set private ip for the first private network for first RAC container. |
| RACNODE1_CRS_PRIVATE_IP2   | Default set to 192.168.18.170. Set this env variable when you want to set private ip for the second private network for first RAC container. |
| INSTALL_NODE               | Default set to racnodep1. Set this env variable to any of RAC container, but this will remain same across the RAC Cluster for both nodes where actual RAC cluster installation will happen. |
| RAC_IMAGE_NAME             | Default set to localhost/oracle/database-rac:21.0.0. Set this env variable when you want to specify RAC Image name. |
| CRS_NODES                  | Default set to "pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip". Set this env variable to value in format as used here for all the nodes part of RAC Cluster Setup. |
| SCAN_NAME                  | Default set to racnodepc1-scan. Set this env variable when you want to specify resolvable scan name from DNS. |
| CRS_ASM_DISCOVERY_STRING   | Default set to /oradata with NFS Storage devices. Default set to /dev/asm-disk* for BlockDevices. This specifies the discovery string for ASM. Do not change this unless you have modified podman-compose.yml to find different discovery string. |
| CRS_ASM_DEVICE_LIST        | Default set to /oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img and is used with NFS Storage Devices. Do not change this. |
| ASM_DISK1                  | Default set to /dev/oracleoci/oraclevdd. Set this env variable when you want to specify first asm disk in block devices setup. |
| ASM_DISK2                  | Default set to /dev/oracleoci/oraclevde. Set this env variable when you want to specify second asm disk in block devices setup. |
| RACNODE2_CONTAINER_NAME    | Default set to racnodep2. Set this env variable when you want to set container name for second RAC container. |
| RACNODE2_HOST_NAME         | Default set to racnodep2. Set this env variable when you want to set host name for second RAC container. |
| RACNODE2_PUBLIC_IP         | Default set to 10.0.20.171. Set this env variable when you want to set public ip for second RAC container. |
| RACNODE2_CRS_PRIVATE_IP1   | Default set to 192.168.17.171. Set this env variable when you want to set first private ip for second RAC container. |
| RACNODE2_CRS_PRIVATE_IP2   | Default set to 192.168.18.171. Set this env variable when you want to set second private ip for second RAC container. |
| PWD_SECRET_FILE            | Default set to /opt/.secrets/pwdfile.enc. Do not change this. |
| KEY_SECRET_FILE            | Default set to /opt/.secrets/key.pem. Do not change this. |
| CMAN_CONTAINER_NAME        | Default set to racnodepc1-cman. Set this env variable when you want to set connection manager container name. |
| CMAN_HOST_NAME             | Default set to racnodepc1-cman. Set this env variable when you want to set hostname for connection manager container. |
| CMAN_IMAGE_NAME            | Default set to "localhost/oracle/client-cman:21.0.0". Set this env variable when you want to set connection manager image name. |
| CMAN_PUBLIC_IP             | Default set to 10.0.20.15. Set this env variable when you want to set public ip for connection manager container. |
| CMAN_PUBLIC_HOSTNAME       | Default set to racnodepc1-cman. Set this env variable when you want to set public hostname for connection manager container. |
| DB_HOSTDETAILS             | Default set to HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170. Set this env variable when you want to set details for DB host to be set up with connection manager container. |
| STORAGE_CONTAINER_NAME     | Default set to racnode-storage. Set this env variable when you want to set container name storage container. |
| STORAGE_HOST_NAME          | Default set to racnode-storage. Set this env variable when you want to set hostname for storage container. |
| STORAGE_IMAGE_NAME         | Default set to "localhost/oracle/rac-storage-server:latest". Set this env variable when you want to set storage image name. |
| ORACLE_DBNAME              | Default set to ORCLCDB. Set this env variable when you want to set RAC DB Name. |
| STORAGE_PRIVATE_IP         | Default set to 192.168.17.80. Set this env variable when you want to set private ip for storage container. |
| NFS_STORAGE_VOLUME         | Default set to /scratch/stage/rac-storage/$ORACLE_DBNAME. Set this env variable when you want to specify path used by NFS storage container. Must be at least 50 GB of space. |
| DB_SERVICE                 | Default set to service:soepdb. Set this env variable when you want to specify database service to be created in this format of <service:nameofservice>. |
| EXISTING_CLS_NODE          | Default set to "racnodep1,racnodep2" and used only during node addition. |

## License

All scripts and files hosted in this repository which are required to build the container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates.