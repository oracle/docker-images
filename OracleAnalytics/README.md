Oracle Analytics Server on Container
=============
Sample container configurations facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) for Oracle Analytics Server 2022 (6.4) based on Oracle Linux 7, Oracle JRE 8 (Server), and Oracle Fusion Middleware Infrastructure 12.2.1.4.0.

For more information about Oracle Analytics Server, see the [Oracle Analytics Server Online Documentation](https://docs.oracle.com/en/middleware/bi/analytics-server/index.html).

The certification of Oracle Analytics Server on Container doesn't require the use of any file presented in this repository. Customers and users are welcome to use them as starter templates to customize or tweak, or to create scripts and Docker files from scratch.

For pre-built images containing Oracle software, check the [Oracle Container Registry](https://container-registry.oracle.com).

## Database Prerequisites

You must have a running Oracle Database, either in a container or on a host. 
You need these database connection details to create midtier schemas for the BI domain. The schemas are created automatically when the BI container starts.
 
If you're using an Oracle multitenant container database (CDB) or pluggable database (PDB) database, you must use PDB when creating the schemas because CDB isn’t supported.

You can create an Oracle Database container by using an [OracleDatabase](https://github.com/oracle/docker-images/tree/master/OracleDatabase) image. Follow these instructions to create a 12.1 or 12.2 Enterprise Edition database.

## Oracle Analytics Server Container Image Creation

To build a BI image, first build the Oracle Java image, and then build the Oracle Fusion Middleware Infrastructure image.

### Building the Oracle Java (Server JRE 8) Image

Download the Oracle Server JRE binary into folder `OracleJava/8` and build the image:

        $ cd OracleJava/8
        $ docker build --tag oracle/serverjre:8 .

Refer to the README.md file under [OracleJava](https://github.com/oracle/docker-images/tree/master/OracleJava) for details on how to build Oracle Java image.

### Building the Oracle Fusion Middleware Infrastructure Image
 
Download the binary of Oracle Fusion Middleware Infrastructure into the folder `OracleFMWInfrastructure/dockerfiles/12.2.1.4`.

If you need a proxy for the host to access yum.oracle.com during build, first set up the appropriate environment. For example:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80
        $ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

Build the image:

        $ cd OracleFMWInfrastructure/dockerfiles
        $ ./buildDockerImage.sh -v 12.2.1.4

Refer to the README.md file under [OracleFMWInfrastructure](https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure) for details on how to build the Oracle Fusion Middleware Infrastructure image.

### Building the Oracle Analytics Server Image

Download the binaries for [Oracle Analytics Server 2022 (6.4)](https://www-sites.oracle.com/solutions/business-analytics/analytics-server/analytics-server.html) for Linux x86-64-bit into the folder `OracleAnalytics/dockerfiles/6.4`.

If you need a proxy for the host to access yum.oracle.com during build, first set up the appropriate environment. For example:

        $ export http_proxy=myproxy.example.com:80
        $ export https_proxy=myproxy.example.com:80
        $ export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

Build the image:

        $ cd OracleAnalytics/dockerfiles
        $ ./buildDockerImage.sh -v 6.4

### Building the Oracle Analytics Server Patched Image

Refer to the README.md file under [OracleAnalytics/patches/6.4-patch](./patches/6.4-patch) for steps on how to build the Oracle Analytics Server patched image.


## Creating an Oracle Analytics Server Container

The BI image provides a script to create and start a single-node BI domain, with the SampleApp Lite application.

This script is invoked when a container is started using the image. Subsequently, if the container restarts, the BI domain restarts automatically.

The BI image doesn't support scale-out or upgrade to any future Oracle Analytics Server patchset release.

### Starting a New Container
The following variables are mandatory when starting the container:
* ADMIN_USERNAME - WebLogic admin username for the new domain
* ADMIN_PASSWORD - WebLogic admin password
* DB_HOST - Host name for database into which to create schemas
* DB_PORT - Database listener port
* DB_SERVICE - Database instance service name
* DB_USERNAME - Database sysdba username
* DB_PASSWORD - Database sysdba password
* SCHEMA_PREFIX - Schema prefix for new schemas in the new domain. The schema prefix must be unique. If it’s already in use, domain creation fails.
* SCHEMA_PASSWORD - Password for all new schemas created

ORACLE_HOME is fixed to `/u01/oracle`. 
DOMAIN_HOME is fixed to `/u01/oracle/user_projects/domains/bi`.
  
For example:

        $ docker run -d --name bi -p 9500:9500 -p 9502:9502 -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=<admin_password> -e DB_HOST=database -e DB_PORT=1521 -e DB_SERVICE=ORCLPDB1 -e DB_USERNAME=sys -e DB_PASSWORD=<db_password> -e SCHEMA_PREFIX=DEV -e SCHEMA_PASSWORD=<schema_password> oracle/analyticsserver:6.4-patch

Change _<...password>_ to your required values, and DB values to match your database.

On success, logs the following: `The configuration of Oracle Fusion Middleware completed successfully.`. The script then tails the domain log to stdout.


The BI domain uses the following ports:
* 9500 - WebLogic AdminServer
* 9502 - WebLogic bi_server1 managed server, hosting BI JEE apps
* 9508 - OBI Cluster Controller, providing access to OBI Server system component
* 9514 - OBI Server system component

The following example URLs provide access to the BI domain:
* http://www.example.com:9500/console - WebLogic Admin Console
* http://www.example.com:9502/analytics - BI Answers/Dashboards
* http://www.example.com:9502/va - Data Visualization
* http://www.example.com:9502/xmlpserver - BI Publisher

If access to the OBI Server component is required, for example by the BI Administration Tool, you must modify the previous `docker run` command to expose port 9514.

For example:

        $ docker run -it -p 9500:9500 -p 9502:9502 -p 9514:9514 -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=<admin_password> -e DB_HOST=database -e DB_PORT=1521 -e DB_SERVICE=ORCLPDB1 -e DB_USERNAME=sys -e DB_PASSWORD=<db_password> -e SCHEMA_PREFIX=DEV -e SCHEMA_PASSWORD=<schema_password> oracle/analyticsserver:6.4-patch


### Using a Host Directory for Persistent Data

In the basic usage above, the container stores the persistent data in DOMAIN_HOME, APPLICATIONS_DIR, and SINGLETON_DATA_DIRECTORY.  If the container is deleted, the data is lost.

You can use a data volume for `/u01/oracle/user_projects` to store persistent data on the host disk. For example, to mount a host directory as a data volume:

        $ mkdir -p /scratch/bi && chmod 777 /scratch/bi
        $ docker run -v /scratch/bi:/u01/oracle/user_projects ......

`chmod` is necessary because the container's processes are run under user 'oracle'.

### Using a Database Container

In the above example, `DB_HOST` specifies the host name for the database instance. You must set up a container user-defined network if you want to use a database container or the legacy `--link` feature.

For example,
1. Create a user-defined network using the bridge driver:
     $ docker network create -d bridge bi_net
        
2. Start a database container using the above network:

   $ docker run --name database --network=bi_net ...... oracle/database:12.1.0.2-ee

3. Start a BI container that uses the database by name:

   $ docker run --name bi --network=bi_net -e DB_HOST=database ...... oracle/analyticsserver:6.4-patch

Note: In the above docker run examples, other parameters are omitted for clarity.

### Passing Configuration Environment by Mounted File or Container Secrets

The domain creation script also supports loading the same set of environment key/value pairs from files mounted into the container, using `docker run /v` or docker secrets.

The following files are processed if available, overriding any environment already set:
* For ADMIN_USERNAME/ADMIN_PASSWORD: `/run/secrets/admin.txt` 
* For DB_USERNAME/DB_PASSWORD: `/run/secrets/db.txt`
* For SCHEMA_PASSWORD: `/run/secrets/schema.txt`
* For providing all keys: `/run/secrets/config.txt`

Each *.txt file must contain lines of `key=value` pairs.

### Using Docker Compose

The BI image supports using docker compose to start the BI and DB containers together.

In this mode, the containers are started in parallel, and the BI container must wait for the DB to become available.  The wait time is enabled by setting environment variable `DB_WAIT_TIMEOUT` to the maximum number of seconds to wait. For example, in your `docker-compose.yml`, add:

        environment:
          - DB_WAIT_TIMEOUT=240

## Known Issues

1. The domain's node manager is configured to listen on the network interface for the container's original host name, rather than on all interfaces.  Therefore, if you create a container using an existing data volume for /u01/oracle/user_projects, you must ensure you use the same host name. For example,

        $ docker run --hostname original_hostname ......

2. If the container is restarted, pass the same set of environment variables again, even though the domain has already been created.

3. Container health-check isn't implemented.

## License

To download and run Oracle Analytics Server Distribution regardless of inside or outside a container, and regardless of the distribution, you must download the binaries from the Oracle website and accept the license indicated on that page.

All scripts and files hosted in this project and GitHub [docker/OracleAnalyticsServer](./) repository required to build the container images are, unless otherwise noted, released under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## Copyright

Copyright (c) 2022 Oracle and/or its affiliates.

