Oracle GoldenGate Veridata on Docker

This Docker configuration has been used to create the Oracle GoldenGate Veridata image. Providing this OGG Veridata image facilitates the configuration and environment set up for DevOps users. This project includes the creation of an OGG Veridata domain and agent.

How to build

Please use https://container-registry.oracle.com to pull the prerequisites images.

docker login container-registry.oracle.com

1) FMW Infrastructure

Pull the Oracle FMW Infra Docker image

docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4-210701

2) Oracle Database

Oracle Database is required to install OGG Veridata repository.You can use an existing Oracle Database or pull Oracle DB Image.

docker pull container-registry.oracle.com/database/enterprise:19.3.0.0

3) OGG Veridata Installer

Download the OGG Veridata 12.2.1.4.0 Installer.

https://www.oracle.com/middleware/technologies/goldengate-downloads.html

4) Latest Bundle Patch (optional but recommended)
 
Download the latest bundle patch.

5) Run buildDockerImage.sh

Usage: buildDockerImage.sh -v [version]
Builds a Docker Image for Oracle GoldenGate Veridata.

Parameters:
-v: Release version to build. Default is 12.2.1.4.0
-i: OGG Veridata Installer zip file
-f: FMW Release version.Default is 12.2.1.4-210701
-p: Patch file
-h: Help

e.g.
buildDockerImage.sh -v 12.2.1.4-210630 -i fmw_12.2.1.4.0_ogg_Disk1_1of1.zip -p p32761281_122140_Generic.zip


How to run OGG Veridata Server

1) Create Docker Bridge

e.g.
docker network create -d bridge VdtBridge

2) Oracle Database

Make sure the Database is running on the network ,created earlier, using --network.

3) OGG Veridata Admin Server

Edit vdt.env file and execute run_admin_server.sh.

4) OGG Veridata Managed Server

Edit vdt.env file and execute run_managed_server.sh.


5) OGG Veridata Agent

Edit vdtagent.env and execute run_agent.sh.










