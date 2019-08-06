Oracle Fusion Middleware Infrastructure domain on Docker
========================================================
This project creates a Docker image which contains an Oracle Fusion Middleware Infrastructure domain image. The image extends the FMW Infrastructure install/binary image and builds an FMW Infrastructure domain persisted inside the image.

### Building the Oracle Fusion Middleware Infrastructure 12.2.1.3 base image
A prerequisite to building the 12213-fmw-domain-in-image image is having an Oracle Fusion Middleware Infrastructure 12.2.1.3 install/binary image. The Dockerfile and scripts to build the image are under the folder, `../../OracleFMWInfrastructure/dockerfile/12.2.1.3`. For more information, see the [README](../../OracleFMWInfrastructure/README.md) file.

**IMPORTANT**: If you are building the Oracle FMW Infrastructure image, you must first download the Oracle FMW Infrastructure 12.2.1.3 install/binary and place it in the folder, `../OracleFMWInfrastructure/dockerfiles/12.2.1.3`.

        $ cd ../../OracleFMWInfrastructure/dockerfiles
        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version]
        Builds a Docker Image for Oracle FMW Infrastructure.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.3
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        LICENSE UPL 1.0

        Copyright (c) 2014,2019 Oracle and/or its affiliates. All rights reserved.

#### Providing the Administration Server user name and password and database user name and password
The Administration Server user name and password must be supplied in a `domain_security.properties` file and the database user name and password must be supplied in a `rcu_security.properties` file. Both these files should be located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server and database.

The format of the `domain_security.properties` file is key=value pair:

        username=myadminusername
        password=myadminpassword

The format of the `rcu_security.properties` file is key=value pair:

        db_user=sys
        db_pass=Oradoc_db1
        db_schema=Oradoc_db1

**Note**: Oracle recommends that the `domain_securtity.properties` and the `rcu_security.properties` files be deleted or secured after the container and WebLogic Server are started so that the user name and password are not inadvertently exposed.

## Running the Oracle FMW Infrastructure domain Docker image
To run an FMW Infrastructure domain sample container, you will need the FMW Infrastructure domain image and a database. The database could be remote or running in a container. If you want to run the Oracle database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com), or build your own image using the Dockerfiles and scripts in this Git repository. There is a slim version of the Oracle database image in the [Oracle Container Registry](https://container-registry.oracle.com) that you can pull and run.

Follow the steps below:

  1. Create the Docker network for the infra server to run:

       $ docker network create -d bridge InfraNET

  2. Run the database container to host the RCU schemas.

     The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the FMW Infrastructure image to connect to the database running in the container.

     Add to an `env.txt` file, the following parameters:

	ID=InfraDB

	DB_PDB=InfraPDB1

	DB_DOMAIN=us.oracle.com

	DB_BUNDLE=basic

       $ docker run -d --name InfraDB --network=InfraNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1


Verify that the database is running and healthy. The `STATUS` field shows `healthy` in the output of `docker ps`.

The database is created with the default password `Oradoc_db1`. To change the database password, you must use `sqlplus` and give the right permissions.  To run `sqlplus`, pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a `sqlplus` container with the following command:

       $ docker run -ti --network=InfraNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA

       SQL> alter user sys identified by MYDBPasswd container=all;

### Build and run RCU
Many of the Oracle Fusion Middleware components require the existence of schemas in a database prior to installation. These schemas are created and loaded in your database using the Repository Creation Utility (RCU). To facilitate running RCU, you can build an image using the `Dockerfile.rcu`.

       $ docker build -f Dockerfile.rcu -t 12213-fmw-rcu .

To run RCU, start a container from the image created:

       $ docker run -d --name RCU --network=InfraNET -v HOSTPATH/OracleFMWInfrastructure/samples/12213-domain-in-volume/properties:/u01/oracle/properties 12213-fmw-rcu

**NOTE**: To have access to the `RCU.out`, map volume `/u01/oracle/` in the Administration Server container.

### Build the FMW Infrastructure Domain Image
The Dockerfile in this sample extends the FMW Infrastructure install image and creates a domain configuration inside of the image. We provide a `build.sh` script to assist with the building of the image and setting the correct BUILD_ARGS that have been defined in the `domain.properties` and `rcu.properties` files. You can override the default values of the following parameters during configuration time in both these properties files. The script `./container-scripts/setEnv.sh` sets the build time environment variables to configure the domain, the following BUILD ARGS are set:

* `CUSTOM_DOMAIN_NAME`
* `CUSTOM_ADMIN_PORT`
* `CUSTOM_ADMIN_HOST`
* `CUSTOM_ADMIN_NAME`
* `CUSTOM_MANAGED_BASE_NAME`
* `CUSTOM_MANAGED_SERVER_COUNT`
* `CUSTOM_MANAGEDSERVER_PORT`
* `CUSTOM_CLUSTER_NAME`
* `CUSTOM_RCUPREFIX`
* `CUSTOM_PRODUCTION_MODE`
* `CUSTOM_DEBUG_PORT`
* `CUSTOM_DEBUG_FLAG`
* `CUSTOM_CONNECTION_STRING`

**NOTE**: When you set the `CUSTOM_DOMAIN_NAME`, the `DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME`.

  1. To build the `12.2.1.3` FMW Infrastructure domain image, run:

       $ docker build $BUILD_ARG --network InfraNET -f Dockerfile -t 12213-fmw-domain-in-image .

  2. Verify that you now have this image in place with:

       $ docker images


#### Start the container
Start a container from the image created in step 1.
The script `./container-scripts/setRuntimeEnv.sh` sets the environment variables required at runtime based on the values defined in the `./properties/domain.properties`  file and used originally to configure the domain.

We are supplying the scripts, `run_admin_server.sh` and `run_managed_server.sh`, to facilitate setting the environment variables defined in the property files and running the Administration Server and Managed Server containers.

  Start a container to launch the Administration Server and Managed Servers from the image created in step 1.

  To run an Administration Server container, call:

       $ sh run_admin_server.sh


  To run a Managed Server with the base name, `infraMS`, pass in to the script, `run_managed_server.sh`, the name of the Managed Server you want to run, and the host port that will be mapped to the Managed Server port 8001. To run Managed Server one, with the name, `infraMS1`, and mapped to the host port 9004, call:

       $ sh run_managed_server.sh infraMS1 9004

 To run Managed Server two with the name, `infraMS2`, and mapped to the host port 9006, call:

       $ sh run_managed_server.sh infraMS2 9006

  Access the WLS Administration Console:

       $ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>

This returns the IP address of the container (for example, `xxx.xx.x.x`).  
Go to your browser and enter `http://xxx.xx.x.x:9001/console`.

Because the container ports are mapped to the host port, you can access it using the `hostname` as well.


## Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
