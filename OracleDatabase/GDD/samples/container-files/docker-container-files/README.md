# Oracle Globally Distributed Database Containers on Docker

Docker is used on Oracle Linux 7 Host Machines to create containers. This document provides the details to manually create the Docker containers to deploy an Oracle Globally Distributed Database.

- [Prerequisites](#prerequisites)
  - [Create Network Bridge](#create-network-bridge)
    - [Macvlan Bridge](#macvlan-bridge)
    - [Ipvlan Bridge](#ipvlan-bridge)
    - [Bridge](#bridge)
  - [Setup Hostfile](#setup-hostfile)
  - [Password Setup](#password-setup)
  - [Create Containers](#create-containers)
    - [Deploy Oracle Globally Distributed Database with System-Managed Sharding](#deploy-oracle-globally-distributed-database-with-system-managed-sharding)
    - [Deploy Oracle Globally Distributed Database with User-Defined Sharding](#deploy-oracle-globally-distributed-database-with-user-defined-sharding)
- [Support](#support)
- [License](#license)
- [Copyright](#copyright)

## Prerequisites

You must complete all of the prerequisites before deploying an Oracle Globally Distributed Database using Docker Containers. These prerequisites include creating the Docker network, creating the encrypted file with secrets, and other steps required before deployment.

### Create Network Bridge

Before creating a container, you must create the Docker network by creating a Docker network bridge based on your environment. If you are using the bridge name with the network subnet mentioned in this README.md then you can use the same IPs mentioned in the [Create Containers](#create-containers) section.

#### Macvlan Bridge

```bash
docker network create -d macvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=ens5 shard_pub1_nw
```

#### Ipvlan Bridge

```bash
docker network create -d ipvlan --subnet=10.0.20.0/24 --gateway=10.0.20.1 -o parent=ens5 shard_pub1_nw
```

If you are planning to create a test environment within a single machine, then you can use a Docker bridge. However, these IPs will not be reachable on the user network.

#### Bridge

```bash
docker network create --driver=bridge --subnet=10.0.20.0/24 shard_pub1_nw
```

**Note:** You can change the subnet and choose one of the other Docker network bridge options mentioned above, based on your environment.

### Setup Hostfile

**Note:** You can skip this step of creating a Hostfile when you are using a DNS for the IP resolution.

All containers will share a host file for name resolution. The shared hostfile must be available to all containers. Create the shared host file (if it doesn't exist) at `/opt/containers/shard_host_file`.

For example:

```bash
mkdir /opt/containers
rm -rf /opt/containers/shard_host_file && touch /opt/containers/shard_host_file
```

Because Oracle Database containers do not have root access to modify the `/etc/hosts` file, add the following host entries in `/opt/containers/shard_host_file` This file must be prepopulated. You can change these entries based on your environment and network setup.

```bash
127.0.0.1       localhost.localdomain           localhost
10.0.20.100     oshard-gsm1.example.com         oshard-gsm1
10.0.20.101     oshard-gsm2.example.com         oshard-gsm2
10.0.20.102     oshard-catalog-0.example.com    oshard-catalog-0
10.0.20.103     oshard1-0.example.com           oshard1-0
10.0.20.104     oshard2-0.example.com           oshard2-0
10.0.20.105     oshard3-0.example.com           oshard3-0
10.0.20.106     oshard4-0.example.com           oshard4-0
```

### Password Setup

**IMPORTANT:** Make sure the version of `openssl` in the Oracle Database and Oracle GSM images is compatible with the `openssl` version on the machine where you will run the openssl commands to generated the encrypted password file during the deployment.

Specify the secret volume for resetting the database user password during catalog and shard setup. This secret volume can be a shared volume among all the containers

```bash
mkdir /opt/.secrets/
openssl genrsa -out /opt/.secrets/key.pem
openssl rsa -in /opt/.secrets/key.pem -out /opt/.secrets/key.pub -pubout
```

Edit the `/opt/.secrets/pwdfile.txt` and seed the password. The password will be a common password for all the database users. Execute following command:

```bash
vi /opt/.secrets/pwdfile.txt
```

**Note**: Enter your secure password in the above file and save the file.

After seeding password and saving the `/opt/.secrets/pwdfile.txt` file, run the following command:

```bash
openssl pkeyutl -in /opt/.secrets/pwdfile.txt -out /opt/.secrets/pwdfile.enc -pubin -inkey /opt/.secrets/key.pub -encrypt
rm -f /opt/.secrets/pwdfile.txt
chown 54321:54321 /opt/.secrets/pwdfile.enc
chown 54321:54321 /opt/.secrets/key.pem
chown 54321:54321 /opt/.secrets/key.pub
chmod 400 /opt/.secrets/pwdfile.enc
chmod 400 /opt/.secrets/key.pem
chmod 400 /opt/.secrets/key.pub
```

This password key is used for the initial Oracle Globally Distributed Database topology setup. After the Oracle Globally Distributed Database topology setup is completed, you must change the topology passwords based on your environment.

## Create Containers

Refer to the relevant section depending on whether you want to deploy the Oracle Globally Distributed Database using System-Managed Sharding, or User-Defined Sharding.

### Deploy Oracle Globally Distributed Database with System-Managed Sharding

Refer to [Sample Oracle Globally Distributed Database with System-Managed Sharding deployed manually using Docker Containers](./docker-sharded-database-with-system-sharding.md) to deploy a sample Oracle Globally Distributed Database with system-managed sharding using Docker containers.

### Deploy Oracle Globally Distributed Database with User-Defined Sharding

Refer to [Sample Oracle Globally Distributed Database with User-Defined Sharding deployed manually using Docker Containers](./docker-sharded-database-with-user-defined-sharding.md) to deploy a sample Oracle Globally Distributed Database with User-Defined sharding using Docker containers.

## Support

Oracle 19c or Oracle 23ai GSM and RDBMS is supported for Oracle Linux 7.

## License

To run Oracle Globally Distributed Database, whether inside or outside a Container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022, 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
