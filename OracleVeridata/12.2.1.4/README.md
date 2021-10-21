# Oracle GoldenGate (OGG) Veridata

This Docker configuration has been used to create the Oracle GoldenGate Veridata image. Providing this OGG Veridata image facilitates the configuration and environment set up for DevOps users. This project includes the creation of an OGG Veridata domain and agent.


## Prerequisites

Please use https://container-registry.oracle.com to pull the images.

`docker login container-registry.oracle.com`

For more information please check https://container-registry.oracle.com


## How to build

1. FMW Infrastructure

Pull the Oracle FMW Infra Docker image

`docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210701`

Please use *docker tag* to tag it to *oracle/fmw-infrastructure:12.2.1.4.0-210701*

2. Oracle Database

Oracle Database is required to install OGG Veridata repository.
You can use an existing Oracle Database or build a Oracle Database image.

For building a Oracle Database image use the following command

`docker pull container-registry.oracle.com/database/enterprise:19.3.0.0`

For more information please check *Database* section in

https://container-registry.oracle.com


3. OGG Veridata Installer

Download the OGG Veridata 12.2.1.4.0 Installer.

https://www.oracle.com/middleware/technologies/goldengate-downloads.html



4. Latest Bundle Patch (optional but recommended)
 
Download the latest bundle patch. Use the support website and login. Navigate to *Patch & Updates* and search for product patch.

https://support.oracle.com


5. Run `buildContainerImage.sh`

Usage: buildContainerImage.sh -v [version]
Builds a container Image for Oracle GoldenGate Veridata.

Parameters:
-v: Release version to build. Default is 12.2.1.4.0
-i: OGG Veridata Installer zip file location
-f: FMW Release version.Default is 12.2.1.4-210701
-p: Patch file
-h: Help

e.g.

`buildDockerImage.sh -v 12.2.1.4-210630 -i fmw_12.2.1.4.0_ogg_Disk1_1of1.zip -p p32761281_122140_Generic.zip`


## How to run OGG Veridata Server

1. Create Docker network

docker network create -d bridge VdtBridge



2. Oracle Database

Make sure the Database is running on the network ,created earlier, using --network.
This is need in case you have container image of Oracle Database as repository. 

3. OGG Veridata Admin Server and Managed Server

Edit `vdt.env file` . Following list of properties are required

*DATABASE_HOST*
*DATABASE_PORT*
*DATABASE_SERVICE*
*SCHEMA_PREFIX*
*SCHEMA_PASSWORD*
*DATABASE_USER*
*DATABASE_PASSWORD*
*VERIDATA_USER*
*VERIDATA_PASSWORD*
*DOMAIN_HOST_VOLUME*

Execute `run_admin_server.sh` to run the Admin server.

Note: Only for the  first time this script will also install the Veridata domain. Subsequent runs will only start the Admin server.

After starting of the Admin Server execute run_managed_server.sh to run the Veridata Server. 

Note: Oracle recommends that the `vdt.env` file be deleted or secured after the container and 
WebLogic Server are started so that the user name and password are not inadvertently exposed.


4. OGG Veridata Agent

Edit `vdtagent.env` . Following list of properties are required

Execute `run_agent.sh` to start the Agent.










