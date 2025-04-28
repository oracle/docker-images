# Oracle Fusion Middleware Infrastructure on Docker

This Docker configuration has been used to create the Oracle Fusion Middleware Infrastructure image. Providing this FMW image facilitates the configuration and environment set up for DevOps users. This FMW Infrastructure 14.1.2.0 image is based on Oracle Linux and Oracle JDK 17 or Oracle JDK 21. This project includes the creation of a FMW Infrastructure domain.

**IMPORTANT**: We provide Dockerfiles as samples to build FMW Infrastructure images but this is _NOT_ a recommended practice. We recommend obtaining patched FMW Infrastructure images have the latest security patches. For more information, see [Obtaining, Creating, and Updating Oracle Fusion Middleware Images with Patches] (<https://docs.oracle.com/en/middleware/fusion-middleware/14.1.2/opatc/obtaining-creating-and-updating-oracle-fusion-middleware-images-patches.html>).

The samples in this repository are for development purposes only. We recommend for production to use alternative methods, we suggest obtaining base FMW Infastructure images from the [Oracle Container Registry](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/ocr-images/>).

Consider using the open source [WebLogic Image Tool](<https://oracle.github.io/weblogic-kubernetes-operator/userguide/base-images/custom-images/>) to create custom images, and using the open source [WebLogic Kubernetes Operator](<https://oracle.github.io/weblogic-kubernetes-operator/>) to deploy and manage cwFMW Infrastructure domains.

The certification of the Oracle FMW Infrastructure on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize, tweak, or create from scratch, new scripts and Dockerfiles.

## How to build and run
This project offers a sample Dockerfile and scripts to build an Oracle Fusion Middleware Infrastructue 14c (14.1.2.0) binary image. To assist in building the image, you can use the [`buildDockerImage.sh`](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is a utility shell script that takes the version of the image that needs to be built. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building the Oracle JDK image
If you want to run FMW Infrastructure on Oracle JDK 17, you must build the image by using the Dockerfile in [`../../../OracleJava/17`](<https://github.com/oracle/docker-images/tree/master/OracleJava/17>). If you want to run images of FMW Infrastructure based on the Oracle JDK 21 image, you must build the image by using the Dockerfile in [`../../../OracleJava/21`](<https://github.com/oracle/docker-images/tree/master/OracleJava/21>).

### Building the Oracle FMW Infrastructure 12.2.1.x base image
**IMPORTANT**: If you are building the FMW Infrastructure image, you must first download the FMW Infrastructure 14.1.2.0 binary and locate it in the folder, `../OracleFMWInfrastructure/dockerfiles/14.1.2.0`.

        $ sh buildDockerImage.sh
        Usage: buildDockerImage.sh -v [version]
        Builds a Docker Image for Oracle FMW Infrastructure.

        Parameters:
           -v: version to build. Required.
           Choose : 12.2.1.4 or 14.1.2.0
           -c: enables Docker image layer cache during build
           -s: skips the MD5 check of packages

        LICENSE UPL 1.0

        Copyright (c) 2025 Oracle and/or its affiliates. All rights reserved.

**IMPORTANT:** The resulting images will have a domain with an Administration Server and one Managed Server by default. You must extend the image with your own Dockerfile, and create your domain using WLST.

#### Providing the Administration Server user name and password and database user name and password
The user name and password must be supplied in a `./dockerfiles/14.1.2.0/properties/domain_security.properties` file located in a HOST directory that you will map at Docker runtime with the `-v` option to the image directory `/u01/oracle/properties`. The properties file enables the scripts to configure the correct authentication for the WebLogic Administration Server and database.

The format of the `domain_security.properties` file is key=value pair.

**Note**: Oracle recommends that the `domain_security.properties` file be deleted or secured after the container and WebLogic Server are started so that the user name and password are not inadvertently exposed.

### Write your own Oracle Fusion Middleware Infrastructure domain with WLST
The best way to create your own domain, or extend an existing domain, is by using the [WebLogic Scripting Tool](https://docs.oracle.com/en/middleware/fusion-middleware/14.1.2/wlstg/index.html). You can find an example of a WLST script to create domains at [`createInfraDomain.py`](dockerfiles/14.1.2.0/container-scripts/createInfraDomain.py).
You may want to tune this script with your own setup to create datasources and connection pools, security realms, deploy artifacts, and so on. You can also extend images and override an existing domain, or create a new one with WLST.

## Running the Oracle FMW Infrastructure domain Docker image
To run an FMW Infrastructure domain sample container, you will need the FMW Infrastructure domain image and an Oracle database. The Oracle database could be remote or running in a container.
If you want to run the Oracle database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com), or build your own image using the Dockerfiles and scripts in this Git repository.

Follow the steps below:

    1. Create the Docker network for the infra server to run:

       `$ docker network create -d bridge InfraNET`

    2. Run the database container to host the RCU schemas.

     The Oracle database server container requires custom configuration parameters for starting up the container. These custom configuration parameters correspond to the datasource parameters in the FMW Infrastructure image to connect to the database running in the container.

     Add to an `env.txt` file, the following parameters:

       `DB_SID=InfraDB`

       `DB_PDB=InfraPDB1`

       `DB_DOMAIN=us.oracle.com`

       `DB_BUNDLE=basic`

       `$ docker run -d --name InfraDB --network=InfraNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:19.19.0.0`


Verify that the database is running and healthy. The `STATUS` field shows `healthy` in the output of `docker ps`.

The database is created with the default password `Oradoc_db1`. To change the database password, you must use `sqlplus`.  To run `sqlplus`, pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a `sqlplus` container with the following command:

       `$ docker run -ti --network=InfraNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA`

       `SQL> alter user sys identified by MYDBPasswd container=all;`

### Build the FMW Infrastructure Image

     1. To build the `14.1.2.0` FMW Infrastructure image, run:

      `$ sh buildDockerImage.sh -v 14.1.2.0`

     2. Verify that you now have this image in place with:

      `$ docker images`

## Start the containers
In this image, the domain home will be persisted to a volume in the host. The `-v` option is used at Docker runtime to map the image directory where the domain home is persisted, `/u01/oracle/user_projects/domains`, to the host directory you have defined in `domain.properties` `DOMAIN_HOST_VOLUME`.

You can override the default values of the following parameters during runtime in the `./properties/domain.properties` file. The script `./container-scripts/setEnv.sh` sets the environment variables to configure the domain. The default values of the environment variables are:

* `DOMAIN_NAME=myinfraDomain`
* `ADMIN_LISTEN_PORT=7001`
* `ADMIN_NAME=myadmin`
* `ADMIN_HOST=InfraAdminContainer`
* `ADMINISTRATION_PORT_ENABLED=false`
* `ADMINISTRATION_PORT=9002`
* `MANAGEDSERVER_PORT=8001`
* `MANAGED_NAME=infraServer1`
* `RCUPREFIX=INFRA01`
* `PRODUCTION_MODE=dev`
* `CONNECTION_STRING=InfraDB:1521/InfraPDB1.us.oracle.com`
* `DOMAIN_HOST_VOLUME=/User/host/dir`

**NOTE**: For security, you want to set the domain mode to `production mode`. In WebLogic Server 14.1.2.0 a new `production mode` domain becomes by default a `secured production` mode domain. Secured production mode domains have more secure default configuration settings, for example the Administration port is enabled, all non-ssl listen ports are disabled, and all ssl ports are enabled.

In this image we create a Development Mode domain by default, you can create a Production Mode domain (with Secured Production Mode disabled) by setting in the `docker run` command `PRODUCTION_MODE` to `prod` and set `ADMINISTRATION_PORT_ENABLED` to true.
If you intend to run these images in production, then you should change the Production Mode to `production`. When you set the `DOMAIN_NAME`, the `DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME`. Please see the documentation [Administering Security for Oracle WebLogic Server](<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/14.1.2/secmg/using-secured-production-mode.html#GUID-9ED2EF38-F763-4999-80ED-27A3FBCB9D7D>).

  Start a container to launch the Administration Server and Managed Servers from the image created in step 1. To facilitate setting the environment variables defined in the "./properties/domain.properties" file, we provide scripts "./container-scripts/setEnv.sh", "./run_admin_server.sh", and "./run_managed_server.sh".

        `$ docker run -d -p 9001:7001 -p 9002:9002 --name ${adminhost} --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties -v ${DOMAIN_HOST_VOLUME}:/u01/oracle/user_projects/domains ${ENV_ARG} oracle/fmw-infrastructure:14.1.2.0`


  To run a Managed Server, call:

        `$ docker run -d -p 9802:8002 --network=InfraNET -v ${scriptDir}/properties:/u01/oracle/properties ${ENV_ARG} --volumes-from ${adminhost} --name ${managedname}  oracle/fmw-infrastructure:14.1.2.0 startManagedServer.sh`

**NOTE**: WebLogic Server 14.1.2.0 provides the WebLogic Remote Console, a lightweight, open source console that you can use to manage domain configurations of WebLogic Server Administration Servers or WebLogic Deploy Tooling (WDT).
For details related to WDT metadata models, please see [documentation `About WebLogic Remote Console`] (<https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-remote-console/administer/introduction.html#WLSRC-GUID-C52DA76D-A7F2-4E7F-ABDA-499EB41372E5>).  The WebLogic Remote Console replaces the retired WebLogic Administration Console.

Run the WLS Remote Console :

WebLogic Remote Console is available in two formats:

    * Desktop WebLogic Remote Console, a desktop application installed on your computer.
    * Hosted WebLogic Remote Console, a web application deployed to an Administration Server and accessed through a browser.

Generally, the two formats have similar functionality, though the desktop application offers certain conveniences that are not possible when using a browser. The Desktop WebLogic Remote Console is best suited for monitoring WebLogic domains running in containers.

1. Download the latest version of Desktop WebLogic Remote Console from the [WebLogic Remote Console GitHub Repository] (<https://github.com/oracle/weblogic-remote-console/releases>). Choose the appropriate installer for your operating system.
2. Follow the typical process for installing applications on your operating system.
3. Launch WebLogic Remote Console.

You will need the ip.address of the Admin server container to later use to connect from the Remote Console

        `$ docker inspect --format '{{.NetworkSettings.IPAddress}}' <container-name>`

4. Open the Providers drawer and click More ︙.
5. Choose a provider type from the list:
     `Add Admin Server Connection Provider`
6. Fill in any required connection details for the selected provider.  In the URL filed enter `http://xxx.xx.x.x:7001` if in Production Mode `https://xxx.xx.x.x:9002`.
7. Click OK to establish the connection.

## Copyright
Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
