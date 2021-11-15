
# Oracle GoldenGate (OGG) Veridata

## Overview

This Docker configuration has been used to create the Oracle GoldenGate Veridata image. The README facilitates the configuration and environment set up for DevOps users. This project includes the creation of an Oracle GoldenGate Veridata domain and agent.


## Prerequisites

Use the docker network command to create a network for the Admin, Managed Server and optional repository database (if necessary).

`docker network create -d bridge VdtBridge`

## Building the Docker Image

1. Pull the Oracle FMW Infrastructure Docker image:

 https://github.com/oracle/docker-images/tree/main/OracleFMWInfrastructure/dockerfiles/12.2.1.4

Use `docker tag` to tag it to `oracle/fmw-infrastructure:12.2.1.4.0-210701`

2. Oracle Database:

Oracle Database is required to install Oracle GoldenGate Veridata repository.
You can use an existing Oracle Database or build a Oracle Database image.

Build and deploy an Oracle Database container using the provided scripts in the following link:

https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance


3. Oracle GoldenGate Veridata Installer:

Download the Oracle GoldenGate Veridata 12.2.1.4.0 Installer in to your local directory from the following location:

https://www.oracle.com/middleware/technologies/goldengate-downloads.html


4. Latest Bundle Patch (optional but recommended)
 
1. Download the latest bundle patch. Go to https://support.oracle.com and login. 
2. Navigate to *Patch & Updates* and search for product patch.
3. Run `buildContainerImage.sh`

```bash
#!/bin/bash

Usage: buildContainerImage.sh -v [version]
Builds a container Image for Oracle GoldenGate Veridata.

Parameters:
-v: Release version to build. Default is 12.2.1.4.0
-i: OGG Veridata Installer zip file location
-f: FMW Release version.Default is 12.2.1.4-210701
-p: Patch file
-h: Help
```
For example: 
`buildContainerImage.sh -v 12.2.1.4-210630 -i fmw_12.2.1.4.0_ogg_Disk1_1of1.zip -p p32761281_122140_Generic.zip`


## How to Run Oracle GoldenGateVeridata Server

1. Oracle Database

Make sure the Database is running on the network, created earlier, using `--network`.
This is required when your Oracle Database repository server is running in a container.

2. Oracle GoldenGate Veridata Admin Server and Managed Server

Edit `./vdt.env` file. Following list of properties are required:

*DATABASE_HOST*
*DATABASE_PORT*
*DATABASE_SERVICE*
*SCHEMA_PREFIX*
*DATABASE_USER*
*DATABASE_PASSWORD*
*VERIDATA_USER*
*DOMAIN_HOST_VOLUME*

Start a container to launch the Administration Server and Veridata Managed Servers from the image created earlier. To facilitate running, the following scripts are provided:
`run_admin_server.sh`,`run_managed_server.sh`.

To run the Admin Server, execute the following:

`docker run --name ${ADMIN_CONTAINER_NAME} -it --network=VdtBridge -p 7001:7001 --env-file vdt.env -v ${DOMAIN_HOST_VOLUME}:/u01/oracle/user_projects oracle/oggvdt:12.2.1.4.0 createOrStartVdtDomain.sh`

To run a Veridata Managed Server, execute the following:

`docker run --name ${VERIDATA_CONTAINER_NAME} -it --network=VdtBridge -p 7003:7003 --env-file vdt.env --volumes-from ${adminhost} oracle/oggvdt:12.2.1.4.0 startManagedServer.sh`

Note: The Oracle GoldenGate Veridata domain is created during the first run of the container before the Admin Server is started. Subsequent runs will only start the Admin Server.
Oracle recommends that the `vdt.env` file be deleted or secured after the container and WebLogic Server are started so that the user name and password are not inadvertently exposed.


3. Oracle GoldenGate Veridata Agent

1. Edit `./vdtagent.env`. Following list of properties are required

*AGENT_PORT*
*AGENT_JDBC_URL*
*AGENT_HOST_VOLUME*

2. Start a container to launch the Veridata Agent from the image created earlier. To facilitate running, the following script has is being provided `run_agent.sh`.

3. To run a Veridata Agent, execute:

`docker run -d -p ${AGENT_PORT}:${AGENT_PORT} --env-file vdtagent.env -v ${AGENT_HOST_VOLUME}:/u01/oracle/vdt_agent --name ${agenthost} --network=VdtBridge oracle/oggvdt:12.2.1.4 createOrStartVdtAgent.sh`

# Copyright

Copyright (c) 2021 Oracle and/or its affiliates.OGG Veridata 12.2.1.4.0 Installer