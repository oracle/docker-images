SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for Oracle SOA 12.2.1.3.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle Fusion Middleware Infrastructure 12.2.1.3.0.

At the end of this configuration there may be 3 containers running: 
1. Oracle Database Container (Optional: only when RCU schema is created in a database running in a container) 
2. Oracle Weblogic Administration Server Container 
3. Oracle Weblogic Managed Server Container (Oracle SOA Server or Oracle Service Bus Server)

The containers will be connected using a Docker User Defined network. 

## Create a User Defined network

In this configuration creation of a user defined network will enable the communication between the containers just using container names. For this setup we will use a user defined network using bridge driver.

Create a user defined network using the bridge driver by executing the following command :

    $ docker network create -d bridge <some name>
   
Sample command:

    $ docker network create -d bridge SOANet

# Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. The default location of the volume in container is under `/var/lib/docker/volumes`. There is an option to mount a directory from the host into a container as volume. In this project we will use that option for the data volume. The volume will be used to store Database datafiles and WebLogic Server domain files. This volume will be created on the host at `/u01/DockerVolume/SOAVolume/`. Since the volume is created as "root" user, provide read/write/execute permissions to "oracle" user (by providing permissions to "others"), as all operations inside the container happens with "oracle" user login.

To determine if a user already exists on your host system with uid:gid of 1000, run:

    # getent passwd 1000

If that returns a username (which is the first field), you can skip the below useradd command. If not, create the `oracle` user manually. 

    # useradd -u 1000 -g 1000 oracle 

Once the `oracle` user is created, run the following commands as a root user:

    # mkdir -p /u01/DockerVolume/SOAVolume/SOA
    # chown -R 1000:1000 /u01/DockerVolume/SOAVolume/
    # chmod -R 700 /u01/DockerVolume/SOAVolume/

# Database

You need to have a running database container or a database running on any machine. The database connection details are required for creating SOA specific RCU schemas while configuring SOA domain. While using a 12.2.0.1 CDB/PDB DB, ensure PDB is used to load the schemas. RCU loading on CDB is not supported.

Run the database container to host the RCU schemas using below steps. For creating an Oracle Database container that uses data volumes to persist data, refer Oralce Enterprise Database documentation available at `https://container-registry.oracle.com`. 

The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the SOA image to connect to the database running in the container.

     Add to an `db.env.txt` file, the following parameters:

	`DB_SID=soadb`

	`DB_PDB=soapdb`

	`DB_DOMAIN=us.oracle.com`

	`DB_BUNDLE=basic`

	`$ docker run -d --name soadb --network=SOANet -p 1521:1521 -p 5500:5500 --env-file ./db.env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1`

Verify that the database is running and healthy. The `STATUS` field shows `healthy` in the output of `docker ps`.

The database is created with the default password `Oradoc_db1`. To change the database password, you must use `sqlplus`.  To run `sqlplus`, pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a `sqlplus` container with the following command:

	$ docker run -ti --network=SOANet --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@soadb:1521/soadb.us.oracle.com AS SYSDBA

	SQL> alter user sys identified by Welcome1 container=all;


## SOA 12.2.1.3.0 Docker image

