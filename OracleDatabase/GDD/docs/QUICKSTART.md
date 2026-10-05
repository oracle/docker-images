# Oracle Globally Distributed Database Container Quick Start Guide

Use this quick start to deploy Oracle Globally Distributed Database with RAFT replication enabled on a single Oracle Linux host using `Podman Compose`.

This is the fastest path to a working evaluation environment. It is best suited for first-time users who want to validate the container workflow before moving to the more detailed scenario guides.

## What This Quick Start Deploys

This guide creates the following on one Oracle Linux host:

- one catalog database container
- four shard database containers
- one primary GSM container
- one standby GSM container
- one Podman bridge network named: `shard_pub1_nw`

This quick start uses:

- Oracle AI Database 26ai container image: `container-registry.oracle.com/database/enterprise:latest`
- Oracle GSM container image: `container-registry.oracle.com/database/gsm:latest`
- default network subnet: `10.0.20.0/20`
- default data location used by the script: `/scratch/oradata`

## Before You Start

### Prerequisites

Before running this guide, review:

- [Prerequisites](../README.md#prerequisites)
- [Getting Container Images](../README.md#getting-container-images)

Minimum requirements for this quick start:

- Oracle Linux 8 or later
- kernel `5.14` or later
- at least `32 GB` of physical memory
- `root` or a user with `sudo` privileges
- access to the required container images

The helper script used in this guide validates the host, installs Podman and `podman-compose` if needed, configures SELinux support when applicable, and creates the required Podman secrets.

### Working Directory

Run the commands in this guide from:

```bash
<GITHUB_REPO_CLONED_PATH>/db-sharding/container-based-sharding-deployment/containerfiles
```

### Files Used by This Quick Start

- Host preparation script: [setup_gdd_host.sh](../containerfiles/setup_gdd_host.sh)
- Compose file: [podman-compose.yml](../samples/compose-files/podman-compose/podman-compose.yml)
- Environment variable reference: [ENVVARIABLESCOMPOSE.md](./ENVVARIABLESCOMPOSE.md)

## Step 1: Set the Deployment Password

Set the secret used by the helper script to create the Podman secrets:

```bash
export SHARDING_SECRET=<secret-password>
```

If `SHARDING_SECRET` is not set, the deployment script will fail when it tries to create `pwdsecret` and `keysecret`.

## Step 2: Prepare the Host

Run the host preparation script:

```bash
./setup_gdd_host.sh -prepare-sharding-env
```

This step:

- validates the Oracle Linux and kernel versions
- installs Podman if it is missing
- installs `podman-compose` if it is missing
- configures SELinux policy when SELinux is enabled
- validates that the host has enough memory

Expected success message:

```txt
INFO: Finished setting up the prerequisites for Podman host
```

## Step 3: Stage the Compose File and Export Environment Variables

Copy the compose file into the working directory:

```bash
cp ../samples/compose-files/podman-compose/podman-compose.yml .
```

Then export the required environment variables:

```bash
source ./setup_gdd_host.sh -export-sharding-env
```

Use `source` so the environment variables remain available in your current shell.

This step also:

- creates `/opt/containers/shard_host_file`
- creates the required storage directories under `/scratch/oradata`
- creates Podman secrets
- applies SELinux file contexts when needed

Expected success message:

```txt
Sharding Environment Variables are setup successfully.
```

Important defaults used by the script:

- `PODMANVOLLOC=/scratch/oradata`
- `NETWORK_SUBNET=10.0.20.0/20`
- `SIDB_IMAGE=container-registry.oracle.com/database/enterprise:latest`
- `GSM_IMAGE=container-registry.oracle.com/database/gsm:latest`

If you need different values, review [ENVVARIABLESCOMPOSE.md](./ENVVARIABLESCOMPOSE.md) before deployment.

## Step 4: Deploy the Environment

Deploy the services in the following order. Wait for the success message from each service before moving to the next one.

| Order | Service | Deploy command | Monitor logs | Success message |
| --- | --- | --- | --- | --- |
| 1 | Catalog | `./setup_gdd_host.sh -deploy-catalog` | `podman-compose logs -f catalog_db` | `GSM Catalog Setup Completed` |
| 2 | Shard 1 | `./setup_gdd_host.sh -deploy-shard1` | `podman-compose logs -f shard1_db` | `GSM Shard Setup Completed` |
| 3 | Shard 2 | `./setup_gdd_host.sh -deploy-shard2` | `podman-compose logs -f shard2_db` | `GSM Shard Setup Completed` |
| 4 | Shard 3 | `./setup_gdd_host.sh -deploy-shard3` | `podman-compose logs -f shard3_db` | `GSM Shard Setup Completed` |
| 5 | Shard 4 | `./setup_gdd_host.sh -deploy-shard4` | `podman-compose logs -f shard4_db` | `GSM Shard Setup Completed` |
| 6 | Primary GSM | `./setup_gdd_host.sh -deploy-gsm-primary` | `podman-compose logs -f primary_gsm` | `GSM Setup Completed` |
| 7 | Standby GSM | `./setup_gdd_host.sh -deploy-gsm-standby` | `podman-compose logs -f standby_gsm` | `GSM Setup Completed` |

Example deployment sequence:

```bash
./setup_gdd_host.sh -deploy-catalog
./setup_gdd_host.sh -deploy-shard1
./setup_gdd_host.sh -deploy-shard2
./setup_gdd_host.sh -deploy-shard3
./setup_gdd_host.sh -deploy-shard4
./setup_gdd_host.sh -deploy-gsm-primary
./setup_gdd_host.sh -deploy-gsm-standby
```

## Step 5: Validate the Deployment

Check that all containers are running:

```bash
podman ps -a
```

You should see these containers in the `Up` state:

- `catalog`
- `shard1`
- `shard2`
- `shard3`
- `shard4`
- `gsm1`
- `gsm2`

You can also inspect service-level logs if a container is still initializing:

```bash
podman-compose logs -f catalog_db
podman-compose logs -f shard1_db
podman-compose logs -f primary_gsm
```

Success criteria:

- all seven containers are present
- all seven containers are running
- each service reaches the expected setup completion message

You can log in to a GSM container and run basic checks using `GDSCTL` commands.

For example, connect to the `gsm1` container using the following command:

```bash
podman exec -it gsm1 /bin/bash
```

Run the following checks:

```bash
gdsctl config shard
gdsctl config sdb
gdsctl config chunks
gdsctl status ru
```

## Common Issues

### `SHARDING_SECRET` Is Not Set

Symptom:

- secret creation fails during `-export-sharding-env`

Fix:

```bash
export SHARDING_SECRET=<secret-password>
source ./setup_gdd_host.sh -export-sharding-env
```

### Environment Variables Are Missing

Symptom:

- the script reports missing variables from `podman-compose.yml`

Fix:

- make sure you copied `podman-compose.yml` into the working directory
- rerun `source ./setup_gdd_host.sh -export-sharding-env`
- stay in the same shell session after sourcing the script

### A Container Exits or Stays in Initialization

Symptom:

- one or more containers are not in the `Up` state

Fix:

- inspect the service logs with `podman-compose logs -f <service>`
- confirm the previous deployment step finished successfully before starting the next one
- verify that the host has enough memory and free space under `/scratch/oradata`

### SELinux or Host Preparation Problems

Symptom:

- the prepare step fails or container file access is blocked

Fix:

- rerun `./setup_gdd_host.sh -prepare-sharding-env`
- review the SELinux-related output from the prepare step
- confirm you are running as `root` or with `sudo`

## Clean Up the Environment

To remove the environment created by this quick start:

```bash
./setup_gdd_host.sh -cleanup
```

This removes:

- the deployed containers
- the `shard_pub1_nw` Podman network
- data created under `PODMANVOLLOC`

Expected success message:

```txt
INFO: Oracle Globally Distributed Database Container Environment Cleanup Successfully
```

## Next Steps

After you complete this quick start, you can move to the detailed guides for other deployment patterns:

- [Top-level README](../README.md)
- [Podman manual deployment](../samples/container-files/podman-container-files/README.md)
- [Podman Compose deployment](../samples/compose-files/podman-compose/README.md)

## Environment Variables Reference

For a complete list of configurable variables, see [ENVVARIABLESCOMPOSE.md](./ENVVARIABLESCOMPOSE.md).

## Support

Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and later.

## License

To run Oracle Globally Distributed Database, whether inside or outside a container, download the binaries from the Oracle website and accept the license terms provided there.

Unless otherwise noted, the scripts and files in this project and the related `docker-images/OracleDatabase` repository are released under the UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
