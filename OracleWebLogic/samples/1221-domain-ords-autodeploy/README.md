Oracle WebLogic with ORDS 
================================
This Dockerfile extends the Oracle WebLogic image **oracle/weblogic:12.2.1-developer**. It creates a domain based on the **Basic WebLogic Server Domain (12.2.1.0.0)** template and deploys the [Oracle REST Data Services](http://www.oracle.com/technetwork/developer-tools/rest-data-services/overview/index.html) in the **AdminServer**. The purpose of this image is to help devops engineers to debug their ORDS installations on WebLogic.

The [Dockerfile](Dockerfile) installs the domain and creates the **ORDS_HOME** with the [script](container-scripts/configureORDSandStartWLSDomain.sh) that will configure ORDS, deploy it on WLS server and start the domain.

# How to build and run

## Download ORDS binaries
You can get the binaries from [here](http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html). For this example I did use the version **3.0.12**. You will need to **extract** the **ords.war** from the .zip file and put it in the same folder as the Dockerfile.  

## Build the base Oracle WebLogic image
First make sure you have built **oracle/weblogic:12.2.1-developer**. Now to build this sample, run:

        $ docker build -t 1221-domain --build-arg ADMIN_PASSWORD=welcome1 .

## Create an user defined network
Before you run your containers you will have to specify a network in which WLS will communicate with the database. In order to do so you need to create an [user-defined network](https://docs.docker.com/engine/userguide/networking/#user-defined-networks) first.
This can be done via following command:

    docker network create <your network name>

Once you have created the network you can double check by running:

    docker network ls

You should see your network, amongst others, in the output.

## Run Oracle Database container
To run this sample you will need the **Oracle Database Container**. Either you can pull it from the [Oracle Container Registry](https://container-registry.oracle.com/pls/apex/f?p=113:101), from [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or build any of the images provided on this [repository](https://github.com/oracle/docker-images/tree/master/OracleDatabase).   

For this example I have built the [Oracle Database 12c Standard Edition Release 12.2.0.1.0](https://github.com/oracle/docker-images/tree/master/OracleDatabase/dockerfiles/12.1.0.2).

Now you want to start your database container with the specified network. This can be done via the `docker run` with `--network` option:

       $ docker run --name <your database container name> --network=<your network name> -p <host port>:1521 -p <host port>:5500 -e ORACLE_PWD==<Your DB SYS PASSWORD> -e ORACLE_SID=<Your DB System ID> -e ORACLE_PDB=<Your pluggable database name> -v [<host mount point>:]/opt/oracle/oradata oracle/database:12.2.0.1-se2

**Note**: You can find the password for SYS, SYSTEM and PDBADMIN in the docker output

## Build your image
Just run:

      $ docker build -t 1221-domain-ords-autodeploy --build-arg ADMIN_PASSWORD=welcome1 .

## Run your Weblogic image
Use an environment to set the database host, port, service, password of the ORDS_PUBLIC_USER, sys username and password:

      DB_HOSTNAME=<Your database container name>
      DB_PORT=1521
      DB_SERVICENAME=<Your pluggable database name>
      USER_PUBLIC_PASSWORD=<Any password of your choice>
      SYS_USER=SYS
      SYS_PASSWORD=<Your DB SYS PASSWORD>

Run the container with:

      $ docker run --name wls_ords --network=SampleNET --env-file=env.txt -p 7001:7001 1221-domain-ords-autodeploy

The first thing that our container will do is to set the **configdir** for the **ords.war**. In the docker output you should see something like:

     INFO: Set config.dir to /u01/oracle/user_projects/ords/conf in: /u01/oracle/user_projects/ords/ords.war

Once the configdir is set, the install command will create the **ORDS_METADATA** (random password) and **ORDS_PUBLIC_USER** (with the specified password) in your **PDB** database. ORDS_METADATA is the owner of the PL/SQL packages used for implementing many Oracle REST Data Services capabilities. ORDS_PUBLIC_USER is the one used for invoking RESTful Services in the Oracle REST Data Services-enabled schemas. The docker output should look like this:

     INFO: Updated configurations: defaults, apex_pu
     Nov 11, 2017 6:38:54 PM oracle.dbtools.installer.Installer log
     INFO: Installing Oracle REST Data Services version 3.0.12.263.15.32
     Nov 11, 2017 6:38:54 PM oracle.dbtools.installer.Runner log
     INFO: ... Log file written to /u01/oracle/ords_install_core_2017-11-11_183854_00277.log
     Nov 11, 2017 6:38:54 PM oracle.dbtools.installer.Runner log
     INFO: ... Verified database prerequisites
     Nov 11, 2017 6:38:55 PM oracle.dbtools.installer.Runner log
     INFO: ... Created Oracle REST Data Services schema
     Nov 11, 2017 6:38:55 PM oracle.dbtools.installer.Runner log
     INFO: ... Created Oracle REST Data Services proxy user
     Nov 11, 2017 6:38:56 PM oracle.dbtools.installer.Runner log
     INFO: ... Granted privileges to Oracle REST Data Services
     Nov 11, 2017 6:39:04 PM oracle.dbtools.installer.Runner log
     INFO: ... Created Oracle REST Data Services database objects
     Nov 11, 2017 6:39:09 PM oracle.dbtools.installer.Runner log
     INFO: ... Log file written to /u01/oracle/ords_install_datamodel_2017-11-11_183909_00379.log
     Nov 11, 2017 6:39:09 PM oracle.dbtools.installer.Installer log
     INFO: Completed installation for Oracle REST Data Services version 3.0.12.263.15.32. Elapsed time: 00:00:15.614

Finally Weblogic will pick up the ords.war from its **autodeploy** folder and will deploy it in the **AdminServer** under the **/ords** context:

     INFO: No encryption key found in configuration, generating key
     Nov 11, 2017 6:39:36 PM  
     INFO: No mac key found in configuration, generating key
     Nov 11, 2017 6:39:36 PM  
     INFO: Updated configurations: defaults
     Nov 11, 2017 6:39:36 PM  
     INFO: Updated configuration with generated keys
     Nov 11, 2017 6:39:36 PM  
     INFO: Using configuration folder: /u01/oracle/user_projects/ords/conf/ords
     Nov 11, 2017 6:39:36 PM  
     INFO: Validating pool: |apex|pu|
     Nov 11, 2017 6:39:37 PM  
     INFO: Pool: |apex|pu| is correctly configured
     version
     config.dir
     Nov 11, 2017 6:39:37 PM  
     INFO: Oracle REST Data Services initialized
     Oracle REST Data Services version : 3.0.12.263.15.32
     Oracle REST Data Services server info: WebLogic Server 12.2.1.0.0 Tue Oct 6 10:05:47 PDT 2015 1721936 WebLogic JAX-RS 2.0 Portable Server / Jersey 2.x integration module 

#Test your installation
If you try this request

     http://localhost:7001/ords/

You will get a **404**. This is because there is still no schema, neither database object (table, procedure, etc.) with the **REST services enabled**. Probably the first thing you want to do is to create a simple table and populate it with some data. Unfortunately the user default user **pdbadmin** created in your database has not enough privileges to create a table. Moreover only database users with the DBA role can enable the REST services capabilities in their objects. You can copy the [ddl-scripts/grant_dba_and_create_table_to_pdbadmin_user.sql](ddl-scripts/grant_dba_and_create_table_to_pdbadmin_user.sql) to the database container and run it for fixing this:

     $ docker cp ddl-scripts/grant_dba_and_create_table_to_pdbadmin_user.sql <your database container name>:/home/oracle
     $ docker exec -ti <your database container> sqlplus sys/<your sys password>@//localhost:1521/PDB as SYSDBA @/home/oracle/grant_dba_and_create_table_to_pdbadmin_user.sql

Now you can create a simple table for testing

     $ docker cp ddl-scripts/create_customer_table.sql <your database container name>:/home/oracle
     $ docker exec -ti <your database container> sqlplus pdbadmin/<your pdbadmin password>@//localhost:1521/PDB @/home/oracle/create_customer_table.sql

We are almost done! The final step would be to enable the rest access on your table. This can be easily done through the [AutoREST](https://docs.oracle.com/cd/E56351_01/doc.30/e87809/developing-REST-applications.htm#GUID-4CE630AA-2F06-41D9-96F6-DA77AB1E6395) capability. However if you try to do this in our freshly created table you will get an error like this:

     ORA-06598: insufficient INHERIT PRIVILEGES privilege
     ORA-06512: at "ORDS_METADATA.ORDS", line 1
     ORA-06512: at line 5
     06598. 00000 -  "insufficient INHERIT PRIVILEGES privilege"
     *Cause:    An attempt was made to run an AUTHID CURRENT_USER function or
                procedure, or to reference a BEQUEATH CURRENT_USER view, and the
                owner of that function, procedure, or view lacks INHERIT PRIVILEGES
                privilege on the calling user.
     *Action:   Either do not call the function or procedure or reference the view,
                or grant the owner of the function, procedure, or view
                INHERIT PRIVILEGES privilege on the calling user.

The calling user, **pdbadmin**, does not have privileges to invoke the [ORDS.ENABLE_OBJECT](https://docs.oracle.com/cd/E56351_01/doc.30/e87809/ORDS-reference.htm#AELIG90183) procedure. This can be solved running:

     $ docker cp ddl-scripts/grant_inherit_privileges.sql <your database container>:/home/oracle
     $ docker exec -ti <your database container> sqlplus sys/<your sys password>@//localhost:1521/PDB as sysdba @/home/oracle/grant_inherit_
privileges.sql

Now you can enable the REST services on the customer table:

     $ docker cp ddl-scripts/enable_auto_rest_on_customer_table.sql <your database container>:/home/oracle
     $ docker exec -ti <your database container> sqlplus pdbadmin/<your pdbadmin password>@//localhost:1521/PDB @/home/oracle/enable_auto_rest_on_customer_table.sql

Finally if you try 

     $ curl http://localhost:7001/ords/pdbadmin/customer/

You will get the list of your customers in json format!

# License
To download and run ORDS, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleWebLogic/samples/1221-domain-ords-autodeploy](./) repository required to build the Docker images are, unless otherwise noted, released under [GNU GENERAL PUBLIC LICENSE Version 3](LICENSE).

# Known issues

Well, probably I have already my first case to support :). If you try something like

     $ curl -v -H "Content-Type: application/json" -d '{"id":4,"name":"Luis","lastname":"Rodriguez"}' http://localhost:7001/ords/pdbadmin/customer/

The new customer will be inserted, but you will get a **500 error response** with a message like this: **An unexpected error with the following message occurred: Length not positive**
In the WLS docker container you will see an exception like:

     SEVERE: Length not positive
     java.lang.AssertionError: Length not positive
	at oracle.jdbc.driver.NumberCommonAccessor.getBigDecimal(NumberCommonAccessor.java:2342)

It looks like there is an issue if we have a **NUMBER** as a primary key in our table. 

# Acknowledgments

Thanks [Martin Giffy D'Souza](https://github.com/martindsouza) for this fantastic example [Oracle REST Data Services on Docker](https://github.com/oracle/docker-images/tree/master/OracleRestDataServices)
Thanks [Damian Radoslaw Moskalik](https://www.linkedin.com/in/damian-moskalik/) for showing me the magic path to REST and ORDS ;)

# Copyright
Copyright (c) 2017 CERN
