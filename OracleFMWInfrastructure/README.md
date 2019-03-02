Oracle Fusion Middleware Infrastructure on Docker
=================================================
This Docker configuration has been used to create the Oracle Fusion Middleware Infrastructure image. Providing this FMW image facilitates the configuration and environment setup for DevOps users. This project includes the creation of an  FMW Infrastructure domain.

The certification of the Oracle FMW Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

## How to build and run
This project offers a sample Dockerfile and scripts to build an Oracle Fusion Middleware Infrastructue 12cR2 (12.2.1.x) image. To assist in building the image, you can use the [`buildDockerImage.sh`](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building the Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary, locate it in the folder, `../OracleJava/java-8`, and build that image. For more information, see the [`OracleJava`](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../OracleJava/java-8
        $ sh build.sh

You can also pull the Oracle Server JRE 8 image from the [Oracle Container Registry](https://container-registry.oracle.com) or the [Docker Store](https://store.docker.com/images/oracle-serverjre-8). When pulling the Server JRE 8 image, re-tag the image so that it works with the existing Dockerfiles.

        $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8
        $ docker tag store/oracle/serverjre:8 oracle/serverjre:8

### Building the Oracle FMW Infrastructure 12.2.1.x base image
**IMPORTANT**: If you are building the Oracle FMW Infrastructure image, you must first download the Oracle FMW Infrastructure 12.2.1.x binary and locate it in the folder, `../OracleFMWInfrastructure/dockerfiles/12.2.1.x`.

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version] 
        Builds a Docker Image for Oracle FMW Infrastructure.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.x
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        LICENSE UPL 1.0

        Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will have a domain with an Administration Server and one Managed Server by default. You must extend the image with your own Dockerfile, and create your domain using WLST.

#### Providing the Administration Server user name and password and Database username and password
The user name and password must be supplied in a `domain.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server and Database.

The format of the `domain.properties` file is key=value pair:

        username=myadminusername
        password=myadminpassword
        db_username=mydbusername
        db_password=mydbpassword
        db_schema_password=mydbschemapassword

**Note**: Oracle recommends that the `domain.properties` file be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### Write your own Oracle Fusion Middleware Infrastructure domain with WLST
The best way to create your own domain, or extend an existing domain, is by using the [WebLogic Scripting Tool](https://docs.oracle.com/middleware/1221/cross/wlsttasks.htm). You can find an example of a WLST script to create domains at [`createInfraDomain.py`](dockerfiles/12.2.1.x/container-scripts/createInfraDomain.py). You may want to tune this script with your own setup to create datasources and connection pools, security realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Running the Oracle FMW Infrastructure domain Docker image
To run an FMW Infrastructure domain sample container, you will need the FMW Infrastructure domain image and an Oracle database. The Oracle database could be remote or running in a container. If you want to run the Oracle database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com), or build your own image using the Dockerfiles and scripts in this Git repository.

Follow the steps below:

  1. Create the Docker network for the infra server to run:

	`$ docker network create -d bridge InfraNET`

  2. Run the database container to host the RCU schemas
     The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the FMW Infrastructure image to connect to the database running in the container. Add to an `env.txt` file the following parameters:

	`DB_SID=InfraDB`

	`DB_PDB=InfraPDB1`

	`DB_DOMAIN=us.oracle.com`

	`DB_BUNDLE=basic`

	`$ docker run -d --name InfraDB --network=InfraNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1`


Verify that the database is running and healthy. The `STATUS` field shows `healthy` in the output of `docker ps`.

The database is created with the default password `Oradoc_db1`. To change the database password, you must use `sqlplus`.  To run `sqlplus`, pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a `sqlplus` container with the following command:

	$ docker run -ti --network=InfraNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA

	SQL> alter user sys identified by MYDBPasswd container=all;

#### Start the container
Start a container from the image created in step 1.
You can override the default values of the following parameters during runtime with the `-e` option:

      * `ADMIN_NAME`                  (default: `AdminServer`)
      * `ADMIN_LISTEN_PORT`           (default: `7001`)
      * `DOMAIN_NAME`                 (default: `infra_domain`)
      * `ADMINISTRATION_PORT_ENABLED` (default: `true`)
      * `ADMINISTRATION_PORT`         (default: `9002`)
      * `MANAGEDSERVER_PORT`          (default: `8001`)



  The environment variables used to configure the `InfraDomain` are defined in the `infraDomain.env.list` file. In `infraDomain.env.list`, replace the values.  Make sure you have created the domain.properties file as described above with the credentials to the Admin server and the database.  Call `docker run` from the `dockerfiles/12.2.1.x` directory where the `infraDomain.env.list` file is located and pass in the file name at runtime.

  To run an Administration Server container, call:

	`$ docker run -d -p 9001:7001 --network=InfraNET -v `HOST PATH where thedomain.properties file is`:/u01/oracle/properties -v `HOST PATH where you map domain configuration`:/u01/oracle/user_projects/domains --name InfraAdminContainer --env-file ./infraDomain.env.list -e ADMINISTRATION_PORT_ENABLED=true -e DOMAIN_NAME=infra_domain oracle/fmw-infrastructure:12.2.1.X`

  To run a Managed Server container, call:

	`$ docker run -d -p 9801:8001 --network=InfraNET --volumes-from InfraAdminContainer --name InfraManagedContainer --env-file ./infraDomain.env.list oracle/fmw-infrastructure:12.2.1.x startManagedServer.sh`

  Access the Administration Console:

	`$ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>`
        This returns the IP address of the container (for example, `xxx.xx.x.x`).  Go to your browser and enter `http://xxx.xx.x.x:9001/console`

        Because the container ports are mapped to the host port, you can access it using the `hostname` as well.

**NOTE**: To have access to the RCU.out map volume in the container /u01/oracle/. 

## Copyright
Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
