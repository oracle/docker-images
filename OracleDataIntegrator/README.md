ODI on Docker
=============
Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This project includes quick start [dockerfiles](dockerfiles/) for ODI 12.2.1.2.6 based on Oracle Linux 7, Oracle JRE 8 (Server).

At the end of this configuration there will be 2 containers running : 1) DB Container 2) ODI Agent.
The containers will be connected using a Docker User Defined network 

## Pre-Requisite

1. Mount a host directory as a data volume

Data volumes are designed to persist data, independent of the container’s lifecycle. he default location of the volume in container is under "/var/lib/docker/volumes".
There is an option to mount a directory from your Docker engine’s host into a container as volume. In this project we will use that option for the data volume. 
The volume will be used to store Database datafiles and ODI domain files.

Since the volume is created as "root" user, provide read/write/execute permissions to "oracle" user (by providing permissions to "others"), as all operations inside the container happens with "oracle" user login.
       $ mkdir /scratch/DockerVolume/ODIVolume/DB
       $ mkdir /scratch/DockerVolume/ODIVolume/ODI
       $ chmod -R 777 /scratch/DockerVolume/ODIVolume

2. Database

You need to have a running database container or a database running on any machine. 
The database connection details are required for creating ODI specific RCU schemas while configuring ODI domain. 
While using a 12.2.0.1 CDB/PDB DB, ensure PDB is used to load the schemas. RCU loading on CDB is not supported.

The Oracle Database image can be pulled from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com) or you can build your own using the Dockerfiles and scripts in [GitHub Location](https://github.com/oracle/docker-images/tree/master/OracleDatabase/dockerfiles/12.2.0.1)

Create an environment file **db.env.list**

        ORACLE_SID=<DB SID>
        ORACLE_PDB=<PDB ID>
        ORACLE_PWD=<password>
        
Sample Data will look like this...

	ORACLE_SID=odidb
        ORACLE_PDB=odipdb
        ORACLE_PWD=Welcome1
        
Sample Command to Start the Database is as follows

         $ docker run --name ODI122126Database  -p 1521:1521 -p 5500:5500 -v /scratch/DockerVolume/ODIVolume/DB:/opt/oracle/oradata --env-file ./db.env.list  oracle/database:12.2.0.1-ee

The above command starts a DB container attaching to a network and mounting a host directory as /opt/oracle/oradata for persistence. 
It maps the containers 1521 adn 5500 port to respective host port such that the services can be accessible outside of localhost.

## ODI Distributable version 12.2.1.2.6 Docker image Creation and Running

To build a ODI image either you can start from building Oracle JDK or use the already available Oracle JDK image.
The Oracle JDK  image is not currently available.
If plan to use available Oracle JDK image, skip next steps and jump to "Building Docker Image for ODI"

### Building Oracle JDK (Server JRE) base image

Oracle Server JRE image can be pulled from the [Docker Store](https://store.docker.com/images/oracle-serverjre-8) or the [Oracle Container Registry](https://container-registry.oracle.com) or you can build your own using the Dockerfiles and scripts in [GitHub Location](https://github.com/oracle/docker-images/tree/master/OracleJava/java-8). For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

### Building Docker Image for ODI

**IMPORTANT:** you have to download the binary of ODI and put it in place (see `.download` files inside dockerfiles/<version>).


To try a sample of a ODI image with a domain configured, follow the steps below:

  1. Make sure you have **oracle/odi:12.2.1.2.6** image built. If not go into **dockerfiles** and call 

        $ sh buildDockerImage.sh -v 12.2.1.2.6

  2. Verify you now have the image **oracle/odi:12.2.1.2.6** in place with 

        $ docker images

**IMPORTANT:** the resulting images will NOT have a domain pre-configured. But, it has the scripts to create and configure a odi domain while creating a container out of the image.


### Creating ODI container

Create an environment file **odi.env.list**

        CONNECTION_STRING=<Database Container Name>:<port#>/<ORACLE_PDB>
        RCUPREFIX=<RCU_Prefix>
        DB_PASSWORD=<database_password>
        DB_SCHEMA_PASSWORD=<RCU schema Password>
        SUPERVISOR_PASSWORD=<Password for SUPERVISOR>
        WORK_REPO_NAME=<Name for WORK repository>
        WORK_REPO_PASSWORD=<Password for WORK repository>
        HOST_NAME=<Hostname where docker is running>
        
        
Sample Data will look like this...

        CONNECTION_STRING=ODI122126Database:1521/odipdb
        RCUPREFIX=ODI1
        DB_PASSWORD=Welcome1
        DB_SCHEMA_PASSWORD=Welcome1
        SUPERVISOR_PASSWORD=Welcome1
        WORK_REPO_NAME=WORKREP
        WORK_REPO_PASSWORD=Welcome1
        HOST_NAME=<Hostname where docker is running>

To start a docker container with a ODI domain and Agent, call docker run command and pass the above odi.env.list file.

A sample docker run command is given below:

         $ docker run -t -i --name ODIContainer --env-file ./odi.env.list -v /scratch/DockerVolume/ODIVolume/ODI:/u01/oracle/user_projects -p 20910:20910 oracle/odi:12.2.1.2.6

The options "-i -t" in the above command runs the container in interactive mode and you will be able to see the commands running in the container. 
This includes the command for RCU creation, domain creation and configuration followed by starting ODI Agent. 
Mapping container port 21910 to host port 21910 enables accessing of the Agent outside of the local host.
Connecting to ODINet network enables accessing the DB container by it's name i.e ODI122126Database. If not using ODINet then hostname where DB is runnings needs to given in place of ODI122126Database in odi.env.list

Once the ODI container is created logs will be tailed and displayed to keep the container running.

Now you can access the Agent at http://<host name>:20910/oraclediagent 
         
**NOTES:** 

1) If DB_SCHEMA_PASSWORD, SUPERVISOR_PASSWORD, WORK_REPO_PASSWORD are not provided in odi.env.list then it will generate random password and use it while running RCU. It will display generated random password on console. If you need to find the passwords at a later time, grep for "password" in the Docker logs generated during the startup of the  container.  To look at the Docker Container logs run:

        $ docker logs --details <Container-id>


2) 12.2.1.2.6 Studio is required to be used in conjunction with docker image for ODI 12.2.1.2.6

3) ODI 12.2.1.2.6 docker image supports only Oracle Database as the repository database. 

4) For all other supported matrix information, please refer to ODI 12.2.1.2.6 documentation. The supported database for repository mentioned above supersede the configuration matrix for ODI 12.2.1.2.6

5) As a pre-requisite, "Maximum number of sessions" field needs to be Overwritten in Studio UI for the Agent created by the ODI Container. Post docker configuration, "Maximum number of sessions" is set as null in the repository database, but the Studio UI  render 1000 as the default value set. User is required  to explicitly overwrite the "Maximum number of sessions"  value to force an update in the repository. If this step is not performed, all sessions will continue to wait in the queue and will not be processed.

     Steps to Overwrite the "Maximum number of sessions"  Value in Studio UI

       • Login to ODI Studio
       • In Topology Navigator expand the Agents node in the Physical Architecture navigation tree
       • Select the Agent created by the ODI Container
       • Right-click and select View
       • In the Definition tab, for the field “Maximum number of sessions”, overwrite the value again to 5 and click Save button. Then again overwrite the value to 1000 and click Save button.



