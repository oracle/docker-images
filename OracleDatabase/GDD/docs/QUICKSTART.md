# Oracle Globally Distributed Database Container QuickStart Guide

Use this quickstart to help you deploy Oracle Globally Distributed Database with the RAFT Replication feature enabled using Podman Containers on a single Oracle Linux Host machine using Podman Compose.

This deployment uses Oracle Globally Distributed Database Container Image and bridge network driver for Podman.

- [Oracle Globally Distributed Database Container QuickStart Guide](#oracle-globally-distributed-database-container-quickstart-guide)
  - [Before you begin](#before-you-begin)
  - [Getting Oracle Globally Distributed Database Container Images](#getting-oracle-globally-distributed-database-container-images)
  - [Networking in Oracle Globally Distributed Database Podman Container Environment](#networking-in-oracle-globally-distributed-database-podman-container-environment)
  - [Deploy Oracle Globally Distributed Database Environment](#deploy-oracle-globally-distributed-database-on-podman-container-environment)
  - [Validating Oracle Globally Distributed Database Environment](#validating-oracle-globally-distributed-database-container-environment)
  - [Cleanup the environment](#clean-up-the-environment)
  - [Environment Variables Explained](#environment-variables-explained)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## Before you begin

- Before proceeding further, prepare the Podman host by completing prerequisites related to the Oracle Globally Distributed Database Containers on Podman host environment as explained in [Preparation Steps for running Oracle Globally Distributed Database Database in containers](../README.md#preparation-steps-for-running-oracle-globally-distributed-database-in-linux-containers). Oracle provides a precreated script, `setup_gdd_host.sh`, which will prepare the Podman host with the following prerequisites-
  - Validate Host machine for supported OS version(OL >8), Kernel(>UEKR6), Memory(>32GB), etc.
  - Install Podman
  - Install Podman Compose
  - Setup and Load SELinux modules
  - Create Oracle Globally Distributed Database Podman secrets
- Set `secret-password` of your choice below, which is going to be used as a password for the Oracle Globally Distributed Database Container environment.

  Run the following command-

  ```bash
  export SHARDING_SECRET=<secret-password>
  ```

- To prepare the Podman host machine using a precreated script, copy the file `setup_gdd_host.sh` from [<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/GDD/containerfiles/setup_gdd_host.sh](../containerfiles/setup_gdd_host.sh) and run the following command -

  ```bash
  ./setup_gdd_host.sh -prepare-sharding-env
  ```
  
  Logs-
  
  ```bash
  INFO: Finished setting up the pre-requisites for Podman-Host
  ```

- In this quickstart, our working directory is `<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/GDD/containerfiles` from where all commands are run.

## Getting Oracle Globally Distributed Database Container Images

- Refer to the [Getting Oracle Globally Distributed Database Container Images](../README.md#building-oracle-globally-distributed-database-container-images) section to get Oracle Globally Distributed Database Container Images used in quickstart setup.  
- We are going to use the Oracle AI Database 26ai images in this deployment:

  ```bash
  container-registry.oracle.com/database/enterprise:latest
  container-registry.oracle.com/database/gsm:latest
  ```

## Networking in Oracle Globally Distributed Database Podman Container Environment

- In this Quick Start, we will create the following subnets for Oracle Globally Distributed Database Podman Container Environment-  

  | Network Name   | Subnet CIDR         | Description                                                                        |
  |----------------|---------------------|------------------------------------------------------------------------------------|
  | shard_pub1_nw  | 10.0.20.0/20        | Public network for Oracle lobally Distributed Database Podman Container Environment|

## Deploy Oracle Globally Distributed Database on Podman Container Environment

- Copy the `podman-compose.yml` file from this [<GITHUB_REPO_CLONED_PATH>/docker-images/OracleDatabase/GDD/samples/compose-files/podman-compose/podman-compose.yml](../samples/compose-files/podman-compose/podman-compose.yml) in your working directory.
- Run the following command from your working directory to export the required environment variables required by the compose file in this quickstart-

  ```bash
  source ./setup_gdd_host.sh -export-sharding-env
  ```

  Logs -
  
  ```bash
  INFO: Sharding Environment Variables are setup successfully.
  ```

  Note: This Quickstart guide uses the variable `export PODMANVOLLOC='/scratch/oradata'` for storing all data files related to Oracle Globally Distributed Database containers. You can change this as needed in your environment where required free space is available.

- Run the following command to deploy the Catalog Container-

  ```bash
  ./setup_gdd_host.sh -deploy-catalog
  ```

  Monitor Logs -

  ```bash
  # podman-compose logs -f catalog_db
  ```

  Wait for the following message:

  ```txt
  ==============================================
     GSM Catalog Setup Completed              
  ==============================================
  ```

- Execute below to deploy the Shard1 Container-

  ```bash
  ./setup_gdd_host.sh -deploy-shard1
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f shard1_db
  ```
  
  Wait for the following message:

  ```txt
  ==============================================
     GSM Shard Setup Completed                
  ==============================================
  ```

- Run the following command to deploy the Shard2 Container-

  ```bash
  ./setup_gdd_host.sh -deploy-shard2
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f shard2_db
  ```

  Wait for the following message:

  ```txt
  ==============================================
     GSM Shard Setup Completed                
  ==============================================
  ```

- Run the following command to deploy the Shard3 Container-

  ```bash
  ./setup_gdd_host.sh -deploy-shard3
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f shard3_db
  ```

  Wait for the following message:

  ```txt
  ==============================================
     GSM Shard Setup Completed                
  ==============================================
  ```

- Run the following command to deploy the Shard4 Container-

  ```bash
  ./setup_gdd_host.sh -deploy-shard4
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f shard4_db
  ```

  Wait for the following message:

  ```txt
  ==============================================
     GSM Shard Setup Completed                
  ==============================================
  ```

- Run the following commanda to deploy the Primary GSM Container-

  ```bash
  ./setup_gdd_host.sh -deploy-gsm-primary
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f primary_gsm
  ```
  
  Wait for the following message:

  ```txt
  ==============================================
  GSM Setup Completed
  ==============================================
  ```

- Run the following command to deploy Standby GSM Container-

  ```bash
  ./setup_gdd_host.sh -deploy-gsm-standby
  ```

  Monitor Logs -

  ```bash
  podman-compose logs -f standby_gsm
  ```

  Wait for the following message:

  ```txt
  ==============================================
  GSM Setup Completed
  ==============================================
  ```

## Validating Oracle Globally Distributed Database Container Environment

You can validate if the environment is set up correctly by running the following command and checking the logs of each container-

```bash
# podman ps -a
CONTAINER ID  IMAGE                                                      COMMAND               CREATED         STATUS         PORTS       NAMES
181a4215b517  container-registry.oracle.com/database/enterprise:latest   /bin/sh -c exec $...  22 minutes ago  Up 22 minutes              catalog
2b5ade918112  container-registry.oracle.com/database/enterprise:latest   /bin/sh -c exec $...  18 minutes ago  Up 18 minutes              shard1
f4943c6d67ce  container-registry.oracle.com/database/enterprise:latest   /bin/sh -c exec $...  15 minutes ago  Up 15 minutes              shard2
fa9611ad2bbe  container-registry.oracle.com/database/enterprise:latest   /bin/sh -c exec $...  11 minutes ago  Up 11 minutes              shard3
e19138866b51  container-registry.oracle.com/database/enterprise:latest   /bin/sh -c exec $...  7 minutes ago   Up 7 minutes               shard4
e88e57c4e442  container-registry.oracle.com/database/gsm:latest          /bin/sh -c exec $...  3 minutes ago   Up 3 minutes               gsm1
4e751cdfe01e  container-registry.oracle.com/database/gsm:latest          /bin/sh -c exec $...  24 seconds ago  Up 24 seconds              gsm2
```

## Clean up the environment

If you want to clean up the Oracle Globally Distributed Database Container environment, then run the following command-

```bash
./setup_gdd_host.sh -cleanup
```

This command will clean up the Oracle Globally Distributed Database Containers, Oracle Storage Volume, Oracle Globally Distributed Database Podman Networks, and so on.

Logs-

```bash
INFO: Oracle Globally Distributed Database Container Environment Cleanup Successfully
```

## Environment Variables Explained

Refer to [Environment Variables Details for Oracle Globally Distributed Database using Podman Compose](./ENVVARIABLESCOMPOSE.md) for the explanation of all the environment variables related to Oracle Globally Distributed Database using Podman Compose. Change or Set these environment variables as required for your environment.

## Support

Oracle Globally Distributed Database on Docker is supported on Oracle Linux 7.
Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and onwards.

## License

To run Oracle Globally Distributed Database, regardless of whether it is inside or outside a Container, ensure that you download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
