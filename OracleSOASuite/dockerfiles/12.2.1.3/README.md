SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for Oracle SOA 12.2.1.3.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle Fusion Middleware Infrastructure 12.2.1.3.0.

At the end of this configuration there may be 3 containers running: 
1. Oracle Database Container (Only when container based Database is used)
2. Oracle Weblogic Admin Server Container 
3. Oracle Weblogic Managed Server Container (SOA Server)

The containers will be connected using a Docker User Defined network 

## Create a User Defined network

In this configuration creation of a user defined network will enable the communication between the containers just using container names. For this setup we will use a user defined network using bridge driver.

Create a user defined network using the bridge driver by executing the following command :

    $ docker network create -d bridge <some name>
   
Sample command:

    $ docker network create -d bridge SOANet

# Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. The default location of the volume in container is under `/var/lib/docker/volumes`. There is an option to mount a directory from the host into a container as volume. In this project we will use that option for the data volume. The volume will be used to store Database datafiles and WebLogic Server domain files. This volume will be created on the host at `/scratch/DockerVolume/SOAVolume/`. Since the volume is created as "root" user, provide read/write/execute permissions to "oracle" user (by providing permissions to "others"), as all operations inside the container happens with "oracle" user login.

To determine if a user already exists on your host system with uid:gid of 1000, run:

    # getent passwd 1000

If that returns a username (which is the first field), use that user for the `useradd` command below. If not, create the `oracle` user manually. 

    # useradd -u 1000 -g 1000 oracle 

Run the following commands as root:

    # mkdir -p /scratch/DockerVolume/SOAVolume/
    # chown 1000:1000 /scratch/DockerVolume/SOAVolume/
    # chmod 700 /scratch/DockerVolume/SOAVolume/

# Database

You need to have a running database container or a database running on any machine. The database connection details are required for creating SOA specific RCU schemas while configuring SOA domain. While using a 12.2.0.1 CDB/PDB DB, ensure PDB is used to load the schemas. RCU loading on CDB is not supported.

Please refer [README.md](https://github.com/oracle/docker-images/blob/master/OracleDatabase/README.md) under docker/OracleDatabase for details on how to build Oracle Database image.

The DB image created through above step need to be retagged from `container-registry.oracle.com/oracle/database:12.2.0.1-ee`  to `oracle/database:12.2.0.1-ee` before continuing with next steps.

$ docker tag container-registry.oracle.com/oracle/database:12.2.0.1-e  oracle/database:12.2.0.1-ee

## Running Oracle Database in a Docker container

Create an environment file db.env.list

    ORACLE_SID=<DB SID>
    ORACLE_PDB=<PDB ID>
    ORACLE_PWD=<password>
    
Sample Data will look like this:

    ORACLE_SID=soadb
    ORACLE_PDB=soapdb
    ORACLE_PWD=Welcome1

Sample Command to Start the Database is as follows

     $ docker run --name soadb  --network=SOANet -p 1521:1521 -p 5500:5500 -v /scratch/DockerVolume/SOAVolume/DB:/opt/oracle/oradata --env-file ./db.env.list  oracle/database:12.2.0.1-ee
     
The above command starts a DB container attaching to a network and mounting a host directory as `/opt/oracle/oradata` for persistence. 
It maps the containers 1521 and 5500 port to respective host port such that the services can be accessible outside of localhost.


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
    MANAGED_SERVER=<Managed Server name>
    DOMAIN_TYPE=<soa/osb/soaosb/soaess/soaessosb/bpm>
    
Sample Data will look like this:

    CONNECTION_STRING=soadb:1521/soapdb
    RCUPREFIX=SOA1
    DB_PASSWORD=Welcome1
    DB_SCHEMA_PASSWORD=Welcome1
    ADMIN_PASSWORD=Welcome1
    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    
To start a docker container with a SOA domain and the WebLogic Administration Server call `docker run` command and pass the above `adminserver.env.list` file.

A sample docker run command is given below:

     $docker run -i -t  --name soaas --network=SOANet -p 7001:7001  -v /scratch/DockerVolume/SOAVolume/SOA:/u01/oracle/user_projects   --env-file ./adminserver.env.list oracle/soa:12.2.1.3.0
     
>IMPORTANT: the resulting images will NOT have a domain pre-configured. But, it has the scripts to create and configure a soa domain >while creating a container out of the image.
     
The options `-i -t` in the above command runs the container in interactive mode and you will be able to see the commands running in the container. This includes the command for RCU creation, domain creation and configuration followed by starting the Administration Server. 

>IMPORTANT: You need to wait till all the above commands are run before you can access the Administration Server Web Console.
>The following lines highlight when the Administration Server is ready to be used:    

`INFO: Admin server is running`

`INFO: Admin server running, ready to start managed server`

The above line indicate that the Administration Server started successfully with the name `soaas`, mapping container port 7001 to host port 7001 enables accessing of the Weblogic host outside of the local host, connecting to SOANet network enables accessing the DB container by it's name i.e soadb. This includes the command to tail logs to keep the container up and running.


## Creating a container for SOA Server

Start a container to launch the Managed Server from the image created. The environment variables used to run the Managed Server image are defined in the file `soaserver.env.list`. 

Create an environment file `soaserver.env.list` with the below details:

    MANAGED_SERVER=<Managed Server name, For Exp:- soa_server1, osb_server1, bpm_server1>
    DOMAIN_TYPE=<soa/osb/bpm>
    ADMIN_HOST=<Admin host name>
    ADMIN_PORT=<port number where Administration Server is running>
    ADMIN_PASSWORD=<admin_password>
 
Sample Data will look like this:

    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    ADMIN_HOST=host.domain.com
    ADMIN_PORT=7001
    ADMIN_PASSWORD=Welcome1
    
To start a docker container for SOA server you can simply call `docker run` command and passing `soaserver.env.list`. 

A sample docker run command is given below:

    $ docker run -i -t  --name soams --network=SOANet -p 8001:8001   --volumes-from soaas   --env-file ./soaserver.env.list oracle/soa:12.2.1.3.0 "/u01/oracle/dockertools/startMS.sh"
    
Using `--volumes-from` reuses the volume created by the Administration Server container. In the above `docker run` command, `soaas` is the name of the Administration Server container started in the previous step and we must use the same name used for the Administration Server to start the SOA Managed Server. 

This includes the command to tail logs to keep the container up and running.

>IMPORTANT: You need to wait till all the above commands are run before you can start the SOA Server.

The following lines highlight when the SOA Managed Server is ready to be used:    
`INFO: Managed Server is running`

`INFO: Managed server has been started`

Once the SOA container is created logs will be tailed and displayed to keep the container running.

Now you can access

   * AdminServer Web Console at http://<hostname>:7001/console  with weblogic/Welcome1 credentials.

   * EM Console at http://<hostname>:7001/em  with weblogic/Welcome1 credentials.

   * SOA infra Console at http://<hostname>:8001/soa-infra with weblogic/Welcome1 credentials.

   * Service Bus Console at http://<hostname>:7001/servicebus with weblogic/Welcome1 credentials.
