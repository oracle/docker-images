Oracle Business Intelligence on Docker
=============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for Oracle Business Intelligence 12.2.1.3.0 based on Oracle Linux 7, Oracle JRE 8 (Server) and Oracle FMW Infrastructure 12.2.1.3.0.

For more information about Oracle Business Intelligence please see the [Oracle Business Intelligence 12.2.1.3.0 Online Documentation](http://docs.oracle.com/middleware/12213/biee/index.html).

The certification of Oracle Business Intelligence on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

The instructions below can also be used to build and run Oracle Business Intelligence 12.2.1.2.0, based on FMW Infrastructure 12.2.1.2.0, by changing 12.2.1.3 to 12.2.1.2 as required. A docker image for Oracle Business Intelligence 12.2.1.4.0, on FMW Infrastructure 12.2.1.3.0, can be built and run by changing 12.2.1.3 to 12.2.1.4 in the commands that follow.

## Database prerequisite

You need to have a running Oracle Database, either in a Docker container or on a host. 
The database connection details are required for creating midtier schemas for use by the BI domain.  The schemas are created automatically when the BI container is started.
 
If using an Oracle CDB/PDB database, ensure PDB is used when creating the schemas. CDB is not supported.

An Oracle Database container can be created from an [OracleDatabase](https://github.com/oracle/docker-images/tree/master/OracleDatabase) image - follow the instructions to create a 12.1 or 12.2 Enterprise Edition database.

For Oracle Business Intelligence 12.2.1.2.0, default installs of Oracle Database 12.2 are not supported - please see [Known Issues](#known-issues).

## Oracle Business Intelligence Docker Image Creation

To build a BI image you start by building the Oracle Java image and then the Oracle FMW Infrastructure image.

### Building the Oracle Java (Server JRE) Image

Download the Oracle Server JRE binary into folder `OracleJava/java-8` and build the image:

        $ cd OracleJava/java-8
        $ docker build -t oracle/serverjre:8 .

Please refer to README.md under [OracleJava](https://github.com/oracle/docker-images/tree/master/OracleJava) for details on how to build Oracle Java image.

### Building the Oracle FMW Infrastructure Image
 
Download the binary of FMW Infrastructure into folder `OracleFMWInfrastructure/dockerfiles/12.2.1.3`.

If a proxy is needed for the host to access yum.oracle.com during build, then first set up the appropriate environment, e.g.:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80
        $ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

Build the image:

        $ cd OracleFMWInfrastructure/dockerfiles
        $ ./buildDockerImage.sh -v 12.2.1.3

Please refer to README.md under [OracleFMWInfrastructure](https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure) for details on how to build FMW Infrastructure image.

### Building the Oracle Business Intelligence Image

Download the two binaries for [Oracle Business Intelligence 12.2.1.3.0](http://www.oracle.com/technetwork/middleware/bi/downloads/default-3852322.html) for Linux x86-64-bit into folder `OracleBI/dockerfiles/12.2.1.3`.

If a proxy is needed for the host to access yum.oracle.com during build, then first set up the appropriate environment, e.g.:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80
        $ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

Build the image:

        $ cd OracleBI/dockerfiles
        $ ./buildDockerImage.sh -v 12.2.1.3

## Creating an Oracle Business Intelligence Container

The BI image provides a script to create and start a single-node BI domain, with the SampleApp Lite application.

This script is invoked when a container is started using the image. If the container is subsequently restarted, then the BI domain is restarted automatically.

The BI image does not support scale-out, or upgrading to any future Oracle Business Intelligence patchset release.

### Starting a new container
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

ORACLE_HOME is fixed to `/u01/oracle`. DOMAIN_HOME is fixed to `/u01/oracle/user_projects/domains/bi`
  
e.g.:

        $ docker run -it -p 9500:9500 -p 9502:9502 -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=<admin_password> -e DB_HOST=database -e DB_PORT=1521 -e DB_SERVICE=ORCLPDB1 -e DB_USERNAME=sys -e DB_PASSWORD=<db_password> -e SCHEMA_PREFIX=DEV -e SCHEMA_PASSWORD=<schema_password> oracle/biplatform:12.2.1.3

(change _<...password>_ to your required values, and DB values to match your database).

On success, the following is logged: `The configuration of Oracle Fusion Middleware completed successfully.`. The script then tails the domain log to stdout.


The following ports are used by the BI domain:
* 9500 - WebLogic AdminServer
* 9502 - WebLogic bi_server1 managed server, hosting BI JEE apps
* 9508 - OBI Cluster Controller, providing access to OBI Server system component
* 9514 - OBI Server system component

The following example URLS provide access to the BI domain:
* http://www.example.com:9500/console - WebLogic Admin Console
* http://www.example.com:9502/analytics - BI Answers/Dashboards
* http://www.example.com:9502/va - Data Visualisation
* http://www.example.com:9502/xmlpserver - BI Publisher

If access to the OBI Server component is required, e.g. by the BI Administration Tool, then port 9514 must be exposed and the previous `docker run` command should be modified

e.g.:

        $ docker run -it -p 9500:9500 -p 9502:9502 -p 9514:9514 -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=<admin_password> -e DB_HOST=database -e DB_PORT=1521 -e DB_SERVICE=ORCLPDB1 -e DB_USERNAME=sys -e DB_PASSWORD=<db_password> -e SCHEMA_PREFIX=DEV -e SCHEMA_PASSWORD=<schema_password> oracle/biplatform:12.2.1.3


### Using a host directory for persistent data

In the basic usage above, persistent data in DOMAIN_HOME, APPLICATIONS_DIR and SINGLETON_DATA_DIRECTORY is stored within the container.  If the container is deleted, the data is lost.

A data volume for `/u01/oracle/user_projects` can be used to store persistent data on the host disk. For instance, to mount a host directory as a data volume:

        $ mkdir -p /scratch/bi && chmod 777 /scratch/bi
        $ docker run -v /scratch/bi:/u01/oracle/user_projects ......

The chmod is necessary as the container's processes are run under user 'oracle'.

### Using a database container

In the above example, `DB_HOST` specifies the hostname for the database instance.  If a database container is used, then a docker user-defined network must be set up as a pre-requisite, or the legacy `--link` feature used.

For instance, create a user-defined network using the bridge driver:

        $ docker network create -d bridge bi_net
        
Then start a database container using the above network:

        $ docker run --name database --network=bi_net ...... oracle/database:12.1.0.2-ee

Then start a BI container that uses the database by name:

        $ docker run --name bi --network=bi_net -e DB_HOST=database ...... oracle/biplatform:12.2.1.3

(in the above docker run examples other parameters are omitted for clarity).

### Passing configuration environment by mounted file or docker secrets

The domain creation script also supports loading the same set of environment key/value pairs from files mounted into the container, via `docker run /v` or docker secrets.

The following files are processed if available, overriding any environment already set:
* For ADMIN_USERNAME/ADMIN_PASSWORD: `/run/secrets/admin.txt` 
* For DB_USERNAME/DB_PASSWORD: `/run/secrets/db.txt`
* For SCHEMA_PASSWORD: `/run/secrets/schema.txt`
* For providing all keys: `/run/secrets/config.txt`

Each *.txt file must contain lines of `key=value` pairs.

### Using docker compose

The BI image supports using docker compose to start the BI and DB containers together.

In this mode, the containers are started in parallel and the BI container must wait for the DB to become available.  The wait is enabled by setting environment `DB_WAIT_TIMEOUT` to the maximum number of seconds to wait, e.g. in your `docker-compose.yml`, add:

        environment:
          - DB_WAIT_TIMEOUT=240

## Known Issues

1. The domain's nodemanager is configured to listen on the network interface for the container's original hostname, rather than on all interfaces.  Therefore if you create a new container using an existing data volume for /u01/oracle/user_projects, you must ensure the same hostname is used, e.g.

        $ docker run --hostname original_hostname ......

2. Oracle Business Intelligence 12.2.1.2.0 configuration fails against default Oracle Database 12.2, with obips1, obisch1 and obis1 system components failing to start.  This is due to incompatible logon version from the ODBC drivers. To workaround, include the following within the DB server's `sqlnet.ora`:

        SQLNET.ALLOWED_LOGON_VERSION_SERVER=11
    For further information, see [Oracle Database Net Services Reference](http://docs.oracle.com/database/122/NETRF/parameters-for-the-sqlnet-ora-file.htm#GUID-1FA9D26C-4D97-4D1C-AB47-1EC234D924AA).

3. Oracle Business Intelligence 12.2.1.3.0 configuration validation fails if the database hostname contains an underscore.

4. If the container is restarted, it requires the same set of environment variables passed in again, even though the domain has already been created.

5. Docker health-check is not implemented.

6. Oracle Business Intelligence R Installer will fail as `make` is not installed.

  Prior to running `RInstaller.sh installpackages`, first run `yum install -y make`, setting `http_proxy` if required.

  Note that `RInstaller.sh` needs to be run as root - this can be done by `docker exec -it -u root bi bash`.

  For further information on R installation, please see [Oracle Fusion Middleware Installing and Configuring Oracle Business Intelligence](https://docs.oracle.com/middleware/12213/lcm/BIEIG/GUID-9094BFE3-0B41-40AD-83F5-23E0A2D7229F.htm#BIEIG-GUID-9094BFE3-0B41-40AD-83F5-23E0A2D7229F).

## License

To download and run Oracle Business Intelligence 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [docker/OracleBI](./) repository required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

## Copyright

Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

