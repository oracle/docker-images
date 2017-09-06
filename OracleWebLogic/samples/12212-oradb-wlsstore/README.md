Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic install image from the DockerStore configures a WebLogic domain, creates a DataSource that connects to a DB, and deploys a WLS application that does DB operations.

# How to build and run
Pull the WebLogic install image from the DockerStore at https://store.docker.com/images/oracle-weblogic-server-12c.
	$ docker pull  store/oracle/weblogic:12.2.1.2 

To run this sample you will need both the WebLogic container and an Oracle Database container. Pull the Oracle Database image from the Docker Store or the Oracle Container Registry.

	$ docker pull container-registry.oracle.com/database/enterprise:latest 

Follow the steps below:

    Create the docker network for the infra server to run

   $ docker network create -d bridge InfraNET
 
# Run the Database container 
To create a database container, use the environment file below to set the database name, password, domain and feature bundle.  The example environment file env.txt is:

	DB_SID=infradb
	DB_PDB=infrapdb
	DB_PASSWD=Welcome1
	DB_DOMAIN=us.oracle.com
	DB_BUNDLE=basic


   $ docker run --name MYInfraDb --network=InfraNET -p 1521:1521 -p 5500:5500 --env-file env.txt -it --shm-size="8g" container-registry.oracle.com/database/enterprise:latest

  Verify that the Database is running you should see the string 

   Done ! The database is ready for use .

To run DDL to create the tables needed by the application copy createSchema.sql into the DB

    $ docker cp createSchema.sql MYInfraDb:/u01/app/oracle

Run sqlplus to run the ddl

    $docker docker exec -ti MYInfraDb /u01/app/oracle/product/12.1.0/dbhome_1/bin/sqlplus system@infrapdb/<My DB Password> @/u01/app/oracle/createSchema.sql

# Build the WebLogic image

When you build the image the domain and Admin Server are created, the Data Source is created and the Auction application is deployed

        $ docker build -t 12212-oradb-wlsstore .

or
        $ ./build.sh

To start the Admin Server, run:

        $ docker run -i -t -p 7001:7001 --network=InfraNET --name WLSStoreContainer 12212-oradb-wlsstore:latest

# Access the application:

        http://localhost:7001/auction

# Copyright
 Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.


 Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

