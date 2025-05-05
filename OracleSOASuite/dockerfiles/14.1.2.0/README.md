# Running Oracle SOA Suite in containers

Sample configurations to facilitate installation, configuration, and environment setup for Podman users. This project includes quick start `Containerfiles` for Oracle SOA 14.1.2.0 based on Oracle Linux 8, Oracle JDK 17, and Oracle Fusion Middleware Infrastructure 14.1.2.0.

The sample files in this repository are for development purposes, customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Containerfiles.


At the end of this configuration there will be at least two running containers:
1. (Optional) Oracle Database container (only when RCU schema is created in a database running in a container)
2. Oracle WebLogic Server Administration Server container
3. Two Oracle WebLogic Server Managed Server containers (Oracle SOA Server or Oracle Service Bus Server)

This documentation provides the steps for a Single node scenario where all the containers are created on a single node.

To create the Podman network and run containers, follow these steps:

 1. [Create a network](#1-create-a-network)
 2. [Mount a host directory as a data volume](#2-mount-a-host-directory-as-a-data-volume)
 3. [Create the database](#3-create-the-database)
 4. [Obtain the SOA 14.1.2.0 container image](#4-obtain-the-soa-14120-container-image)
 5. [Create a container for the Administration Server](#5-create-a-container-for-the-administration-server)
 6. [Create SOA Managed Server containers](#6-create-soa-managed-server-containers)
 7. [Create Oracle Service Bus Managed Server containers](#7-create-oracle-service-bus-managed-server-containers)
 8. [Access the Consoles](#8-access-the-consoles)
 9. [Clean up the environment](#9-clean-up-the-environment)

## 1. Create a network

The containers will be connected using a Podman user-defined network.

### Create a user-defined network

In this configuration, the creation of a user-defined network will enable the communication between the containers just using container names. For this setup we will use a user-defined network using bridge driver.

Create a user-defined network using the bridge driver:
`$ podman network create -d bridge <network name>`

For example:
`$ podman network create -d bridge SOANet`

## 2. Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. Podman automatically creates volumes when you specify a volume name with the -v option, without the need to predefine directories on the host.
In this project, the volumes will be used to store Database data files and WebLogic Server domain files. These volumes will be automatically created and managed by Podman. The names of the volumes are specified in the podman run commands.

`$ podman -d --name soadb -v soadb_vol:/opt/oracle/oradata`

The default storage location for Podman volumes is determined by Podman’s storage configuration.
To identify the location of a volume, run:

`$ podman volume inspect <volume_name>`

The Mountpoint entry should point to the location of the volume in the host.

Podman creates volumes with default permissions. Ensure that the container’s oracle user has the necessary read/write/execute permissions on the auto-created volume. This may require setting proper permissions or ownership using a post-creation script, depending on your environment.

`$ sudo chmod -R 777 $HOME/.local/shared/containers/storage/volumes/soadb_vol`

To determine if a user already exists on your node system with uid:gid of 1000, run:

`$ getent passwd 1000`

If this command returns a username (which is the first field), you can skip the following `useradd` command. If not, create the `oracle` user manually:

`$ useradd -u 1000 -g 0 oracle`

## 3. Create the database

You need to have a running database container or a database running on any machine. The database connection details are required for creating SOA-specific RCU schemas while configuring the SOA domain. While using a 19.3.0.0 CDB/PDB DB, ensure a PDB is used to load the schemas. RCU loading on a CDB is not supported.

The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the SOA image to connect to the database running in the container.

To run the database container to host the RCU schemas:

1. Add the following parameters to a `db.env.txt` file:
    ``` bash
    ORACLE_SID=soadb
    ORACLE_PDB=soapdb
    ORACLE_PWD=Oradoc_db1
    ENABLE_ARCHIVELOG=true
    ```
1. Enter the following command:
    ``` bash
    `$ podman run -d --name soadb --network=SOANet -p 1521:1521 -p 5500:5500 -v soadb_vol:/opt/oracle/oradata --env-file ./db.env.txt container-registry.oracle.com/database/enterprise:19.3.0.0`
    ```
1. Verify that the database is running and healthy. The `STATUS` field should show `healthy` in the output of `podman ps`.

## 4. Obtain the SOA 14.1.2.0 container image

You can either build the SOA image with the `Containerfile` provided or use the already available Oracle SOA Suite (14.1.2.0) image in the [Oracle Container Registry](https://container-registry.oracle.com/ords/ocr/ba/middleware/soasuite).

## 5. Create a container for the Administration Server

Start a container to launch the Administration Server from the image created using the steps above. The environment variables used to configure the domain are defined in `adminserver.env.list`. Replace in `adminserver.env.list` the values for the Database and WebLogic Server passwords.

Create an environment file `adminserver.env.list`:
``` bash
CONNECTION_STRING=<Database container name>:<port#>/<ORACLE_PDB>
RCUPREFIX=<RCU_Prefix>
DB_PASSWORD=<database_sys_password>
DB_SCHEMA_PASSWORD=<soa-infra schema password>
ADMIN_PASSWORD=<admin_password>
DOMAIN_NAME=soainfra
DOMAIN_TYPE=<soa/osb/soaosb>
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=<Node port number mapping Administration Server container port `7001`>
PERSISTENCE_STORE=<jdbc | file>
```
>IMPORTANT: `DOMAIN_TYPE` must be carefully chosen and specified depending on the use case. It can't be changed once you proceed.
For Oracle SOA Suite domains, the supported domain types are `soa`, `osb` and `soaosb`.
- soa       : Deploys a SOA Domain with Enterprise Scheduler (ESS)
- osb       : Deploys an OSB Domain (Oracle Service Bus)
- soaosb    : Deploys a Domain with SOA, OSB and Enterprise Scheduler (ESS)

For example:
``` bash
CONNECTION_STRING=soadb:1521/soapdb
RCUPREFIX=SOA1
DB_PASSWORD=Oradoc_db1
DB_SCHEMA_PASSWORD=Oradoc_db1
ADMIN_PASSWORD=welcome1
DOMAIN_NAME=soainfra
DOMAIN_TYPE=soa
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
PERSISTENCE_STORE=jdbc
```
If `PERSISTENCE_STORE` is not specified, the default value is `jdbc`. When `PERSISTENCE_STORE=jdbc`, a JDBC persistence store will be configured for all servers for TLOG + SOAJMS/UMSJMS servers. If `PERSISTENCE_STORE=file`, file-based persistence stores will be used instead.


To start a Podman container with a SOA domain and the WebLogic Server Administration Server, use the `podman run` command and pass the `adminserver.env.list` file.

For example:
``` bash
`$ podman run -it --name soaas --network=SOANet -p 7001:7001 -v soadomain_vol:/u01/oracle/user_projects --env-file ./adminserver.env.list container-registry.oracle.com/middleware/soasuite:14.1.2.0-17-ol8-241205`
```
The options `-it` in the above command runs the container in interactive mode and you will be able to see the commands running in the container. This includes the command for RCU creation, domain creation, and configuration, followed by starting the Administration Server.

> IMPORTANT: You need to wait until all the above commands are run before you can access the Administration Server Web Console. The following lines highlight when the Administration Server is ready to be used:
``` bash
INFO: Admin server is running

INFO: Admin server running, ready to start Managed Server
```
These lines indicate that the Administration Server started successfully with the name `soaas`. Mapping container port `7001` to node port `7001` enables access to the WebLogic Server node outside of the local node. Connecting to the `SOANet` network enables access to the DB container by its name (`soadb`).

To view the Administration Server logs, enter the following command:
``` bash
`$ podman logs -f \<Administration Server container name\>`
```
## 6. Create SOA Managed Server containers

> **Note**: These steps are required only for the  `soa` and `soaosb` domain type.

You can start containers to launch the SOA Managed Servers from the image created.

Create an environment variables file specific to each Managed Server in the cluster in the SOA domain. For example, `soaserver1.env.list` and `soaserver2.env.list` for a SOA cluster:
``` bash
MANAGED_SERVER=<Managed Server name, either soa_server1 or soa_server2>
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=<Node port number mapping Administration Server container port `7001`>
ADMIN_PASSWORD=<admin_password>
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=<Container port number where Managed Server is running>
```

>IMPORTANT: In the Managed Servers environment variables file
> - `MANAGED_SERVER` value must be `soa_server1` or `soa_server2` for the  `soa` and `soaosb` domain type.
> - `MANAGEDSERVER_PORT` must be `7003` for `soa_server1` or `7005` for `soa_server2`.
> - `ADMIN_PORT` must match the **node** port mapping the Administration Server container port `7001`.

Example for `soaserver1.env.list`:
``` bash
MANAGED_SERVER=soa_server1
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=7003
```

Example for `soaserver2.env.list`:
``` bash
MANAGED_SERVER=soa_server2
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=7005
```
To start a Podman container for the SOA server (for `soa_server1`), you can use the `podman run` command passing `soaserver1.env.list` with port `7003`.

For example:
``` bash
`$ podman run -it --name soams1 --network=SOANet -p 7003:7003  -v soadomain_vol:/u01/oracle/user_projects --env-file ./soaserver1.env.list container-registry.oracle.com/middleware/soasuite:14.1.2.0-17-ol8-241205 "/u01/oracle/container-scripts/startMS.sh"`
```
Similarly, to start a second Podman container for the SOA server (for `soa_server2`), you can use the `podman run` command passing `soaserver2.env.list` with port `7005`.

For example:
``` bash
`$ podman run -it --name soams2 --network=SOANet -p 7005:7005 -v soadomain_vol:/u01/oracle/user_projects --env-file ./soaserver2.env.list  container-registry.oracle.com/middleware/soasuite:14.1.2.0-17-ol8-241205 "/u01/oracle/container-scripts/startMS.sh"`
```

> **Note**: Using `-v` reuses the volume created by the Administration Server container.


The following lines indicate when the SOA Managed Server is ready to be used:
``` bash
INFO: Managed Server is running

INFO: Managed Server has been started
```
Once the Managed Server container is created, you can view the server logs:

`$ podman logs -f \<Managed Server container name\>`

## 7. Create Oracle Service Bus Managed Server containers

> **Note**: These steps are required only for the `osb` and `soaosb` domain type.

You can start containers to launch the Oracle Service Bus Managed Servers from the image created.

Create an environment variables file specific to each Managed Server in the cluster in the SOA domain. For example, `osbserver1.env.list` and `osbserver2.env.list` for an Oracle Service Bus cluster:
``` bash
MANAGED_SERVER=<Managed Server name, either osb_server1 or osb_server2>
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=<Node port number mapping Administration Server container port `7001`>
ADMIN_PASSWORD=<admin_password>
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=<Container port number where Managed Server is running>
```

>IMPORTANT: In the Managed Servers environment variables file
> - `MANAGED_SERVER` value must be `osb_server1` or `osb_server2` for the  `osb` and `soaosb` domain type.
> - `MANAGEDSERVER_PORT` must be `8002` for `osb_server1` or `8004` for `osb_server2`.
> - `ADMIN_PORT` must match the **node** port mapping the Administration Server container port `7001`.

Example for `osbserver1.env.list`:
``` bash
MANAGED_SERVER=osb_server1
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=8002
```
Example for `osbserver2.env.list`:
```bash
MANAGED_SERVER=osb_server2
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=8004
```

To start a Podman container for the Oracle Service Bus server (for `osb_server1`), you can use the `podman run` command passing `osbserver1.env.list`.

For example:
``` bash
`$ podman run -it --name osbms1 --network=SOANet -p 8002:8002 -v soadomain_vol:/u01/oracle/user_projects --env-file ./osbserver1.env.list container-registry.oracle.com/middleware/soasuite:14.1.2.0-17-ol8-241205 "/u01/oracle/container-scripts/startMS.sh"`
```
Similarly, to start a second Podman container for the Oracle Service Bus server (for `osb_server2`), you can use the `podman run` command passing `osbserver2.env.list`.

For example:
``` bash
`$ podman run -it --name osbms1 --network=SOANet -p 8004:8004 -v soadomain_vol:/u01/oracle/user_projects --env-file ./osbserver2.env.list container-registry.oracle.com/middleware/soasuite:14.1.2.0-17-ol8-241205 "/u01/oracle/container-scripts/startMS.sh"`
```
The following lines indicate when the Oracle Service Bus Managed Server is ready to be used:
``` bash
INFO: Managed Server is running

INFO: Managed Server has been started
```

Once the Managed Server container is created, you can view the server logs:
``` bash
`$ podman logs -f \<Managed Server container name\>`
```

## 8. Access the Consoles
Now you can access the following Consoles:

* EM Console at http://\<hostname\>:7001/em  with weblogic/welcome1 credentials.
* SOA infra Console at http://\<hostname\>:7003/soa-infra with weblogic/welcome1 credentials.
* SOA infra Console at http://\<hostname\>:7005/soa-infra with weblogic/welcome1 credentials.
* Service Bus Console at http://\<hostname\>:7001/servicebus with weblogic/welcome1 credentials.


> **Note**: `hostname` is the FQDN of the host name where the container is running. Do not use 'localhost' for `ADMIN_HOST`. Use the actual FQDN name of the host as `ADMIN_HOST`. <br>
In a multinode scenario, you cannot access the `SOA Composer` and `BPM Worklist` application URLs from the `soa-infra` application page.

## 9. Clean up the environment

1. Stop and remove all running containers from the node where the container is running:
    ``` bash
    `$ podman stop \<container name\>`

    `$ podman rm \<container name\>`
    ```
    where containers are `soadb`, `soaas`, `soams1`, `soams2`, `osbms1` and `osbms2`.

2. Clear the data volume:
    ``` bash
    `$ podman volume rm soadb_vol`

    `$ podman volume rm soadomain_vol`
    ```
3. Remove the Podman network:
    ``` bash
    `$ podman network rm SOANet`
    ```
