Example of how to Patch a FMW Infrastructure Image
===================================================

This project offers a Dockerfile that shows how to apply a patch to the FMW Infrastructure image.  It extends the Oracle FMW Infrastructure image and applies a PSU patch to the binaries in the image. 

If this is the first time runing a FMW Infrastructure container and the domain has not been created previously you can run an Admin Server and a Managed Server containers from the patched image. If you have containers running from the unpatched FMW Infrastructure image you will need to shut them down before running the patched servers. Start by removing both the Admin Server container and the Managed Server container.  Run a new Admin Server and Managed Server container from the patched image.  

## How to Build and Run
First make sure you have built oracle/fmw-infrastructure:12.2.1.2

Then download file  p25871788_122120_Generic.zip and place it in the same directory as  this README.

    $ docker build -t fmw-infrastructure-12212-psu25871788 .

### Sample FMW Infrastructure Domain 
The image **oracle/fmw-infrastructure:12.2.1.2** will configure a **base_domain** with one Admin Server and a Managed Server with the following settings:

 * Admin Username: `weblogic`
 * Admin Password: `Auto generated` 
 * DB Schema Password: 'Auto generated'
 * DB Username: 'sys' 
 * DB Password: 'Auto Generated at runtime by DB container' 
 * RCU Prefix: 'INFRA6'
 * Oracle Linux Username: `oracle`
 * Oracle Linux Password: `welcome1`
 * Domain Name: `InfraDomain`
 * Admin Server on port: `7001`
 * Managed Server on port: `8001`
 * Production Mode: `production`
  
The patched image uses the scripts from the base FMW Infrastructure image to start the Admin Server and Managed Server.  Please make reference to the README file in **oracle/docker-images/OracleFMWInfrastructure** for detailed instructions.

## Running the Oracle FMW Infrastructure Domain Docker Image
To run a FMW Infrastructure Domain sample container, you will need the FMW Infrastructure Domain image and an Oracle Database. The Oracle Database could be remote or running in a container. If you want to run Oracle Database in a container, you can either pull the image from the [Docker Store](https://store.docker.com/images/oracle-database-enterprise-edition) or the [Oracle Container Registry](https://container-registry.oracle.com) or build your own image using the Dockerfiles and Scripts in this Git repository.

Follow the steps below:

  1. Create the docker network for the infra server to run
  
 	$ docker network create -d bridge InfraNET
  		
  2. Run the Database container to host the RCU schemas
  
 	$ docker run --detach=true --name MYInfraDB --network=InfraNET -p 1377:1521 -p 6500:5500 -e ORACLE_SID=MYInfraDB -e ORACLE_PDB=InfraPDB1 -e ORACLE_PWD=<DB Password> oracle/database:12.2.0.1-ee

      Verify that the Database is running look at the logs from the run command:
 
        $ docker logs -f <container id>

     You should see the string 

     #########################
     DATABASE IS READY TO USE!
     #########################

     The Database password is auto generated, one way to change the DB passcode 
        $ docker exec MYInfraDB ./setPassword.sh <DB password>

  
  3. Start a container to launch the Admin Server. The environment variables used to configure the InfraDomain are defined in infraDomain.env.list file. Call docker run from the **samples/12212-patch** directory where the infraDomain.env.list file is and pass the file name at runtime. To run an Admin Server container call: 

        $ docker run -d -p 9001:7001 --network=InfraNET -v $HOST_VOLUME:/u01/oracle/user_projects --name InfraAdminContainer --env-file ./infraDomain.env.list fmw-infrastructure-12212-psu25871788:latest

Where $HOST_VOLUME stands for a directory on the host where you map your domain directory and both the Admin Server and Managed Server containers can read/write to.
  4. Access the administration console

        $ docker inspect --format '{{.NewworkSettings.IPAddress}}' <container-name>
        This returns the IPAddress (example xxx.xx.x.x) of the container.  Got to your browser and enter http://xxx.xx.x.x:9001/console
        
        Since the container ports are mapped to host port, you can access using the hostname as well.
  
  5. Start a container to launch the Managed Serve. The environment variables used to run the Managed Server image are defined in the file infraserver.env.list. Call docker run from the **samples/12212-patch** directory where the infraserver.env.list file is and pass the file name at runtime. To run a Managed Server container call:

        $ docker run -d -p 9801:8001 --network=InfraNET --volumes-from InfraAdminContainer --name InfraManagedContainer --env-file ./infraServer.env.list fmw-infrastructure-12212-psu25871788:latest startManagedServer.sh

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
