# Oracle GoldenGate (OGG) Veridata

This Docker configuration has been used to create the Oracle GoldenGate Veridata image. Providing this OGG Veridata image facilitates the configuration and environment set up for DevOps users. This project includes the creation of an OGG Veridata domain and agent.


## Prerequisites

Create Docker network to run Admin,Managed server and repository Database (in case needed)

`docker network create -d bridge VdtBridge`



## How to build

1. FMW Infrastructure

Pull the Oracle FMW Infra Docker image

 https://github.com/oracle/docker-images/tree/main/OracleFMWInfrastructure/dockerfiles/12.2.1.4

Please use *docker tag* to tag it to *oracle/fmw-infrastructure:12.2.1.4.0-210701*

2. Oracle Database

Oracle Database is required to install OGG Veridata repository.
You can use an existing Oracle Database or build a Oracle Database image.

For building a Oracle Database image use the following command

https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance


3. OGG Veridata Installer

Download the Oracle GoldenGate Veridata 12.2.1.4.0 Installer to your local directory.

https://www.oracle.com/middleware/technologies/goldengate-downloads.html


4. Latest Bundle Patch (optional but recommended)
 
Download the latest bundle patch. Use the support website and login. Navigate to *Patch & Updates* and search for product patch.

https://support.oracle.com


5. Run `buildContainerImage.sh`

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
e.g.
`buildDockerImage.sh -v 12.2.1.4-210630 -i fmw_12.2.1.4.0_ogg_Disk1_1of1.zip -p p32761281_122140_Generic.zip`


## How to run OGG Veridata Server

1. Oracle Database

Make sure the Database is running on the network,created earlier,using --network.
This is needed in case you have container image of Oracle Database as repository. 

2. OGG Veridata Admin Server and Managed Server

Edit `./vdt.env` file. Following list of properties are required

*DATABASE_HOST*
*DATABASE_PORT*
*DATABASE_SERVICE*
*SCHEMA_PREFIX*
*DATABASE_USER*
*DATABASE_PASSWORD*
*VERIDATA_USER*
*DOMAIN_HOST_VOLUME*

Start a container to launch the Administration Server and Veridata Managed Servers from the image created earlier.To facilitate running we provide scripts
`run_admin_server.sh`,`run_manages_server.sh`.

To run a Admin Server, call:

`docker run --name OggVdtAdmin -it --network=VdtBridge -p 7001:7001 --env-file vdt.env -v /scratch/arnnandi/vdtdocker/domain:/u01/oracle/user_projects oracle/oggvdt:12.2.1.4.0 createOrStartVdtDomain.sh`

To run a Veridata Managed Server, call:

`docker run --name OggVdtContainer -it --network=VdtBridge -p 7003:7003 --env-file vdt.env --volumes-from OggVdtAdminContainer oracle/oggvdt:12.2.1.4.0 startManagedServer.sh`

Note: Only for the  first time this script will also install the Veridata domain.Subsequent runs will only start the Admin server.
Oracle recommends that the `vdt.env` file be deleted or secured after the container and 
WebLogic Server are started so that the user name and password are not inadvertently exposed.


3. OGG Veridata Agent

Edit `./vdtagent.env`. Following list of properties are required

*AGENT_PORT*
*AGENT_JDBC_URL*
*AGENT_HOST_VOLUME*

Start a container to launch the Veridata Agent from the image created earlier.To facilitate running we provide script `run_agent.sh`

To run a Veridata Agent, call:

`docker run -d -p 7562:7562 --env-file /scratch/arnnandi/docker-git/build-docker/build/oggvdt122140/vdtagent.env -v /scratch/arnnandi/vdtdocker/vdt_agent:/u01/oracle/vdt_agent --name OggVdtAgent --network=VdtBridge oracle/oggvdt:12.2.1.4 createOrStartVdtAgent.sh`












