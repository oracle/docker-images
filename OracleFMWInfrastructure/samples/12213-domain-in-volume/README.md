Oracle Fusion Middleware Infrastructure domain on Docker
========================================================
This project creates a Docker image which contains an Oracle Fusion Middleware Infrastructure domain image. The image extends the FMW Infrastructure binary image and builds an FMW Infrastructure domain persisted to a host volume.

## How to build and run
This project offers a sample Dockerfile and scripts to build an Oracle Fusion Middleware Infrastructue 12.2.1.3 domain image. 

### Building the Oracle Fusion Middleware Infrastructure 12.2.1.3 base image
A prerequisite to building the 12213-domain-in-volume image is having an Oracle Fusion Middleware Infrastructure 12.2.1.3 binary image. The Dockerfile and scripts to build the image are under the folder, `../../OracleFMWInfrastructure/dockerfile/12.2.1.3`. For more information, see the [README](../../OracleFMWInfrastructure/README.md) file.

**IMPORTANT**: If you are building the Oracle FMW Infrastructure image, you must first download the Oracle FMW Infrastructure 12.2.1.3 binary and place it in the folder, `../OracleFMWInfrastructure/dockerfiles/12.2.1.3`.

        $ cd ../../OracleFMWInfrastructure/dockerfiles
        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version] -d [in-volume/in-image]
        Builds a Docker Image for Oracle FMW Infrastructure.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.3
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        LICENSE UPL 1.0

        Copyright (c) 2014,2019 Oracle and/or its affiliates. All rights reserved.

#### Providing the Administration Server user name and password and Database username and password
The user name and password must be supplied in a `domain_security.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server and Database.

The format of the `domain_security.properties` file is key=value pair:

        username=myadminusername
        password=myadminpassword
        db_user=sys
        db_pass=Oradoc_db1
        db_schema=Oradoc_db1

**Note**: Oracle recommends that the `domain_securtity.properties` file be deleted or secured after the container and the WebLogic Server are started so that the user name and password are not inadvertently exposed.

### Write your own Oracle Fusion Middleware Infrastructure domain with WLST
The best way to create your own domain, or extend an existing domain, is by using the [WebLogic Scripting Tool](https://docs.oracle.com/middleware/1221/cross/wlsttasks.htm). You can find an example of a WLST script to create domains at [`createFMWDomain.py`](samples/12213-domain-in-volume/container-scripts/createFMWDomain.py). You may want to tune this script with your own setup to create datasources and connection pools, security realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Running the Oracle FMW Infrastructure domain Docker image
To run an FMW Infrastructure domain sample container, you will need the FMW Infrastructure domain image and an Oracle database. The Oracle database could be remote or running in a container. If you want to run the Oracle database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com), or build your own image using the Dockerfiles and scripts in this Git repository. There is a slim version of the Oracle database image at [Oracle Container Registry](https://container-registry.oracle.com) that you can pull and run.

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

### Build the FMW Infrastructure Domain Image
There are two Dockerfiles to build the FMW Infrastructure Image, one creates the domain in a volume in the host and one persists a domain inside of a Docker image.

  1. To build the `12.2.1.3` FMW Infrastructure domain image, run:

        `$ docker build -f Dockerfile -t 12213-fmw-domain-in-volume .`

  2. Verify you now have this image in place with:

	`$ docker images`

#### Start the container
Start a container from the image created in step 1.
You can override the default values of the following parameters during runtime in the `./properties/domain.properties` file. The script `./container-scripts/setEnv.sh` sets the environment variables to configure the domain. The default values of the environment variables are:

      * `CUSTOM_DOMAIN_NAME`
      * `CUSTOM_ADMIN_LISTEN_PORT`
      * `CUSTOM_ADMIN_NAME`
      * `CUSTOM_ADMIN_HOST`
      * `CUSTOM_MANAGEDSERVER_PORT`
      * `CUSTOM_MANAGED_BASE_NAME`
      * `CUSTOM_MANAGED_NAME`
      * `CUSTOM_MANAGED_SERVER_COUNT`
      * `CUSTOM_CLUSTER_NAME`
      * `CUSTOM_RCUPREFIX`
      * `CUSTOM_PRODUCTION_MODE`
      * `CUSTOM_DEBUG_PORT`
      * `CUSTOM_DEBUG_FLAG`
      * `CUSTOM_CONNECTION_STRING`

**NOTE**: When you set the `CUSTOM_DOMAIN_NAME`, the `DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME`.

  Start a container to launch the Administration and Managed Servers from the image created in step 1.

  To run an Administration Server container, call:

        `$ sh run_admin_server.sh`

**NOTE**: To have access to the `RCU.out` map volume `/u01/oracle/` in the admin server container. 

  To run Managed Server with base name `infraMS` pass in to the scrtipt `run_managed_server.sh` the name of the managed server you want to run and the host port that will be mapped to the managed server port 8001. To run managed server one with name `infraMS1` and mapped to host port 98001 call:

        `$ sh run_managed_server.sh infraMS1 98001`

 To run managed server two with name `infraMS2` and mapped to host port 98002 call:

        `$ sh run_managed_server.sh infraMS2 98002`

  Access the Administration Console:

	`$ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>`
        This returns the IP address of the container (for example, `xxx.xx.x.x`).  Go to your browser and enter `http://xxx.xx.x.x:9001/console`

        Because the container ports are mapped to the host port, you can access it using the `hostname` as well.


## Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
