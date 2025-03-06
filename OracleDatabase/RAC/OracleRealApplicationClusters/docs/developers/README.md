# Oracle Real Application Clusters in Linux Containers for Developers

Learn about container deployment options for Oracle Real Application Clusters (Oracle RAC) Release 21c (v21.3 or later)

## Overview of Running Oracle RAC in Containers

Oracle Real Application Clusters (Oracle RAC) is an option for the award-winning Oracle Database Enterprise Edition. Oracle RAC is a cluster database with a shared cache architecture that overcomes the limitations of traditional shared-nothing and shared-disk approaches to provide highly scalable and available database solutions for all business applications.
Oracle RAC uses Oracle Clusterware as a portable cluster software that allows clustering of independent servers so that they cooperate as a single system and Oracle Automatic Storage Management (Oracle ASM) to provide simplified storage management that is consistent across all servers and storage platforms.
Oracle Clusterware and Oracle ASM are part of the Oracle Grid Infrastructure, which bundles both solutions in an easy-to-deploy software package. For more information on Oracle RAC Database 21c refer to the [Oracle Database documentation](http://docs.oracle.com/en/database/).

This guide helps you install Oracle RAC on Containers on Host Machines as explained in detail below. With the current release, you prepare the host machine, build or use pre-built Oracle RAC Container Images v21.0, and setup Oracle RAC on Single or Multiple Host machines with Oracle ASM.
In this installation guide, we use [Podman](https://docs.podman.io/en/v3.0/) to create Oracle RAC Containers and manage them.

## Using this Documentation
To create an Oracle RAC environment, follow these steps:

- [Oracle Real Application Clusters in Linux Containers for Developers](#oracle-real-application-clusters-in-linux-containers-for-developers)
  - [Overview of Running Oracle RAC in Containers](#overview-of-running-oracle-rac-in-containers)
  - [Using this Documentation](#using-this-documentation)
  - [Before you begin](#before-you-begin)
  - [QuickStart](#quickstart)
  - [Getting Oracle RAC Database Container Images](#getting-oracle-rac-database-container-images)
  - [Networking in Oracle RAC Podman Container Environment](#networking-in-oracle-rac-podman-container-environment)
  - [Deploy Oracle RAC 2 Node Environment with NFS Storage Container](#deploy-oracle-rac-2-node-environment-with-nfs-storage-container)
  - [Deploy Oracle RAC 2 Node Environment with BlockDevices](#deploy-oracle-rac-2-node-environment-with-blockdevices)
  - [Validating Oracle RAC Environment](#validating-oracle-rac-environment)
  - [Connecting to an Oracle RAC Database](#connecting-to-an-oracle-rac-database)
  - [Environment Variables Explained for above 2 Node RAC on Podman Compose](#environment-variables-explained-for-above-2-node-rac-on-podman-compose)
  - [Cleanup](#cleanup)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Before you begin
- Before proceeding further, the below prerequisites related to the Oracle RAC (Real Application Cluster) Podman host Environment need to be setup as a preparation steps for the Podman host machine for Oracle RAC Containers. For more details related to the preparation of the host machine, refer to [Preparation Steps for running Oracle RAC Database in containers](../../README.md#preparation-steps-for-running-oracle-rac-database-in-containers).
We have pre-created script `setup_rac_host.sh` which will prepare the podman host with the following pre-requisites-
  - Validate Host machine for supported Os version(OL >8.5 or later), Kernel(>UEKR7), Memory(>32GB), Swap(>32GB), shm(>4GB) etc.
  - Update /etc/sysctl.conf
  - Setup node directories for Slim Image
  - Setup chronyd service
  - Setup tsc clock (if available).
  - Install Podman
  - Install Podman Compose
  - Setup and Load SELinux modules
  - Create Oracle RAC Podman secrets  

**Note :**  All below steps or commands in this QuickStart needs to be run as a `sudo` or `root` user.
* In this quickstart, our working directory is `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/containerfiles` from where all commands are executed.
* Set `secret-password` of your choice below, which is going to be used as a password for the Oracle RAC Container environment.
  Execute below command-
  ```bash
  export RAC_SECRET=<secret-password>
  ```

- To prepare podman host machine using a pre-created script, copy the file `setup_rac_host.sh` from [<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/
OracleRealApplicationClusters/containerfiles/setup_rac_host.sh](../../containerfiles/setup_rac_host.sh) and execute below -
  ```bash
  ./setup_rac_host.sh -prepare-rac-env
  ```
  Logs-
  ```bash
  INFO: Finished setting up the pre-requisites for Podman-Host
  ```

## Getting Oracle RAC Database Container Images

Oracle RAC is supported for production use on Podman starting with Oracle Database 19c (19.16), and Oracle Database 21c (21.7). You can also deploy Oracle RAC on Podman using the pre-built images available on the Oracle Container Registry.
Refer [this documentation](https://docs.oracle.com/en/operating-systems/oracle-linux/docker/docker-UsingDockerRegistries.html#docker-registry) for details on using Oracle Container Registry and [Getting Oracle RAC Database Container Images](../../README.md#getting-oracle-rac-database-container-images)

Example of pulling an Oracle RAC Image from the Oracle Container Registry:
```bash
# For Oracle RAC Container Image-
podman pull container-registry.oracle.com/database/rac_ru:latest
podman tag container-registry.oracle.com/database/rac_ru:latest localhost/oracle/database-rac:21c
```

**Notes**
- Use the Oracle `DNSServer` Image to deploy a container providing DNS resolutions. Refer [OracleDNSServer](../../../OracleDNSServer/README.md)
- `OracleRACStorageServer` container image can be used for deploy Oracle RAC with NFS Storage. Refer [OracleRACStorageServer](../../../OracleRACStorageServer/README.md) for details.
- If the Podman bridge network is not available outside your host, you can use the Oracle Connection Manager [CMAN image](../../../OracleConnectionManager/README.md) to access the Oracle RAC Database from outside the host.

- When Podman Images are ready like the below example used in this quickstart developer guide, you can proceed to the next steps-
  ```bash
  podman images
  localhost/oracle/client-cman                    21.3.0      7b095637d7b6  About a minute ago  2.08 GB
  localhost/oracle/database-rac                   21c         dcda5cf71b23  12 hours ago        9.33 GB
  localhost/oracle/rac-storage-server             latest      d233b08a8aed  12 hours ago        443 MB
  localhost/oracle/rac-dnsserver                  latest      7d2301d7ea53  13 hours ago        279 MB
  ```


## QuickStart
To become familiar with Oracle RAC on Containers, Oracle recommends that you first start with this QuickStart.

After you become familiar with Oracle RAC on Containers, you can explore more advanced setups, deployments, features, and so on, as explained in detail in the [Oracle Real Application Clusters](../../../OracleRealApplicationClusters/README.md)

* To resolve VIPs and SCAN IPs, in this guide we use a DNS container. Before proceeding to the next step, create a [DNS server container](../OracleDNSServer/README.md).
If you have a preconfigured DNS server in your environment, then you can replace `-e DNS_SERVERS=10.0.20.25`, `--dns=10.0.20.25`, `-e DOMAIN=example.info`  and `--dns-search=example.info` parameters in the examples in this guide with the `DOMAIN_NAME` and `DNS_SERVER` based on your environment.

## Networking in Oracle RAC Podman Container Environment
- In this Quick Start, we will create below subnets for Oracle RAC Podman Container Environment-

  | Network Name   | Subnet CIDR         | Description                          |
  |----------------|--------------|--------------------------------------|
  | rac_pub1_nw    | 10.0.20.0/24 | Public network for Oracle RAC Podman Container Environment                      |
  | rac_priv1_nw   | 192.168.17.0/24 | First private network for Oracle RAC Podman Container Environment                |
  | rac_priv2_nw   | 192.168.18.0/24 | Second private network for Oracle RAC Podman Container Environment               |

## Deploy Oracle RAC 2 Node Environment with NFS Storage Container
- Copy `podman-compose.yml` file from this [<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/
OracleRealApplicationClusters/samples/rac-compose/racimage/withoutresponsefiles/nfsdevices/podman-compose.yml](../../samples/rac-compose/racimage/withoutresponsefiles/nfsdevices/podman-compose.yml) in your working directory.
- Execute the below command from your working directory to export the required environment variables required by the compose file in this quickstart-
  ```bash
  source ./setup_rac_host.sh -nfs-env
  ```
  Logs -
  ```bash
  INFO: NFS Environment variables setup completed successfully.
  ```
  Note: In this example, `DB_SERVICE` is set to <service:soepdb> as default as an example. If you want to change to a different name, set like below -
  ```bash
  export DB_SERVICE=service:<service-name>
  ```

  Note:
  - In this example, we have used the below path for NFS Storage Volume. This path must have a minimum 100GB of free space. If you want to change it, export by changing it as per your environment before proceeding further -
    ```bash
    export ORACLE_DBNAME=ORCLCDB
    export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
    ```
  - If SELinux host is enabled on the machine then execute the following-
    ```bash
    semanage fcontext -a -t container_file_t /scratch/stage/rac-storage/$ORACLE_DBNAME
    restorecon -v /scratch/stage/rac-storage/$ORACLE_DBNAME
    ```
- Execute below to create Podman Networks specific to RAC in this quickstart-
  ```bash
  ./setup_rac_host.sh -networks
  ```
  Logs -
  ```bash
  INFO: Oracle RAC Container Networks setup successfully
  ```
- Execute below to deploy DNS Containers-
  ```bash
  ./setup_rac_host.sh -dns
  ```
  Logs -
  ```bash
  ##########################################
  INFO: DNS Container is setup successfully.
  ##########################################
  ```
- Execute below to deploy Storage Containers-
  
  ```bash
  ./setup_rac_host.sh -storage
  ```
  Logs-
  ```bash
  ############################################################
  INFO: NFS Storage Container exporting /oradata successfully.
  ############################################################
  racstorage
  ```
- Execute below to deploy Oracle RAC Containers-
  ```bash
  ./setup_rac_host.sh -rac
  ```
  Logs-
  ```bash
  ###############################################
  INFO: Oracle RAC Containers setup successfully.
  ###############################################
  ```
- Optional: If the Podman bridge network is not available outside your host, you can use the Oracle Connection Manager to access the Oracle RAC Database from outside the host. Execute below if you want to deploy CMAN Container as well-
  ```bash
  ./setup_rac_host.sh -cman
  ```
  Logs-
  ```bash
  ###########################################
  INFO: CMAN Container is setup successfully.
  ###########################################
  ```
- If you want to cleanup the RAC Container environment, then execute below-
  ```bash
  ./setup_rac_host.sh -cleanup
  ```
  This will cleanup Oracle RAC Containers, Oracle Storage Volume,  Oracle RAC Podman Networks, etc.

  Logs-
  ```bash
  INFO: Oracle Container RAC Environment Cleanup Successfully
  ```

## Deploy Oracle RAC 2 Node Environment with BlockDevices

- Copy `podman-compose.yml` file from [<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/RAC/
OracleRealApplicationClusters/samples/rac-compose/racimage/withoutresponsefiles/blockdevices/podman-compose.yml](../../samples/rac-compose/racimage/withoutresponsefiles/blockdevices/podman-compose.yml) in your working directory.
- Execute the below command to export the required environment variables required by the compose file in this quickstart-
  ```bash
  source ./setup_rac_host.sh -blockdevices-env
  ```
  Logs-
  ```bash
  INFO: BlockDevices Environment variables setup completed successfully.
  ```
  Note: In this example, DB_SERVICE is set to service:soepdb. If you want to change to a different name, set it like `export DB_SERVICE=service:<service-name>`

  Note: In this example, we have used the below asm disks. If you want to change it, export by changing it as per your environment before proceeding further -
  ```bash
  export ASM_DISK1="/dev/oracleoci/oraclevdd"
  export ASM_DISK2="/dev/oracleoci/oraclevde"
  ```
- Execute below to create Podman Networks specific to RAC in this quickstart-
  ```bash
  ./setup_rac_host.sh -networks
  ```
  Logs-
  ```bash
  INFO: Oracle RAC Container Networks setup successfully
  ```

- Execute below to deploy DNS Containers-
  ```bash
  ./setup_rac_host.sh -dns
  ```
  Logs-
  ```bash
  ##########################################
  INFO: DNS Container is setup successfully.
  ##########################################
  ```
- Execute below to deploy Oracle RAC Containers-
  ```bash
  ./setup_rac_host.sh -rac
  ```
  Logs-
  ```bash
  ###############################################
  INFO: Oracle RAC Containers setup successfully.
  ###############################################
  ```
- Optional: If the Podman bridge network is not available outside your host, you can use the Oracle Connection Manager to access the Oracle RAC Database from outside the host. Execute below if you want to deploy CMAN Container as well-
  ```bash
  ./setup_rac_host.sh -cman
  ```
  Logs-
  ```bash
  ###########################################
  INFO: CMAN Container is setup successfully.
  ###########################################
  ```
- If you want to Cleanup the RAC Container environment , then execute the below-
  ```bash
  ./setup_rac_host.sh -cleanup
  ```
  This will cleanup Oracle RAC Containers, Oracle RAC Podman Networks, etc.
  Logs-
  ```bash
  INFO: Oracle Container RAC Environment Cleanup Successfully
  ```

## Validating Oracle RAC Environment
You can validate if the environment is healthy by running the below command-
```bash
podman ps -a

58642afb20eb  localhost/oracle/rac-dnsserver:latest       /bin/sh -c exec $...  23 hours ago  Up 23 hours (healthy)           rac-dnsserver
a192f4e9092a  localhost/oracle/database-rac:21c                              10 hours ago  Up 10 hours (healthy)              racnodep1
745679457df5  localhost/oracle/database-rac:21c                              10 hours ago  Up 10 hours (healthy)              racnodep2
```
Note:
- Look for `(healthy)` next to container names under the `STATUS` section.

## Environment Variables Explained for above 2 Node RAC on Podman Compose
Refer to [Environment Variables Explained for Oracle RAC on Podman Compose](./ENVVARIABLESCOMPOSE.md) for the explanation of all the environment variables related to Oracle RAC on Podman Compose. Change or Set these environment variables as per your environment.

## Connecting to an Oracle RAC Database

**IMPORTANT:** This section assumes that you have successfully created an Oracle RAC cluster using the preceding sections.  
Refer to the [README](../CONNECTING.md) for instructions on how to connect to the Oracle RAC Database.

## Cleanup
Refer to [README](../CLEANUP.md) for instructions on how to cleanup an Oracle RAC Database Container Environment.

## Support

At the time of this release, Oracle RAC on Podman is supported for Oracle Linux 8.10 later. To see current Linux support certifications, refer [Oracle RAC on Podman Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/install-and-upgrade.html)

## License

To download and run Oracle Grid and Database, regardless of whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under a UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.