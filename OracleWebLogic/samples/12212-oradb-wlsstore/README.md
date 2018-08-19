Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic install image from the DockerStore configures a WebLogic domain, creates a DataSource that connects to a DB, and deploys a WLS application that does DB operations.

## How to build and run
Pull the WebLogic install image from the DockerStore at https://store.docker.com/images/oracle-weblogic-server-12c.

	$ docker pull  store/oracle/weblogic:12.2.1.2

To run this sample you will need both the WebLogic container and an Oracle Database container. Pull the Oracle Database image from the Docker Store or the Oracle Container Registry.

	$ docker pull container-registry.oracle.com/database/enterprise:12.2.0.1

Follow the steps below:

Create the docker network for the WLS and Database containers to run

	$ docker network create -d bridge SampleNET

## Run the Database container
To create a database container, use the environment file below to set the database name, password, domain and feature bundle.  The example environment file env.txt is:

	DB_SID=InfraDB
	DB_PDB=InfraPDB1
	DB_DOMAIN=us.oracle.com
	DB_BUNDLE=basic

	$ docker run -d --name InfraDB --network=SampleNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:12.2.0.1


	Verify that the Database is running and healthy, the STATUS field shows (healthy) in the output of docker ps.

	 The Database is created with the default password 'Oradoc_db1', to change the database password you must use sqlplus.  To run sqlplus pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a sqlplus container with the following command:

	$ docker run -ti --network=SampleNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA

	SQL> alter user system identified by MYDBPasswd container=all;

To run the DDL that creates the tables needed by the application, copy createSchema.sql into the Database container

	$ docker cp createSchema.sql InfraDB:/u01/app/oracle

Run sqlplus to run the DDL

	$docker exec -ti InfraDB /u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus system/MYDBPasswd@InfraDB:1521/InfraPDB1.us.oracle.com @/u01/app/oracle/createSchema.sql


## Build the WebLogic image

When you build the image the domain and Admin Server are created, the Data Source is created and the Auction application is deployed

	$ docker build -t 12212-oradb-wlsstore .

or

	$ ./build.sh

Before starting the WebLogic server make sure you change the file container-scripts/oradatasource.properties to set the database password for user 'system' to MYDBPasswd you set above. The Admin Server, run:

	$ docker run -d -i -t -p 7001:7001 --network=SampleNET --name WLSStoreContainer 12212-oradb-wlsstore:latest

## Access the application:

Invoke from your browser

	http://localhost:7001/auction

## Copyright
 Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.


 Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
