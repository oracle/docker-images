Oracle Enterprise Data Quality on Docker
========================================
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for Enterprise Data Quality 12.2.1.3.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle FMW Infrastructure 12.2.1.3.0.

For more information about Oracle Enterprise Data Quality please see the [Oracle Enterprise Data Quality 12.2.1.3.0 Online Documentation]( http://www.oracle.com/technetwork/middleware/oedq/documentation/index.html).

The certification of Oracle Enterprise Data Quality on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## Database prerequisite

You need to have a running Oracle Database, either in a Docker container or on a host. 
The database connection details are required for creating midtier schemas for use by the EDQ domain.  The schemas are created automatically when the EDQ container is started.
 
If using a 12.1.0.2 CDB/PDB database, ensure PDB is used when creating the schemas. CDB is not supported.

An Oracle Database 12.1.0.2 container can be created from [OracleDatabase](https://github.com/oracle/docker-images/tree/master/OracleDatabase/dockerfiles/12.1.0.2). 
Follow the instructions to create a 12.1.0.2-based Enterprise Edition database.

Default installs of Oracle Database 12.2 are not supported - please see [Known Issues](#known-issues).

## Oracle Enterprise Data Quality Docker Image Creation

To build a EDQ image you start by building Oracle Java 8(Server JRE) and Oracle FMW Infrastructure images.

### Building the Oracle Java 8(Server JRE) Image

Download the Oracle Server JRE binary into folder `OracleJava/java-8` and build the image:

        $ cd OracleJava/java-8
        $ docker build -t oracle/serverjre:8 .

Please refer to README.md under [OracleJava](https://github.com/oracle/docker-images/tree/master/OracleJava) for details on how to build Oracle Java image.

### Building the Oracle FMW Infrastructure Image
 
Download the binary of FMW Infrastructure into folder `OracleFMWInfrastructure/dockerfiles/12.2.1.3` and build the 12.2.1.3 infrastructure image:

        $ cd OracleFMWInfrastructure/dockerfiles
        $ ./buildDockerImage.sh -v 12.2.1.3

Please refer to README.md under [OracleFMWInfrastructure](https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure) for details on how to build FMW Infrastructure image.

### Building the Oracle Enterprise Data Quality Image

Download the two binaries for [Oracle Enterprise Data Quality 12.2.1.3.0]( http://www.oracle.com/technetwork/middleware/oedq/downloads/index.html) for Linux x86-64-bit into folder `OEDQ/dockerfiles/12.2.1.3.0`.

If a proxy is needed for the host to access yum.oracle.com during build, then first set up the appropriate environment, e.g.:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80

Build the image:

        $ cd OEDQ/dockerfiles
        $ ./buildDockerImage.sh -v 12.2.1.3.0

## Creating an Oracle Enterprise Data Quality Container

The OEDQ image provides a script to create a OEDQ domain, with the Director application.

This script is invoked when a container is started using the image. If the container is subsequently restarted, then the OEDQ domain is restarted automatically.

### Starting a new EDQ container
The following variables are mandatory when starting the container:
* ADMIN_USERNAME - WebLogic admin username for the new domain
* ADMIN_PASSWORD - WebLogic admin password
* DB_HOST - Host name for database into which new schemas will be created
* DB_PORT - Database listener port
* DB_SERVICE - Database instance service name
* DB_USERNAME - Database sysdba username
* DB_PASSWORD - Database sysdba password
* SCHEMA_PREFIX - Schema prefix for new schemas for the new domain. This must not already be in use, otherwise domain creation will fail.
* SCHEMA_PASSWORD - Password for all new schemas created

ORACLE_HOME is fixed to `/u01/oracle`. 
DOMAIN_HOME is fixed to ` $HOST_VOLUME: /u01/oracle/user_projects/domains/base_domain`
Where HOST_VOLUME  stands for a directory on the host where you map your domain directory and both the Admin Server and Managed Server containers can read/write to.
DB_HOST - Host name for database into which new schemas will be created
DB_PORT - Database listener port 
DB_SERVICE - Database instance service name
RCUPREFIX - Schema prefix for new schemas for the new domain. This must not already be in use, otherwise domain creation will fail.
DB_PASSWORD - Database sysdba password

DB_SCHEMA_PASSWORD- Password for all new schemas created
DOMAIN_PASSWORD= WebLogic admin username for the new domain

Note: Grant read, write and execute permission to all for /scratch/xyz directory

e.g.:

        $ docker run --name EDQAS -it -p 7001:7001 --env-file ./12.2.1.3.0/edq.db_env.list -v /scratch/xyz:/u01/oracle/user_projects oracle/edq:12.2.1.3.0

On success, the following is logged: `The configuration of Oracle Fusion Middleware completed successfully.`. The script then tails the domain log to stdout.


### Starting another container to Start EDQ Managed Server

Start a container to launch the Managed Server from the image created in prior step  The environment variables used to run the Managed Server image are, 

ADMIN_HOST=<host name> - Admin Server Hostname, Ex: localhost
ADMIN_PORT=7010

To run a Managed Server container call:

e.g.:
        $ docker run -ti --name EDQMS -p 8001:8001 -e ADMIN_HOST=AdminHostName -e ADMIN_PORT=7010 --volumes-from EDQAS oracle/edq:12.2.1.3.0 startManagedServer.sh




The following default ports are used by the EDQ domain:
* 7001 - WebLogic AdminServer
* 8001 - WebLogic edq_server1 managed server

The following URLS provide access to the EDQ domain:
* http://<yourhost>:7001/console - WebLogic Admin Console
* http://<yourhost>:8001/edq - EDQ Launchpad
