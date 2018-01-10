SOA on Docker
=============

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start dockerfiles for SOA 12.2.1.2.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle WebLogic Infrastructure 12.2.1.2.0.

At the end of this configuration there will be 3 containers running : 1) DB Container 2) WLS Admin Server Container 3) WLS Managed Server (SOA Server) Container.
The containers will be connected using a Docker User Defined network 


## Pre-Requisite


## Create a User Defined network


In this configuration creation of a user defined network will enable the communication between the containers just using container names.
User defined network option was preferred over the container linking option as the latter is now deprecated.
For this setup we will use a user defined network using bridge driver.

Create a user defined network using the bridge driver by executing the following command :

   $ docker network create -d bridge <some name>
Sample command ...

    $ docker network create -d bridge SOANet

Mount a host directory as a data volume


Data volumes are designed to persist data, independent of the container’s lifecycle. he default location of the volume in container is under "/var/lib/docker/volumes".
There is an option to mount a directory from your Docker engine’s host into a container as volume. In this project we will use that option for the data volume. 
The volume will be used to store Database datafiles and Weblogic server domain files.
This volume will be created in "/scratch/DockerVolume/SOAVolume/" 

Since the volume is created as "root" user, provide read/write/execute permissions to "oracle" user (by providing permissions to "others"), as all operations inside the container happens with "oracle" user login.

   $ chmod -R 777 /scratch/DockerVolume/SOAVolume

## Database


You need to have a running database container or a database running on any machine. 
The database connection details are required for creating SOA specific RCU schemas while configuring SOA domain. 
While using a 12.2.0.1 CDB/PDB DB, ensure PDB is used to load the schemas. RCU loading on CDB is not supported.

Create an environment file db.env.list

    ORACLE_SID=<DB SID>
    ORACLE_PDB=<PDB ID>
    ORACLE_PWD=<password>
    
Sample Data will look like this...

    ORACLE_SID=soadb
    ORACLE_PDB=soapdb
    ORACLE_PWD=Welcome1
    
The Database 12.2.0.1 container can be started from the GitHub Location. 
Follow the instructions to create a 12.2.0.1 based enterprise edition database.

Sample Command to Start the Database is as follows

     $ docker run --name soadb  --network=SOANet -p 1521:1521 -p 5500:5500 -v /scratch/DockerVolume/SOAVolume/DB:/opt/oracle/oradata --env-file ./db.env.list  oracle/database:12.2.0.1-ee
The above command starts a DB container attaching to a network and mounting a host directory as /opt/oracle/oradata for persistence. 
It maps the containers 1521 adn 5500 port to respective host port such that the services can be accessible outside of localhost.


## SOA Distributable version 12.2.1.3 Docker image Creation and Running

To build a SOA image either you can start from building Oracle JDK and Oracle FMW Infrastrucure image or use the already available Oracle FMW Infrastructure image.
The FMW Infrastructure image is available in the container registry and can be pulled from there. If plan to use available Infrastructure image, skip next two steps and jump to "Building Docker Image for SOA"


## Building Oracle JDK (Server JRE) base image

Download the Oracle Server JRE binary and drop in folder OracleJava/java-8 and build that image.

    $ cd OracleJava/java-8
    $ sh build.sh
NOTE: The files to build JDK image can be found under docker/OracleJava


## Building Oracle FMW Infrastructure Docker Install Image

Download the binary of FMW infrastructure and build the image using "buildDockerImage.sh" script for WebLogic.You need to choose the version as "12.2.1.3" and distribution as "infrastructure".

    $ sh buildDockerImage.sh -v 12.2.1.3 -i
Please refer README.md under docker/OracleFMWInfrastructure for details on how to build FMW Infrastructure image.


## Building Docker Image for SOA

IMPORTANT: you have to download the binary of SOA/OSB/BPM and put it inside dockerfiles/).

To try a sample of a SOA image with a domain configured, follow the steps below:


Make sure you have oracle/soa:12.2.1.3 image built. If not go into dockerfiles and call 

$ sh buildDockerImage.sh -v 12.2.1.3


Verify you now have the image oracle/soa:12.2.1.3 in place with 

$ docker images


IMPORTANT: the resulting images will NOT have a domain pre-configured. But, it has the scripts to create and configure a soa domain while creating a container out of the image.

## Creating a container for AdminServer

Create an environment file adminserver.env.list

    CONNECTION_STRING=<Database Container Name>:<port#>/<ORACLE_PDB>
    RCUPREFIX=<RCU_Prefix>
    DB_PASSWORD=<database_sys_password>
    DB_SCHEMA_PASSWORD=<soa-infra schema password>
    ADMIN_PASSWORD=<admin_password>
    MANAGED_SERVER=<managed servername>
    DOMAIN_TYPE=<soa/osb/bpm>
Sample Data will look like this...

    CONNECTION_STRING=soadb:1521/soapdb
    RCUPREFIX=SOA1
    DB_PASSWORD=Welcome1
    DB_SCHEMA_PASSWORD=Welcome1
    ADMIN_PASSWORD=Welcome1
    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
To start a docker container with a SOA domain and the WebLogic AdminServer call docker run command and pass the above adminserver.env.list file.

A sample docker run command is given below:

     $docker run -i -t  --name soaas --network=SOANet -p 7001:7001  -v /scratch/DockerVolume/SOAVolume/SOA:/u01/oracle/user_projects   --env-file ./adminserver.env.list oracle/soa:12.2.1.3
The options "-i -t" in the above command runs the container in interactive mode and you will be able to see the commands running in the container. 
This includes the command for RCU creation, domain creation and configuration followed by starting the Admin Server. 
Mapping container port 7001 to host port 7001 enables accessing of the Weblogic host outside of the local host.
Connecting to SOANet network enables accessing the DB container by it's name i.e soadb.
This includes the command to tail logs to keep the container up and running.

IMPORTANT: You need to wait till all the above commands are run before you can access the AdminServer Web Console.

## Creating a container for SOA Server

Create an environment file soaserver.env.list with the below details:

    MANAGED_SERVER=<managed server name, For Exp:- soa_server1, osb_server1, bpm_server1>
    DOMAIN_TYPE=<soa/osb/bpm>
    ADMIN_HOST=<Admin host name>
    ADMIN_PORT=<port number where Admin Server is running>
Sample Data will look like this

    MANAGED_SERVER=soa_server1
    DOMAIN_TYPE=soa
    ADMIN_HOST=slc09cwi.us.oracle.com
    ADMIN_PORT=7001
To start a docker container for SOA server you can simply call docker run command and passing soaserver.env.list. 

A sample docker run command is given below:

    $ docker run -i -t  --name soams --network=SOANet -p 8001:8001   --volumes-from soaas   --env-file ./soaserver.env.list oracle/soa:12.2.1.3 "/u01/oracle/dockertools/startMS.sh"
    
Using --volumes-from reuses the volume created by the Admin container.
This includes the command to tail logs to keep the container up and running.

IMPORTANT: You need to wait till all the above commands are run before you can start Admin and SOA Servers.

Once the SOA container is created logs will be tailed and displayed to keep the container running.

Now you can access the AdminServer Web Console at http://:7001/console  with weblogic/Welcome1 credentials.

Now you can access the EM Console at http://:7001/em  with weblogic/Welcome1 credentials.

Now you can access the SOA infra Console at http://:8001/soa-infra with weblogic/Welcome1 credentials.

Now you can access the Service Bus Console at http://:7001/servicebus with weblogic/Welcome1 credentials.


License

To download and run SOA 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that pge.

All scripts and files hosted in this project and GitHub docker-images repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.


Copyright

Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
