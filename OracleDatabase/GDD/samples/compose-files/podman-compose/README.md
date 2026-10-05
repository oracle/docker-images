# Deploy Oracle Globally Distributed Database Using podman-compose

For host machines running Oracle Linux 8 or later, `podman-compose` can be used to deploy containers for Oracle Globally Distributed Database.

For example, you can use Oracle AI Database 26ai RDBMS and GSM Podman images and deploy using the sharding option of your choice: `System-Managed Sharding`, `User-Defined Sharding`, or `System-Managed Sharding with Raft replication`.

This example demonstrates how to use `podman-compose` to create the Podman network and to deploy containers for an Oracle Globally Distributed Database on a single Oracle Linux 8 host.

This example deploys an Oracle Globally Distributed Database with `System-Managed Sharding` using four shard containers, one catalog container, one primary GSM container, and one standby GSM container.

**Important:** This example uses Oracle AI Database 26ai and GSM Podman images to deploy Oracle Globally Distributed Database.

- [Deploy Oracle Globally Distributed Database Using podman-compose](#deploy-oracle-globally-distributed-database-using-podman-compose)
  - [Install podman-compose](#install-podman-compose)
  - [Complete the prerequisite steps](#complete-the-prerequisite-steps)
    - [Create Podman Secrets](#create-podman-secrets)
    - [Run the Prerequisites Script](#run-the-prerequisites-script)
  - [Configure SELinux on the Podman Host](#configure-selinux-on-the-podman-host)
  - [Prepare the podman-compose File](#prepare-the-podman-compose-file)
  - [Deploy Using podman-compose](#deploy-using-podman-compose)
  - [Check the Logs](#check-the-logs)
    - [Catalog Container](#catalog-container)
    - [Shard Containers](#shard-containers)
    - [Primary GSM Container](#primary-gsm-container)
    - [Standby GSM Container](#standby-gsm-container)
  - [Workload Test](#workload-test)
  - [Remove the deployment](#remove-the-deployment)
  - [Deploy with Oracle AI Database 26ai Free](#deploy-with-oracle-ai-database-26ai-free)
  - [Copyright](#copyright)

## Install podman-compose

```bash
dnf config-manager --enable ol8_developer_EPEL
dnf install podman-compose
```

## Complete the prerequisite steps

Complete each of these steps before proceeding with deployment.

### Create Podman Secrets

Complete the procedure to create Podman secrets from [Password Management](../../container-files/podman-container-files/README.md#password-management). These Podman secrets are also used during the deployment of Oracle Globally Distributed Database Containers.

### Run the Prerequisites Script

Run the script file [podman-compose-prerequisites.sh](./podman-compose-prerequisites.sh). This script exports the environment variables, creates the network host file, and creates required directories.

**NOTE:** You must change the values for `SIDB_IMAGE` and `GSM_IMAGE` to use the images that you want to use for the deployment.

```bash
source podman-compose-prerequisites.sh
```

## Configure SELinux on the Podman Host

If SELinux is enabled on the Podman host, load the required `shard-podman` policy as described in [SELinux Configuration on Podman Host](../../container-files/podman-container-files/README.md#selinux-configuration-on-podman-host).

To set the required SELinux contexts for files and directories, run the following script:

[set-file-context.sh](./set-file-context.sh)

```bash
source set-file-context.sh
```

## Prepare the podman-compose File

Copy [podman-compose.yml](podman-compose.yml) to your working directory. In this example, the working directory is [<github_cloned_path>/db-sharding/container-based-sharding-deployment/containerfiles]

## Deploy Using podman-compose

After completing all prerequisites, run the following command to deploy the services:

```bash
# Ensure that podman-compose.yml is present in your working directory.
 
podman-compose up -d
```

Wait for all services to start and become ready:

```bash
$ podman ps -a
CONTAINER ID  IMAGE                                                        COMMAND               CREATED        STATUS        PORTS       NAMES
e38e54c25423  container-registry.oracle.com/database/enterprise_ru:latest  /bin/sh -c exec $...  9 minutes ago  Up 9 minutes              catalog
68f1a21527a9  container-registry.oracle.com/database/enterprise_ru:latest  /bin/sh -c exec $...  9 minutes ago  Up 9 minutes              shard1
a67d07e9d2ca  container-registry.oracle.com/database/enterprise_ru:latest  /bin/sh -c exec $...  9 minutes ago  Up 9 minutes              shard2
b39a9b55b8bf  container-registry.oracle.com/database/enterprise_ru:latest  /bin/sh -c exec $...  9 minutes ago  Up 9 minutes              shard3
c7123d79927f  container-registry.oracle.com/database/enterprise_ru:latest  /bin/sh -c exec $...  9 minutes ago  Up 9 minutes              shard4
7dcd5113348e  container-registry.oracle.com/database/gsm_ru:latest         /bin/sh -c exec $...  9 minutes ago  Up 9 minutes  1522/tcp    gsm1
6db31380bdca  container-registry.oracle.com/database/gsm_ru:latest         /bin/sh -c exec $...  9 minutes ago  Up 9 minutes  1522/tcp    gsm2
```

## Check the Logs

Verify that each container completes its setup successfully.

### Catalog Container

Monitor the Oracle database setup:

```bash
podman logs -f catalog
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
#########################
DATABASE IS READY TO USE!
#########################
```

After the database is ready, monitor the Oracle Globally Distributed Database setup:

```bash
podman exec catalog /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
      GSM Catalog Setup Completed
==============================================
```

### Shard Containers

Repeat the following steps for each shard container (`shard1`, `shard2`, `shard3`, and `shard4`).

Monitor the Oracle database setup:

```bash
podman logs -f shard1
```

Database creation can take approximately 20 minutes. Wait for the following success message:

```text
#########################
DATABASE IS READY TO USE!
#########################
```

After the database is ready, monitor the Oracle Globally Distributed Database setup:

```bash
podman exec shard1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
     GSM Shard Setup Completed
==============================================
```

Repeat these steps for `shard2`, `shard3`, and `shard4`.

### Primary GSM Container

Monitor the primary GSM container setup:

```bash
podman exec gsm1 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
     GSM Setup Completed
==============================================
```

### Standby GSM Container

Monitor the standby GSM container setup:

```bash
podman exec gsm2 /bin/bash -c "tail -f /var/tmp/gdd/oracle_sharding_setup.log"
```

Wait for the following success message:

```text
==============================================
     GSM Setup Completed
==============================================
```

## Workload Test

See [Workload Test](./workload_test.md) for a sample Swingbench workload test against this Oracle Globally Distributed Database deployment.

## Remove the deployment

To remove the deployment, ensure the environment variables from [Complete the prerequisite steps](#complete-the-prerequisite-steps) are still set, then run:

```bash
podman-compose down
rm -rf ${PODMANVOLLOC}
```

## Deploy with Oracle AI Database 26ai Free

You can also use Oracle AI Database 26ai Free and Oracle 26ai GSM container images with `podman-compose` to deploy Oracle Globally Distributed Database with System-Managed Sharding, System-Managed Sharding with Raft replication, or User-Defined Sharding.

For example, if you plan to use Oracle AI Database 26ai Free and Oracle 26ai GSM Container Images for deploying the Oracle Globally Distributed Database with `System-Managed Sharding Topology with Raft replication`, then complete these steps:

- Use file [podman-compose-prerequisites-free.sh](./podman-compose-prerequisites-free.sh) as the prerequisites script file before running the setup as described above.

**NOTE:** You must change the values for `SIDB_IMAGE` and `GSM_IMAGE` to use the Oracle AI Database 26ai Free and Oracle 26ai GSM Container Images you want to use for the deployment.

- Copy [podman-compose-free.yml](./podman-compose-free.yml) and rename it to `podman-compose.yml`.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