You can either build the SOA image with the Dockerfile provided or use the already available Oracle SOA Suite (12.2.1.3.0) image in the [Oracle Container Registry](https://container-registry.oracle.com).

## Creating a container for Administration Server

Start a container to launch the Administration Server from the image created using above steps. The environment variables used to configure the domain are defined in `adminserver.env.list` file. Replace in `adminserver.env.list` the values for the Database and WebLogic passwords. 

Create an environment file adminserver.env.list

    CONNECTION_STRING=<Database Container Name>:<port#>/<ORACLE_PDB>
    RCUPREFIX=<RCU_Prefix>
    DB_PASSWORD=<database_sys_password>
    DB_SCHEMA_PASSWORD=<soa-infra schema password>
    ADMIN_PASSWORD=<admin_password>
    DOMAIN_NAME=soainfra
    DOMAIN_TYPE=<soa/osb>
    ADMIN_HOST=<Administration Server container name or hostname>

>IMPORTANT: DOMAIN_TYPE must be carefully chosen and specified depending on the usecase. It can't be changed once you proceed.
In case of SOASuite domains, the supported Domain types are soa and osb.  
    soa       : Deploys an Oracle SOA Domain  
    osb       : Deploys an OSB Domain (Oracle Service Bus)
    
Sample Data will look like this:

    CONNECTION_STRING=soadb:1521/soapdb.us.oracle.com
    RCUPREFIX=SOA1
    DB_PASSWORD=Welcome1
    DB_SCHEMA_PASSWORD=Welcome1
    ADMIN_PASSWORD=Welcome1
    DOMAIN_NAME=soainfra
    DOMAIN_TYPE=soa
    ADMIN_HOST=soaas
    
To start a docker container with a SOA domain and the WebLogic Administration Server call `docker run` command and pass the above `adminserver.env.list` file.

A sample docker run command is given below:

     $ docker run -i -t  --name soaas --network=SOANet -p 7001:7001  -v /u01/DockerVolume/SOAVolume/SOA:/u01/oracle/user_projects   --env-file ./adminserver.env.list oracle/soa:12.2.1.3.0
     
The options `-i -t` in the above command runs the container in interactive mode and you will be able to see the commands running in the container. This includes the command for RCU creation, domain creation and configuration followed by starting the Administration Server. 

>IMPORTANT: You need to wait till all the above commands are run before you can access the Administration Server Web Console.
>The following lines highlight when the Administration Server is ready to be used:    

`INFO: Admin server is running`

`INFO: Admin server running, ready to start managed server`

The above line indicate that the Administration Server started successfully with the name `soaas`, mapping container port 7001 to host port 7001 enables accessing of the Weblogic host outside of the local host, connecting to SOANet network enables accessing the DB container by it's name i.e soadb.

You can view the Administration Server logs using:

$ docker logs -f \<Administration Server Container Name\> 


## Creating Managed Server containers (SOA and OSB Servers)

You can start containers to launch the Managed Servers (SOA and OSB Servers) from the image created. The environment variables used to run the Managed Server containers are defined below. 

Create an environment variables file specific to each cluster in the SOA domain as described below. For instance `soaserver.env.list` for SOA cluster and `osbserver.env.list` for OSB cluster:

    MANAGED_SERVER=<Managed Server name. Must be either soa_server1 or osb_server1>
    DOMAIN_TYPE=<soa/osb>
    DOMAIN_NAME=soainfra
    ADMIN_HOST=<Administration Server container name Or hostname>
    ADMIN_PORT=<port number where Administration Server is running>
    ADMIN_PASSWORD=<admin_password>

>IMPORTANT: In the Managed Servers environment variables file the MANAGED_SERVER value must be mentioned as soa_server1 for soa domain type and osb_server1 for osb domain type.
 
Sample data for `soaserver.env.list` will look like this:

    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    DOMAIN_NAME=soainfra
    ADMIN_HOST=soaas
    ADMIN_PORT=7001
    ADMIN_PASSWORD=Welcome1

To start a docker container for SOA server (for soa domain type) you can simply call `docker run` command and passing `soaserver.env.list`. 

A sample docker run command is given below:

    $ docker run -i -t  --name soams --network=SOANet -p 8001:8001  --volumes-from soaas  --env-file ./soaserver.env.list oracle/soa:12.2.1.3.0 "/u01/oracle/container-scripts/startMS.sh"
    
Using `--volumes-from` reuses the volume created by the Administration Server container. In the above `docker run` command, `soaas` is the name of the Administration Server container started in the previous step and we must use the same name used for the Administration Server to start the SOA Managed Server. 

>IMPORTANT: You need to wait till all the above commands are run before you can start the SOA Server.

The following lines highlight when the SOA Managed Server is ready to be used:    
`INFO: Managed Server is running`

`INFO: Managed server has been started`

Once the Managed Server container is created, you can view the server logs using:

$ docker logs -f \<Managed Server Container Name\>

Similarly you can start a docker container for OSB server (only in the case of osb domain type) by using `docker run` command and passing `osbserver.env.list`.

Sample data for `osbserver.env.list` will look like this:

    MANAGED_SERVER=osb_server1
    DOMAIN_TYPE=osb
    DOMAIN_NAME=soainfra
    ADMIN_HOST=soaas
    ADMIN_PORT=7001
    ADMIN_PASSWORD=Welcome1

A sample docker run command is given below:

    $ docker run -i -t  --name soams --network=SOANet -p 9001:9001  --volumes-from soaas  --env-file ./osbserver.env.list oracle/soa:12.2.1.3.0 "/u01/oracle/container-scripts/startMS.sh"

>IMPORTANT: Note that the container port used for OSB server (9001) is different from SOA server (8001).

Now you can access

   * AdminServer Web Console at http://\<hostname\>:7001/console  with weblogic/Welcome1 credentials.

   * EM Console at http://\<hostname\>:7001/em  with weblogic/Welcome1 credentials.

   * SOA infra Console at http://\<hostname\>:8001/soa-infra with weblogic/Welcome1 credentials.

   * Service Bus Console at http://\<hostname\>:7001/servicebus with weblogic/Welcome1 credentials.

