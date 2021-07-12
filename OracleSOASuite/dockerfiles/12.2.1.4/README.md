Running Oracle SOA Suite in containers
======================================

Sample configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start `Dockerfiles` for Oracle SOA 12.2.1.4 based on Oracle Linux 7, Oracle Server JRE 8, and Oracle Fusion Middleware Infrastructure 12.2.1.4.

At the end of this configuration there will be at least two running containers:
1. (Optional) Oracle Database container (only when RCU schema is created in a database running in a container)
2. Oracle WebLogic Server Administration Server container
3. Two Oracle WebLogic Server Managed Server containers (Oracle SOA Server or Oracle Service Bus Server)

This documentation provides the steps for the two scenarios to start the containers on the node(s).

- **Single node scenario**: all the containers created on single node.
- **Multinode scenario**: containers can be run on any host connected through Docker Swarm.

  > **Note**: In this scenario, the soa-infra page will not display links to `SOA Composer` and `BPM Worklist` but you can access those two applications.

To create the Docker network and run containers, follow these steps:

 1. [Create a network](#1-create-a-network)
 2. [Mount a host directory as a data volume](#2-mount-a-host-directory-as-a-data-volume)
 3. [Create the database](#3-create-the-database)
 4. [Obtain the SOA 12.2.1.4 container image](#4-obtain-the-soa-122140-container-image)
 5. [Create a container for the Administration Server](#5-create-a-container-for-the-administration-server)
 6. [Create SOA Managed Server containers](#6-create-soa-managed-server-containers)
 7. [Create Oracle Service Bus Managed Server containers](#7-create-oracle-service-bus-managed-server-containers)
 8. [Access the Consoles](#8-access-the-consoles)
 9. [Clean up the environment](#9-clean-up-the-environment)

### 1. Create a network

#### Single node scenario
The containers will be connected using a Docker user-defined network.

##### Create a user-defined network

In this configuration, the creation of a user-defined network will enable the communication between the containers just using container names. For this setup we will use a user-defined network using bridge driver.

Create a user-defined network using the bridge driver:
``` bash
$ docker network create -d bridge <network name>
```
For example:
``` bash
$ docker network create -d bridge SOANet
```

#### Multinode scenario

The containers on different Docker daemons will be connected using a *Docker overlay network*.

##### Create an overlay network

In this configuration, creation of the Docker overlay network will enable communication between the containers. For this setup we will use a network using *bridge overlay*. In order to connect the containers from different hosts, *Docker Swarm* is used. Docker Swarm is a container orchestration tool that allows the user to manage multiple containers deployed across multiple node machines.

**Set up Docker Swarm**

1.  On any one node, initialize a swarm. This node is called the *swarm manager node*:
    ``` bash
    $ docker swarm init
    Swarm initialized: current node (5rsj1c75zpn31cc9lu9yycmi5) is now a manager.
    To add a worker to this swarm, run the following command:
    docker swarm join --token SWMTKN-1-1r8ap4o4fl5vbt3rtfanh7tr42t8h8lvempi1mmri745bcketd-24av3jhw8etrlf7m1toc8ek9j 100.111.150.225:2377
    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
    ```
2.  From all other nodes, join the swarm.

    For example:
    ``` bash
    $ docker swarm join --token SWMTKN-1-1r8ap4o4fl5vbt3rtfanh7tr42t8h8lvempi1mmri745bcketd-24av3jhw8etrlf7m1toc8ek9j 100.111.150.225:2377
    ```
    >  **Note**: If the node fails to join the swarm, the Docker `swarm join` command times out. To resolve, run `docker swarm leave --force`.

3.  Check all the nodes connected to the swarm manager node. Run the following command from the swarm manager node:
    ``` bash
    $ docker node ls
    ID     HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
    5rsj1c75zpn31cc9lu9yycmi5 *   host1           Ready               Active   Leader    19.03.1-ol
    ptnbia3hi7um59x0i28hqyutv     host2           Ready               Active         18.09.1-ol
    ```
    > **Note**: `host1` and `host2` are the host names on which the docker swarm network is created.

4.  From the swarm manager node, create an attachable `overlay` network called `SOANet`:
    ``` bash
    $ docker network create --driver=overlay --attachable SOANet
    ```
    Check the status of the overlay network `SOANet`:
    ``` bash
    $ docker network ls
    NETWORK ID          NAME                DRIVER              SCOPE
    y4mthrc3q4iu        SOANet              overlay             swarm
    9561d0bba675        bridge              bridge              local
    eaf7f217fa94        docker_gwbridge     bridge              local
    c8c2ac715eb1        node                node                local
    bkw9vjsimsde        ingress             overlay             swarm
    9afd6ed76e0b        none                null                local
    ```

### 2. Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. The default location of the volume in container is under `/var/lib/docker/volumes`. There is an option to mount a directory from the node into a container as the volume. In this project we will use that option for the data volume. The volume will be used to store Database data files and WebLogic Server domain files. This volume will be created on the node at `/u01/DockerVolume/SOAVolume/`. For a multinode scenario, this volume should be accessible from other nodes as well, so that containers from other nodes will reuse the volume created by Administration Server node. Since the volume is created as `root` user, provide read/write/execute permissions to the `oracle` user (by providing permissions to `others`), as all operations inside the container happens with the `oracle` user login.

To determine if a user already exists on your node system with uid:gid of 1000, run:
``` bash
# getent passwd 1000
```
If this command returns a username (which is the first field), you can skip the following `useradd` command. If not, create the `oracle` user manually:
``` bash
# useradd -u 1000 -g 0 oracle
```
>  **Note**: For a multinode scenario, make sure the `data volume` is accessible from other hosts to be used for running containers.   

Once the `oracle` user is created, run the following commands as a `root` user:
``` bash
# mkdir -p /u01/DockerVolume/SOAVolume/DB
# mkdir -p /u01/DockerVolume/SOAVolume/SOA
# chown -R 1000:0 /u01/DockerVolume/SOAVolume/
# chmod -R 777 /u01/DockerVolume/SOAVolume/
```
Set the path of the `data_volume` on all the terminals of the hosts where containers are to be started.

- **Single node scenario**:
    ``` bash
    $ export data_volume=/u01/DockerVolume/SOAVolume
    ```
- **Multinode scenario**:
    ``` bash
    $ export data_volume=/net/hostname/u01/DockerVolume/SOAVolume
    ```
> **Note**: Replace `hostname` with the FQDN of the host on which `data_volume` `/u01/DockerVolume/SOAVolume` is created.


> **Note**: For a multinode scenario, make sure the data volume `/u01/DockerVolume/SOAVolume` is accessible from other hosts to be used for running containers. Try to use `data volume` as a `NFS volume` or `/net` so that it can be accessible from other hosts.


### 3. Create the database

You need to have a running database container or a database running on any machine. The database connection details are required for creating SOA-specific RCU schemas while configuring the SOA domain. While using a 12.2.0.1 CDB/PDB DB, ensure a PDB is used to load the schemas. RCU loading on a CDB is not supported.

The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the SOA image to connect to the database running in the container.

To run the database container to host the RCU schemas:

1.  Add the following parameters to a `db.env.txt` file:
    ``` bash
    DB_SID=soadb
    DB_PDB=soapdb
    DB_DOMAIN=example.com
    DB_BUNDLE=basic
    ```
1.  Enter the following command:
    ``` bash
    $ docker run -d --name soadb --network=SOANet -p 1521:1521 -p 5500:5500 -v $data_volume/DB:/opt/oracle/oradata --env-file ./db.env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1
    ```
1.  Verify that the database is running and healthy. The `STATUS` field should show `healthy` in the output of `docker ps`.

The database is created with the default password `Oradoc_db1`. To change the database password, you must use `sqlplus`. To run `sqlplus`, pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a `sqlplus` container:
``` bash
$ docker run -ti --network=SOANet --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@soadb:1521/soadb.example.com AS SYSDBA

SQL> alter user sys identified by Welcome1 container=all;
```

### 4. Obtain the SOA 12.2.1.4 container image

You can either build the SOA image with the `Dockerfile` provided or use the already available Oracle SOA Suite (12.2.1.4) image in the [Oracle Container Registry](https://container-registry.oracle.com).

### 5. Create a container for the Administration Server

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
ADMIN_PORT=<port number where Administration Server is running>
PERSISTENCE_STORE=<jdbc | file>
```
>IMPORTANT: `DOMAIN_TYPE` must be carefully chosen and specified depending on the use case. It can't be changed once you proceed.
For Oracle SOA Suite domains, the supported domain types are `soa`, `osb` and `soaosb`. 
- soa       : Deploys a SOA Domain with Enterprise Scheduler (ESS)
- osb       : Deploys an OSB Domain (Oracle Service Bus)
- soaosb    : Deploys a Domain with SOA, OSB and Enterprise Scheduler (ESS)

For example:
``` bash
CONNECTION_STRING=soadb:1521/soapdb.example.com
RCUPREFIX=SOA1
DB_PASSWORD=Welcome1
DB_SCHEMA_PASSWORD=Welcome1
ADMIN_PASSWORD=Welcome1
DOMAIN_NAME=soainfra
DOMAIN_TYPE=soa
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
PERSISTENCE_STORE=jdbc
```
If `PERSISTENCE_STORE` is not specified, the default value is `jdbc`. When `PERSISTENCE_STORE=jdbc`, a JDBC persistence store will be configured for all servers for TLOG + SOAJMS/UMSJMS servers. If `PERSISTENCE_STORE=file`, file-based persistence stores will be used instead.

> IMPORTANT: In the Administration Server's environment variables file, the `ADMIN_PORT` value must be `7001`.

To start a Docker container with a SOA domain and the WebLogic Server Administration Server, use the `docker run` command and pass the `adminserver.env.list` file.

For example:
``` bash
$ docker run -i -t  --name soaas --network=SOANet -p 7001:7001  -v $data_volume/SOA:/u01/oracle/user_projects   --env-file ./adminserver.env.list oracle/soasuite:12.2.1.4
```
The options `-i -t` in the above command runs the container in interactive mode and you will be able to see the commands running in the container. This includes the command for RCU creation, domain creation, and configuration, followed by starting the Administration Server.

> IMPORTANT: You need to wait until all the above commands are run before you can access the Administration Server Web Console. The following lines highlight when the Administration Server is ready to be used:    
``` bash
INFO: Admin server is running

INFO: Admin server running, ready to start Managed Server
```
These lines indicate that the Administration Server started successfully with the name `soaas`. Mapping container port `7001` to node port `7001` enables access to the WebLogic Server node outside of the local node. Connecting to the `SOANet` network enables access to the DB container by its name (`soadb`).

To view the Administration Server logs, enter the following command:
``` bash
$ docker logs -f \<Administration Server container name\>
```
### 6. Create SOA Managed Server containers

> **Note**: These steps are required only for the  `soa` and `soaosb` domain type.

You can start containers to launch the SOA Managed Servers from the image created.

Create an environment variables file specific to each Managed Server in the cluster in the SOA domain. For example, `soaserver1.env.list` and `soaserver2.env.list` for a SOA cluster:
``` bash
MANAGED_SERVER=<Managed Server name, either soa_server1 or soa_server2>
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=<port number where Administration Server is running>
ADMIN_PASSWORD=<admin_password>
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=<port number where Managed Server is running>
```

>IMPORTANT: In the Managed Servers environment variables file, the `MANAGED_SERVER` value must be `soa_server1` or `soa_server2` for the  `soa` and `soaosb` domain type. Also, `MANAGEDSERVER_PORT` must be `8001` for `soa_server1` or `8002` for `soa_server2`.

Example for `soaserver1.env.list`:
``` bash
MANAGED_SERVER=soa_server1
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=Welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=8001
```

Example for `soaserver2.env.list`:
``` bash
MANAGED_SERVER=soa_server2
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=Welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=8002
```
To start a Docker container for the SOA server (for `soa_server1`), you can use the `docker run` command passing `soaserver1.env.list` with port `8001`.

For example:
``` bash
$ docker run -i -t  --name soams1 --network=SOANet -p 8001:8001  -v $data_volume/SOA:/u01/oracle/user_projects  --env-file ./soaserver1.env.list oracle/soasuite:12.2.1.4 "/u01/oracle/container-scripts/startMS.sh"
```
Similarly, to start a second Docker container for the SOA server (for `soa_server2`), you can use the `docker run` command passing `soaserver2.env.list` with port `8002`.

For example:
``` bash
$ docker run -i -t  --name soams2 --network=SOANet -p 8002:8002  -v $data_volume/SOA:/u01/oracle/user_projects  --env-file ./soaserver2.env.list oracle/soa:12.2.1.4 "/u01/oracle/container-scripts/startMS.sh"
```

> **Note**: Using `-v` reuses the volume created by the Administration Server container.


The following lines indicate when the SOA Managed Server is ready to be used:
``` bash    
INFO: Managed Server is running

INFO: Managed Server has been started
```
Once the Managed Server container is created, you can view the server logs:
``` bash
$ docker logs -f \<Managed Server container name\>
```
### 7. Create Oracle Service Bus Managed Server containers

> **Note**: These steps are required only for the `osb` and `soaosb` domain type.

You can start containers to launch the Oracle Service Bus Managed Servers from the image created.

Create an environment variables file specific to each Managed Server in the cluster in the SOA domain. For example, `osbserver1.env.list` and `osbserver2.env.list` for an Oracle Service Bus cluster:
``` bash
MANAGED_SERVER=<Managed Server name, either osb_server1 or osb_server2>
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=<port number where Administration Server is running>
ADMIN_PASSWORD=<admin_password>
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=<port number where Managed Server is running>
```

>IMPORTANT: In the Managed Servers environment variables file the `MANAGED_SERVER` value must be `osb_server1` or `osb_server2` for the `osb` and `soaosb` domain type. Also, `MANAGEDSERVER_PORT` must be `9001` for `osb_server1` or `9002` for `osb_server2`.

Example for `osbserver1.env.list`:
``` bash
MANAGED_SERVER=osb_server1
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=Welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=9001
```
Example for `osbserver2.env.list`:
```bash
MANAGED_SERVER=osb_server2
DOMAIN_NAME=soainfra
ADMIN_HOST=<Administration Server hostname>
ADMIN_PORT=7001
ADMIN_PASSWORD=Welcome1
MANAGED_SERVER_CONTAINER=true
MANAGEDSERVER_PORT=9002
```

To start a Docker container for the Oracle Service Bus server (for `osb_server1`), you can use the `docker run` command passing `osbserver1.env.list`.

For example:
``` bash
$ docker run -i -t  --name osbms1 --network=SOANet -p 9001:9001  -v $data_volume/SOA:/u01/oracle/user_projects  --env-file ./osbserver1.env.list oracle/soasuite:12.2.1.4 "/u01/oracle/container-scripts/startMS.sh"
```
Similarly, to start a second Docker container for the Oracle Service Bus server (for `osb_server2`), you can use the `docker run` command passing `osbserver2.env.list`.

For example:
``` bash
$ docker run -i -t  --name osbms2 --network=SOANet -p 9002:9002  -v $data_volume/SOA:/u01/oracle/user_projects  --env-file ./osbserver2.env.list oracle/soa:12.2.1.4 "/u01/oracle/container-scripts/startMS.sh"
```
The following lines indicate when the Oracle Service Bus Managed Server is ready to be used: 
``` bash   
INFO: Managed Server is running

INFO: Managed Server has been started
```

Once the Managed Server container is created, you can view the server logs:
``` bash
$ docker logs -f \<Managed Server container name\>
```

### 8. Access the Consoles
Now you can access the following Consoles:

* Administration Server Web Console at http://\<hostname\>:7001/console  with weblogic/Welcome1 credentials.
* EM Console at http://\<hostname\>:7001/em  with weblogic/Welcome1 credentials.
* SOA infra Console at http://\<hostname\>:8001/soa-infra with weblogic/Welcome1 credentials.
* SOA infra Console at http://\<hostname\>:8002/soa-infra with weblogic/Welcome1 credentials.
* Service Bus Console at http://\<hostname\>:7001/servicebus with weblogic/Welcome1 credentials.


> **Note**: `hostname` is the FQDN of the host name where the container is running. Do not use 'localhost' for `ADMIN_HOST`. Use the actual FQDN name of the host as `ADMIN_HOST`.

> **Note**: In a multinode scenario, you cannot access the `SOA Composer` and `BPM Worklist` application URLs from the `soa-infra` application page.

### 9. Clean up the environment

1. Stop and remove all running containers from the node where the container is running:
    ``` bash
    $ docker stop \<container name\>

    $ docker rm \<container name\>
    ```
    where containers are `soadb`, `soaas`, `soams1`, `soams2`, `osbms1` and `osbms2`.

2. Clear the data volume:
    ``` bash
    $ rm -rf $data_volume/SOA/*
    ```
3. Remove the Docker network:
    ``` bash
    $ docker network rm SOANet    
    ```
