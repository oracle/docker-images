# Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers

In this installation guide, the individual shards and the catalog database are deployed using Oracle RAC Databases in Podman Containers. In the current case:

- the Catalog and the Shard Databases will be deployed using 2 node Oracle RAC Databases with each of the RAC Node running in a separate container
- the First Node of each of the RAC Database is deployed on one podman host machine and the Second Node of each of the RAC Database is deployed on another podman host machine
- Podman Network with Macvlan driver is enabled
- DNS Server is setup using a podman container running on the first podman host machine
- the GSM1 and GSM2 podman containers are setup on the first podman host machine

In this case, the Oracle Globally Distributed Database can be deployed with either System-Managed Sharding or User Defined Sharding.

**Note:** Oracle Globally Distributed Database deployment with System-Managed Sharding with RAFT replication enabled is currently NOT supported if the deployment is using Oracle RAC Database.

**NOTE:** Oracle Globally Distributed Database using Oracle RAC Database in Podman Containers is NOT available for Oracle AI Database 26ai Free version.

- [Oracle Globally Distributed Database using Oracle RAC in Podman Containers](#oracle-globally-distributed-database-using-oracle-rac-database-in-podman-containers)
  - [Prerequisites](#prerequisites)
  - [Network Management](#network-management)
    - [Macvlan Network on Both Host Machines](#macvlan-network-on-both-host-machines)
    - [Ipvlan Network on Both Host Machines](#ipvlan-network-on-both-host-machines)
  - [Setup DNS Container](#setup-dns-container)
  - [Password Management](#password-management)
  - [SELinux Configuration on Podman Host](#selinux-configuration-on-podman-host)
  - [Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers](#deploy-oracle-globally-distributed-database-using-oracle-rac-in-podman-containers)
    - [Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers with System-Managed Sharding](#deploy-oracle-globally-distributed-database-using-oracle-rac-in-podman-containers-with-system-managed-sharding)
    - [Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers with User-Defined Sharding](#deploy-oracle-globally-distributed-database-using-oracle-rac-in-podman-containers-with-user-defined-sharding)
- [Support](#support)
- [License](#license)
- [Copyright](#copyright)

## Prerequisites

You must complete all of the prerequisites before deploying an Oracle Globally Distributed Database using Podman Containers. These prerequisites include creating the Docker network, creating the encrypted file with secrets, and other steps required before deployment.

### Network Management

Before creating a container, create the podman network by creating the Podman network bridge based on your environment. If you are using the podman network with the same subnet mentioned in this README.md, then you can use the same IPs mentioned in the [Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers](#deploy-oracle-globally-distributed-database-using-oracle-rac-in-podman-containers) section.

#### Macvlan Network on Both Host Machines

To create a Podman networks with `macvlan` driver, run the following commands on **both** host machines:

```bash
podman network create --driver=macvlan --subnet=10.0.15.0/24 -o parent=ens4 -o mtu=9000 shard_rac_pub1_nw
podman network create --driver=macvlan --subnet=10.0.16.0/24 -o parent=ens5 -o mtu=9000 shard_rac_priv1_nw
podman network create --driver=macvlan --subnet=10.0.17.0/24 -o parent=ens6 -o mtu=9000 shard_rac_priv2_nw
```

#### Ipvlan Network on Both Host Machines

To create a Podman network with `ipvlan` driver, run the following commands on **both** host machines:

```bash
podman network create --driver=ipvlan --subnet=10.0.15.0/24 -o parent=ens4 -o mtu=9000 shard_rac_pub1_nw
podman network create --driver=ipvlan --subnet=10.0.16.0/24 -o parent=ens5 -o mtu=9000 shard_rac_priv1_nw
podman network create --driver=ipvlan --subnet=10.0.17.0/24 -o parent=ens6 -o mtu=9000 shard_rac_priv2_nw
```

**Note:** You can change subnets and choose one of the above mentioned podman network configuration based on your environment.

### Setup DNS Container

In this setup, a DNS Container is used for name resolution. Please refer to [Oracle RAC DNS Server](https://github.com/oracle/docker-images/tree/main/OracleDatabase/RAC/OracleDNSServer) for the corresponding documentation.

Below command is used to create and deploy a DNS Server Container in current setup:

```bash
podman create --hostname racdns \
--dns-search=example.info \
--cap-add=AUDIT_WRITE \
-e DOMAIN_NAME="example.info" \
-e WEBMIN_ENABLED=false \
-e RAC_NODE_NAME_PREFIXD="racnoded" \
-e RAC_NODE_NAME_PREFIXP="racnodep" \
-e SETUP_DNS_CONFIG_FILES="setup_true"  \
--privileged=false \
--name rac-dnsserver \
oracle/rac-dnsserver:latest


podman network disconnect podman rac-dnsserver
podman network connect shard_rac_pub1_nw --ip 10.0.15.25 rac-dnsserver
podman network connect shard_rac_priv1_nw --ip 10.0.16.25 rac-dnsserver
podman network connect shard_rac_priv2_nw --ip 10.0.17.25 rac-dnsserver
podman start rac-dnsserver
```

**Note:** The DNS Container will be running only on the First Host Machine.

### Password Management

**IMPORTANT:** Make sure the version of `openssl` in the Oracle Database and Oracle GSM images is compatible with the `openssl` version on the machine where you will run the openssl commands to generated the encrypted password file during the deployment.

- Specify the secret volume for resetting database user passwords during catalog and shard setup. The secret volume can be a shared volume among all the containers

  ```bash
  mkdir /opt/.secrets/
  cd /opt/.secrets
  openssl genrsa -out key.pem
  openssl rsa -in key.pem -out key.pub -pubout
  ```

- Edit the `/opt/.secrets/pwdfile.txt` and seed the password. The password will be common for all the database users. Run the following command:

  ```bash
  vi /opt/.secrets/pwdfile.txt
  ```

  **Note**: Enter your secure password in the pwdfile.txt file and save the file.

- After seeding password and saving the `/opt/.secrets/pwdfile.txt` file, run the following command:

  ```bash
  openssl pkeyutl -in /opt/.secrets/pwdfile.txt -out /opt/.secrets/pwdfile.enc -pubin -inkey /opt/.secrets/key.pub -encrypt
  rm -rf /opt/.secrets/pwdfile.txt
  ```

  Oracle recommends using Podman secrets inside the containers. Run the following command to create the Podman secrets:
  
  ```bash
  podman secret create pwdsecret /opt/.secrets/pwdfile.enc
  podman secret create keysecret /opt/.secrets/key.pem

  podman secret ls
  ID                         NAME        DRIVER      CREATED        UPDATED
  547eed65c01d525bc2b4cebd9  keysecret   file        8 seconds ago  8 seconds ago
  8ad6e8e519c26e9234dbcf60a  pwdsecret   file        8 seconds ago  8 seconds ago
  ```

**Note:** Use the same set of commands on _both_ the Host Machines to create same secrets on both the Host Machines.

**Note:** This password and key secrets are used for initial Oracle Globally Distributed Database topology setup. After the Oracle Globally Distributed Database topology setup is completed, you must change the topology passwords based on your enviornment.

## SELinux Configuration on Podman Host

To run Podman containers in an environment with Security-Enhanced Linux (SELinux) enabled, you must configure an SELinux policy for the containers. To check if your SELinux is enabled or not, run the `getenforce` command.
With SELinux, you must set a policy to implement permissions for your containers. If you do not configure a policy module for your containers, then they can end up restarting indefinitely, or generate other permission errors. You must add all Podman host nodes for your cluster to the policy module `shard-podman`, by installing the necessary packages and creating a type enforcement file (designated by the `.te` suffix) to build the policy, and load the policy into the system.

In the following example, the Podman host `podman-host` is configured in the SELinux policy module `shard-podman`:

Copy [shard-podman.te](../../../containerfiles/shard-podman.te) to `/var/opt` folder in your host and then execute below:

```bash
cd /var/opt
make -f /usr/share/selinux/devel/Makefile shard-podman.pp
semodule -i shard-podman.pp
semodule -l | grep shard-pod
```

## Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers

Refer to the relevant section depending on whether you want to deploy the Oracle Globally Distributed Database using System-Managed Sharding or User-Defined Sharding.

### Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers with System-Managed Sharding

Refer to [Sample Oracle Globally Distributed Database with System-Managed Sharding deployed using Oracle RAC Database on Podman Containers](./podman-sharded-rac-database-with-system-sharding.md) to deploy a sample Oracle Globally Distributed Database with System-Managed sharding using podman containers. In this case, the Catalog and individual Shard Databases are deployed as 2 Node RAC Databases on Podman Containers.

### Deploy Oracle Globally Distributed Database using Oracle RAC in Podman Containers with User-Defined Sharding

Refer to [Sample Oracle Globally Distributed Database with User-Defined Sharding deployed using Oracle RAC Database on Podman Containers](./podman-sharded-rac-database-with-user-defined-sharding.md) to deploy a sample Oracle Globally Distributed Database with User-Defined sharding using Podman containers. In this case, the Catalog and individual Shard Databases are deployed as 2 Node RAC Databases on Podman Containers.

## Support

Oracle Globally Distributed Database on Docker is supported on Oracle Linux 7.
Oracle Globally Distributed Database on Podman is supported on Oracle Linux 8 and later releases.

## License

To run Oracle Globally Distributed Database, whether inside or outside a Container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and the GitHub docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
