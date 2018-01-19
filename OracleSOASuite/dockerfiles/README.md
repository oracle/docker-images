SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for SOA 12.2.1.2.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle WebLogic Infrastructure 12.2.1.2.0.

At the end of this configuration there will be 3 containers running : 1) DB Container 2) WLS Admin Server Container 3) WLS Managed Server (SOA Server) Container.
The containers will be connected using a Docker User Defined network 


## Pre-Requisite


## Create a User Defined network


In this configuration creation of a user defined network will enable the communication between the containers just using container names. User defined network option was preferred over the container linking option as the latter is now deprecated.
For this setup we will use a user defined network using bridge driver.

Create a user defined network using the bridge driver by executing the following command :

    $ docker network create -d bridge <some name>
   
Sample command:

    $ docker network create -d bridge SOANet


# Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. The default location of the volume in container is under `/var/lib/docker/volumes`. There is an option to mount a directory from the host into a container as volume. In this project we will use that option for the data volume. The volume will be used to store Database datafiles and Weblogic server domain files.This volume will be created on the host at `/scratch/DockerVolume/SOAVolume/`. Since the volume is created as "root" user, provide read/write/execute permissions to "oracle" user (by providing permissions to "others"), as all operations inside the container happens with "oracle" user login.

    $ chmod -R 777 `/scratch/DockerVolume/SOAVolume`

**Database**

You need to have a running database container or a database running on any machine. The database connection details are required for creating SOA specific RCU schemas while configuring SOA domain. While using a 12.2.0.1 CDB/PDB DB, ensure PDB is used to load the schemas. RCU loading on CDB is not supported.

Please refer README.md under docker/OracleDatabase for details on how to build Oracle Database image.
https://github.com/oracle/docker-images/tree/master/OracleDatabase


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


## SOA Distributable version 12.2.1.3 Docker image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle FMW Infrastrucure image or use the already available Oracle FMW Infrastructure image. The FMW Infrastructure image is available in the Oracle Container Registry and can be pulled from there. If you plan to use the Oracle FMW Infrastructure image from the Oracle Container Registry, you can skip the next two steps and continue with "Building a Docker Image for SOA".


## Building Oracle JDK (Server JRE) base image

Please refer README.md under docker/OracleJava for details on how to build Oracle Database image.

https://github.com/oracle/docker-images/tree/master/OracleJava


## Building Oracle FMW Infrastructure Docker Install Image

Please refer README.md under docker/OracleFMWInfrastructure for details on how to build Oracle FMW Infrastructure image.

https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure



## Building Docker Image for SOA

