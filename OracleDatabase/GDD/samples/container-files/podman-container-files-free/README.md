# Oracle Globally Distributed Database on Podman with Oracle AI Database 26ai Free Images

This guide provides detailed instructions for deploying Oracle Globally Distributed Database on Podman using Oracle AI Database 26ai Free image.

This page is the entry point for the Free-image manual deployment flow. It explains the shared setup steps once, then directs you to the scenario-specific deployment guides.

- [Oracle Globally Distributed Database on Podman with Oracle AI Database 26ai Free Images](#oracle-globally-distributed-database-on-podman-with-oracle-ai-database-26ai-free-images)
  - [When to Use This Guide](#when-to-use-this-guide)
  - [What This Guide Covers](#what-this-guide-covers)
  - [Before You Start](#before-you-start)
  - [Oracle Database Free Image Constraints](#oracle-database-free-image-constraints)
  - [Prerequisites](#prerequisites)
    - [Network Management](#network-management)
      - [Macvlan Network](#macvlan-network)
      - [Ipvlan Network](#ipvlan-network)
      - [Bridge Network](#bridge-network)
    - [Set Up the Host File](#set-up-the-host-file)
    - [Password Management](#password-management)
  - [SELinux Configuration on Podman Host](#selinux-configuration-on-podman-host)
  - [Deploy Oracle Globally Distributed Database Containers](#deploy-oracle-globally-distributed-database-containers)
  - [Image Notes](#image-notes)
  - [Support](#support)
  - [License](#license)
  - [Copyright](#copyright)

## When to Use This Guide

Use this guide if all of the following are true:

- you want to deploy with Podman, not Docker or `podman-compose`
- you want to use Oracle AI Database 26ai Free images
- you want to follow the manual container deployment flow

If you want the fastest guided first deployment instead, start with the [Quick Start](../../../docs/QUICKSTART.md).

For the broader documentation entry point, see the top-level [README](../../../README.md).

## What This Guide Covers

This page covers the shared setup required before any of these deployment scenarios:

- System-Managed Sharding
- System-Managed Sharding with RAFT Replication
- User-Defined Sharding
- Composite Sharding
- Composite Sharding with RAFT Replication

Shared setup includes:

- Podman network creation
- shared host file creation
- password encryption and Podman secrets
- SELinux preparation when SELinux is enabled
- Oracle Database Free image considerations

## Before You Start

Before using this page, review these top-level sections:

- [Prerequisites](../../../README.md#prerequisites)
- [Getting Container Images](../../../README.md#getting-container-images)

This guide assumes:

- Oracle Linux 8 or later
- Podman is installed and working
- required container images are available
- commands are run as `root` or by a user with `sudo` privileges

## Oracle Database Free Image Constraints

When you use Oracle Database Free images, keep these limits and requirements in mind:

- Oracle Database Free limits foreground processing to `2 CPUs`
- Oracle Database Free limits memory to `2 GB RAM`
- Oracle Database Free limits user data to `12 GB` on disk
- `CATALOG_CHUNKS` defaults to `12` when not specified
- `INIT_SGA_SIZE` and `INIT_PGA_SIZE` are not supported for this deployment path
- cloning from a database gold image is not supported with Oracle Database Free images
- `ORACLE_SID` must be `FREE`
- `ORACLE_PDB` must be `FREEPDB1`
- extra PDB can be specified through `ORACLE_FREE_PDB`
- `DB_UNIQUE_NAME` can differ from `ORACLE_SID`
- Use is limited to `three` shards

Please refer [Database Licensing Information User Manual](https://docs.oracle.com/en/database/oracle/oracle-database/26/dblic/Licensing-Information.html#GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4).

If these limits do not fit your environment, use one of the non-Free deployment paths from the top-level [README](../../../README.md#deployment-scenarios).

## Prerequisites

You must complete all prerequisites before deploying Oracle Globally Distributed Database using Podman containers. These prerequisites include creating the Podman network, configuring password secrets, and completing the other host preparation steps required before deployment.

### Network Management

Before creating the containers, create a Podman network appropriate for your environment. If you use the same Podman network subnet specified in this guide, you can use the IP addresses shown in the [Deploy Oracle Globally Distributed Database Containers](#deploy-oracle-globally-distributed-database-containers) section.

#### Macvlan Network

To create a Podman network with the `macvlan` driver, run the following command:

```bash
podman network create -d macvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=ens5 shard_pub1_nw
```

#### Ipvlan Network

To create a Podman network with the `ipvlan` driver, run the following command:

```bash
podman network create -d ipvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=ens5 shard_pub1_nw
```

For a test environment running on a single host, you can use a Podman bridge network. However, the container IP addresses will not be directly reachable from the external network.

#### Bridge Network

To create a Podman network with the `bridge` driver, run the following command:

```bash
podman network create --driver=bridge --subnet=10.0.20.0/24 shard_pub1_nw
```

**Note:** You can change the subnet and choose one of the Podman network configurations described above based on your environment.

### Set Up the Host File

**Note:** You can skip this step if you use DNS for name resolution.

All containers share a host file for name resolution. The shared host file must be available to all containers. Create the shared host file, if it does not already exist, at `/opt/containers/shard_host_file`:

For example:

```bash
mkdir -p /opt/containers
rm -f /opt/containers/shard_host_file && touch /opt/containers/shard_host_file
```

Because Oracle Database containers do not have root access to modify the `/etc/hosts` file, add the following entries to `/opt/containers/shard_host_file`.

```text
127.0.0.1       localhost.localdomain           localhost
10.0.20.100     oshard-gsm1.example.com         oshard-gsm1
10.0.20.101     oshard-gsm2.example.com         oshard-gsm2
10.0.20.102     oshard-catalog-0.example.com    oshard-catalog-0
10.0.20.103     oshard1-0.example.com           oshard1-0
10.0.20.104     oshard2-0.example.com           oshard2-0
10.0.20.105     oshard3-0.example.com           oshard3-0
10.0.20.106     oshard4-0.example.com           oshard4-0
```

### Password Management

- Generate the RSA key pair used to encrypt the database password:

  ```bash
  mkdir -p /opt/.secrets/
  cd /opt/.secrets
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out key.pem
  openssl pkey -in key.pem -pubout -out key.pub
  ```

- Create `/opt/.secrets/pwdfile.txt` with the password to use for the initial database setup. This password is used for all database users during setup.

  ```bash
  printf '%s' '<database-user-password>' > /opt/.secrets/pwdfile.txt
  ```

- Encrypt `/opt/.secrets/pwdfile.txt` using the following command:

  ```bash
  # Encrypt with explicit secure OAEP settings (version-stable)
  openssl pkeyutl -encrypt \
  -pubin -inkey key.pub \
  -in /opt/.secrets/pwdfile.txt -out /opt/.secrets/pwdfile.enc \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -pkeyopt rsa_mgf1_md:sha256
  ```

- Remove the file containing the initial database password:

  ```bash
  rm -f /opt/.secrets/pwdfile.txt
  ```

- Create the Podman secrets:
  
  ```bash
  podman secret create pwdsecret /opt/.secrets/pwdfile.enc
  podman secret create keysecret /opt/.secrets/key.pem
  ```

- Verify that the Podman secrets were created:

  ```bash
  podman secret ls
  ```

  Example output:

  ```text
  ID                         NAME        DRIVER      CREATED        UPDATED
  547eed65c01d525bc2b4cebd9  keysecret   file        8 seconds ago  8 seconds ago
  8ad6e8e519c26e9234dbcf60a  pwdsecret   file        8 seconds ago  8 seconds ago
  ```

**Note:** These password and key secrets are used during the initial Oracle Globally Distributed Database topology setup. After the topology setup is complete, change the topology passwords according to your environment's security requirements.

## SELinux Configuration on Podman Host

If Security-Enhanced Linux (SELinux) is enabled on the Podman host, configure the required SELinux policy for the containers. To check the SELinux status, run:

```bash
getenforce
```

Without the required SELinux policy, containers may restart indefinitely or encounter file permission errors.

Install the required SELinux packages, create the policy module from the `shard-podman.te` type enforcement file, and load the policy on each Podman host.

In the following example, the SELinux policy module `shard-podman` is configured on the Podman host.

Copy [shard-podman.te](../../../containerfiles/shard-podman.te) to `/var/opt` on the Podman host, and then run:

```bash
cd /var/opt
make -f /usr/share/selinux/devel/Makefile shard-podman.pp
semodule -i shard-podman.pp
semodule -l | grep shard-pod
```

## Deploy Oracle Globally Distributed Database Containers

Oracle Globally Distributed Database deployment using the Oracle AI Database 26ai FREE Image supports the following sharding and replication combinations:

```text
Supported Deployment Combinations

├── System-Managed Sharding
│   ├── Data Guard Replication
│   └── Native (Raft) Replication
│
├── User-Defined Sharding
│   └── Data Guard Replication
│
└── Composite Sharding
    ├── Data Guard Replication
    └── Native (Raft) Replication
```

## Image Notes

This manual deployment path expects:

- Oracle Database Free image: `container-registry.oracle.com/database/free:latest`
- Oracle GSM image: `container-registry.oracle.com/database/gsm:latest`

If you want a different tag, adjust the image tag to the version you plan to deploy.

For image-pull guidance and compatibility notes, see [Getting Container Images](../../../README.md#getting-container-images).

The following examples demonstrate different deployment scenarios for Oracle Globally Distributed Database (GDD) using the Extended Oracle Single Instance Database Image.

| Scenario | Sample guide |
| --- | --- |
| System-Managed Sharding with Data Guard Replication | [Deploy Oracle GDD with System-Managed Sharding and Data Guard Replication with FREE Image](./podman-sharded-database-free-with-system-sharding.md) |
| System-Managed Sharding with Native (Raft) Replication | [Deploy Oracle GDD with System-Managed Sharding and Native (Raft) Replication with FREE Image](./podman-sharded-database-free-with-system-sharding-with-snr-raft-enabled.md) |
| User-Defined Sharding with Data Guard Replication | [Deploy Oracle GDD with User-Defined Sharding and Data Guard Replication with FREE Image](./podman-sharded-database-free-with-user-defined-sharding.md) |
| Composite Sharding with Data Guard Replication | [Deploy Oracle GDD with Composite Sharding and Data Guard Replication with FREE Image](./podman-sharded-database-free-with-composite-sharding.md) |
| Composite Sharding with Native (Raft) Replication | [Deploy Oracle GDD with Composite Sharding and Native (Raft) Replication with FREE Image](./podman-sharded-database-free-with-composite-sharding-with-snr-raft-enabled.md) |

## Support

- Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and later releases.

## License

To run Oracle Globally Distributed Database, whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and the GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