IMPORTANT: To build the SOA image, you must first download the Oracle SOA Suite 12.2.1.3 binary and drop in folder `../OracleSOASuite/dockerfiles/12.2.1.3`. The binaries can be downloaded from the Oracle Software Delivery Cloud (https://edelivery.oracle.com). Search for "Oracle SOA Suite" and "Oracle Service Bus", download fmw_12.2.1.3.0_soa.jar and fmw_12.2.1.3.0_osb.jar and drop it under `dockerfiles/12.2.1.3`. 

* [Oracle Software Delivery Cloud](https://edelivery.oracle.com)

$ sh buildDockerImage.sh -v 12.2.1.3

   Usage: buildDockerImage.sh -v [version]
   Builds a Docker Image for Oracle SOA Suite.


Verify you now have the image `oracle/soa:12.2.1.3` in place with 

$ docker images


IMPORTANT: the resulting images will NOT have a domain pre-configured. But, it has the scripts to create and configure a soa domain while creating a container out of the image.

## Creating a container for AdminServer

Start a container to launch the Admin Server from the image created using above steps. The environment variables used to configure the domain are defined in adminserver.env.list file. Replace in adminserver.env.list the values for the Database and WebLogic passwords. 

Create an environment file adminserver.env.list

    CONNECTION_STRING=<Database Container Name>:<port#>/<ORACLE_PDB>
    RCUPREFIX=<RCU_Prefix>
    DB_PASSWORD=<database_sys_password>
    DB_SCHEMA_PASSWORD=<soa-infra schema password>
    ADMIN_PASSWORD=<admin_password>
    MANAGED_SERVER=<managed servername>
    DOMAIN_TYPE=<soa/osb/bpm>
    
Sample Data will look like this:

    CONNECTION_STRING=soadb:1521/soapdb
    RCUPREFIX=SOA1
    DB_PASSWORD=Welcome1
    DB_SCHEMA_PASSWORD=Welcome1
    ADMIN_PASSWORD=Welcome1
    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    
To start a docker container with a SOA domain and the WebLogic AdminServer call `docker run command` and pass the above `adminserver.env.list` file.

A sample docker run command is given below:

     $docker run -i -t  --name soaas --network=SOANet -p 7001:7001  -v /scratch/DockerVolume/SOAVolume/SOA:/u01/oracle/user_projects   --env-file ./adminserver.env.list oracle/soa:12.2.1.3
     
The options "-i -t" in the above command runs the container in interactive mode and you will be able to see the commands running in the container. This includes the command for RCU creation, domain creation and configuration followed by starting the Admin Server. 

IMPORTANT: You need to wait till all the above commands are run before you can access the AdminServer Web Console.
The following lines highlight when the Admin server is ready to be used:    

INFO: Admin server is running
INFO: Admin server running, ready to start managed server

The above line indicate the admin server started successfully with the name `soaas`, mapping container port 7001 to host port 7001 enables accessing of the Weblogic host outside of the local host, connecting to SOANet network enables accessing the DB container by it's name i.e soadb. This includes the command to tail logs to keep the container up and running.


## Creating a container for SOA Server

Start a container to launch the Managed Server from the image created. The environment variables used to run the Managed Server image are defined in the file soaserver.env.list. 

Create an environment file soaserver.env.list with the below details:

    MANAGED_SERVER=<managed server name, For Exp:- soa_server1, osb_server1, bpm_server1>
    DOMAIN_TYPE=<soa/osb/bpm>
    ADMIN_HOST=<Admin host name>
    ADMIN_PORT=<port number where Admin Server is running>
    
Sample Data will look like this:

    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    ADMIN_HOST=slc09cwi.us.oracle.com
    ADMIN_PORT=7001
    
To start a docker container for SOA server you can simply call `docker run` command and passing `soaserver.env.list`. 

A sample docker run command is given below:

    $ docker run -i -t  --name soams --network=SOANet -p 8001:8001   --volumes-from soaas   --env-file ./soaserver.env.list oracle/soa:12.2.1.3 "/u01/oracle/dockertools/startMS.sh"
    
Using --volumes-from reuses the volume created by the Admin container. In the above `docker run` command, `soaas` is the name of the Admin server container started in the previous step and we must use the same name used for the AdminServer to start the SOA managed server. 

This includes the command to tail logs to keep the container up and running.

IMPORTANT: You need to wait till all the above commands are run before you can start the SOA Server.

The following lines highlight when the SOA managed server is ready to be used:    
INFO: Managed Server is running
INFO: Managed server has been started

Once the SOA container is created logs will be tailed and displayed to keep the container running.

Now you can access

   * AdminServer Web Console at http://<hostname>:7001/console  with weblogic/Welcome1 credentials.

   * EM Console at http://<hostname>:7001/em  with weblogic/Welcome1 credentials.

   * SOA infra Console at http://<hostname>:8001/soa-infra with weblogic/Welcome1 credentials.

   * Service Bus Console at http://<hostname>:7001/servicebus with weblogic/Welcome1 credentials.


License

To download and run SOA 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub docker-images/OracleDatabase repository required to build the Docker images are, unless otherwise noted, released under UPL 1.0 license.


Copyright

Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
