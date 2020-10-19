Building an Oracle Identity Governance Image using Dockerfile Samples
======================================================================

Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This image includes binaries for Oracle Identity Governance (OIG) Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OIG specific Managed Servers.

***Image***: oracle/oig:<version; example:12.2.1.4.0>

## Prerequisites
The following prerequisites are necessary before building OIG Docker images:

* A working installation of Docker 18.03 or later

## Hardware Requirements

| Hardware  | Size                                              |
| :-------- | :-------------------------------------------------|
| RAM       | Min 16GB                                          |
| Disk Space| Min 50GB (ensure 10G+ available in Docker Home)   |


## How to build

This project offers a sample Dockerfile and scripts to build an Oracle Identity Governance 12cPS4 (12.2.1.4) image. 

Building your own OIG image involves the following steps:

* Pulling the Oracle SOA 12.2.1.4 image
* Downloading the OIG Docker files
* Downloading the 12.2.1.4.0 Identity Management shiphome and Patches
* Building the OIG image


	
### Pulling the Oracle SOA 12.2.1.4 image

  1. Launch a browser and access the [Oracle Container Registry](https://container-registry.oracle.com/).
  2. Click **Sign In** and login with your username and password.
  3. In the **Search** field enter **soasuite** and press Enter.
  4. Click **soasuite** Oracle SOA Suite.
  5. In the **Terms and Conditions** box, select Language as **English**. Click **Continue** and ACCEPT "**Terms and Restrictions**".
  6. On your Docker environment login to the Oracle Container Registry and enter your Oracle SSO username and password when prompted:
  
    $ docker login container-registry.oracle.com
    Username: <username>
    Password: <password>
   
   For example:
   
    $ docker login container-registry.oracle.com
    Username: joe.bloggs@example.com
    Password:
    Login Succeeded

  8. Pull the latest soasuite image:
  
    $ docker pull container-registry.oracle.com/middleware/soasuite:12.2.1.4
	
   The output should look similar to the following:
   
    Trying to pull repository container-registry.oracle.com/middleware/soasuite ...
    12.2.1.4: Pulling from container-registry.oracle.com/middleware/soasuite
    bce8f778fef0: Already exists
    22d5d74b4d76: Pull complete
    666dccc4b57a: Pull complete
    80745fc9ee3c: Pull complete
    330be4fba4b8: Pull complete
    98abb7fffaf5: Pull complete
    1a4ca5ca35b5: Pull complete
    67d3ca48ddaf: Pull complete
    Digest: sha256:6f9b1985e6ce9dbc81f2b9ace210f5ab3e791874ffa9337888f9d788d47a35be
    Status: Downloaded newer image for container-registry.oracle.com/middleware/soasuite:12.2.1.4
    container-registry.oracle.com/middleware/soasuite:12.2.1.4
	
  9. Run the `docker tag` command to tag the image as follows:
  
    docker tag container-registry.oracle.com/middleware/soasuite:12.2.1.4 fmw-soa:12.2.1.4.0
	
   No output is returned to the screen.

  10. Run the `docker images` command to show the image is installed into the repository. The output should look similar to this:
	
	$ docker images
	
    REPOSITORY                                                    TAG                 IMAGE ID            CREATED             SIZE
    fmw-soa                                                       12.2.1.4.0          6d61b77a1e9c        2 weeks ago         4.55GB
    container-registry.oracle.com/middleware/soasuite             12.2.1.4            6d61b77a1e9c        2 weeks ago         4.55GB

### Downloading the OIG Docker files

  1. Make a work directory to place the OIG Docker files:
     
	$ mkdir <work directory>
	
  2. Download the OIG Docker files from the OIG [repository](https://github.com/oracle/docker-images/) by running the following command:
   
    $ cd <work directory>
	$ git clone https://github.com/oracle/docker-images/


### Downloading the 12.2.1.4.0 Identity Management shiphome and Patches

  1. Download the [Oracle Identity and Access Management 12cPS4 software](https://www.oracle.com/middleware/technologies/identity-management/downloads.html) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_idm_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_idm.jar` to `<work directory>/docker-images/OracleIdentityManagement/dockerfiles/12.2.1.4.0/`:
    
	$ unzip fmw_12.2.1.4.0_idm_Disk1_1of1.zip
    $ cp fmw_12.2.1.4.0_idm.jar <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_idm_generic.jar
	
   **Note**: The filename must be changed to `fmw_12.2.1.4.0_idm_generic.jar` when copying to the 12.2.1.4.0 directory.	
   
  2. Create the following directories under the `12.2.1.4.0` directory:
	
	$ mkdir -p <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches
	$ mkdir -p <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch
	
  3. View the latest `manifest.<date>.properties` from this [repository](./imagetool/12.2.1.4.0).	
  
     Look at the `[XXXX_PATCH]` sections and download the one off patches referenced. For example, the `manifest.oig.july2020.properties` below shows the following required patches under `[INFRA_PATCH]`, `[SOA_PATCH]`, `[OSB_PATCH]` and `[IDM_PATCH]`:     
	  
    [JDK]
    jdk-8u261-linux-x64.tar.gz

    [INFRA]
    fmw_12.2.1.4.0_infrastructure.jar

    [INFRA_PATCH]
    p28186730_139424_Generic.zip:Opatch
    p31537019_122140_Generic.zip:WLS
    p31544353_122140_Linux-x86-64.zip:WLS
    p31470730_122140_Generic.zip:COH
    p31488215_122140_Generic.zip:JDEV
    p31403376_122140_Generic.zip:OWCC

    [SOA]
    fmw_12.2.1.4.0_soa.jar

    [SOA_PATCH]
    p31396632_122140_Generic.zip:SOA
	p31287540_122140_Generic.zip:SOA

    [OSB]
    fmw_12.2.1.4.0_osb.jar
	
    [OSB_PATCH]
    p30779352_122140_Generic.zip:OSB
    p30680769_122140_Generic.zip:OSB

    [IDM]
    fmw_12.2.1.4.0_idm.jar

    [IDM_PATCH]
    p31537918_122140_Generic.zip:OIM
    p31497461_12214200624_Generic.zip:OIM
   
   
  6. Download any patches listed in the manifest file from [My Oracle Support](https://support.oracle.com).

  7. Copy any `Opatch` patches to `<work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch/`.
     **Note**: Only copy the opatch patch if the version listed in the manfiest file is different to p28186730_139424_Generic.zip.
  
  8. Copy the rest of the patches to `<work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches/`.
  
  9. Run the following command to change the permissions on the patch files: 
  
    $ chmod 644 <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/patches/*
	$ chmod 644 <work directory>/docker-images/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/opatch_patch/*	
	
	
### Building the Oracle Identity Governance 12.2.1.x image

  1. Run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    $ export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    $ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>
	
  2. Run the following command to build the OIG docker image:

    $ cd <work directory>/docker-images/OracleIdentityGovernance/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

   The output should look similar to the following:
    
    version --> 12.2.1.4.0
    Proxy settings were found and will be used during build.
    Building image 'oracle/oig:12.2.1.4.0' ...
    Proxy Settings ' --build-arg http_proxy=http://proxy.example.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg'
    Sending build context to Docker daemon  1.471GB
    Step 1/15 : FROM fmw-soa:12.2.1.4.0
     ---> 6d61b77a1e9c
    Step 2/15 : ENV FMW_JAR=fmw_12.2.1.4.0_idm_generic.jar     ORACLE_HOME=/u01/oracle     PATCH_DIR=/tmp/patches     OPATCH_PATCH_DIR=/tmp/opatch     OPATCH_NO_FUSER=true     USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom"     PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin     DOMAIN_NAME="${DOMAIN_NAME:-base_domain}"     DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"     DOMAIN_HOME="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"/"${DOMAIN_NAME:-base_domain}"     ADMIN_PORT="${ADMIN_PORT:-7001}"     SOA_PORT="${SOA_PORT:-8001}"     OIM_PORT="${OIM_PORT:-14000}"     OIM_SSL_PORT="${OIM_SSL_PORT:-14002}"     PATH=$PATH:/u01/oracle     DOMAIN_TYPE="oim"
     ---> Running in 59655accf31d
    Removing intermediate container 59655accf31d
     ---> 0eb78124edf2
    Step 3/15 : USER root
     ---> Running in 48cba833b3b4
    Removing intermediate container 48cba833b3b4
     ---> 573b2530edfe
    Step 4/15 : RUN mkdir -p /u01 &&     mkdir -p /u01/oracle/dockertools &&     mkdir ${PATCH_DIR} &&     mkdir ${OPATCH_PATCH_DIR} &&     chown -R oracle:oracle /u01 &&     chown -R oracle:oracle ${PATCH_DIR} &&     chown -R oracle:oracle ${OPATCH_PATCH_DIR}
     ---> Running in 8e65daf57774
    Removing intermediate container 8e65daf57774
     ---> 50704c82cdd8
    Step 5/15 : COPY *.response oraInst.loc fmw_12.2.1.4.0_idm_generic* /u01/
     ---> 6cd214ffc79b
    Step 6/15 : COPY container-scripts/* /u01/oracle/dockertools/
     ---> dfeefa7d7a1e
    Step 7/15 : COPY --chown=oracle:oracle Dockerfile patches/* ${PATCH_DIR}/
     ---> bec71e0e4f4d
    Step 8/15 : COPY --chown=oracle:oracle Dockerfile opatch_patch/* ${OPATCH_PATCH_DIR}/
     ---> 205130bae6f9
    Step 9/15 : RUN chmod a+xr /u01/oracle/dockertools/*.*
     ---> Running in ae73e60c7f6f
    Removing intermediate container ae73e60c7f6f
     ---> ea4004cf8c17
    Step 10/15 : USER oracle
     ---> Running in 93e8966063f6
    Removing intermediate container 93e8966063f6
     ---> be6bd1c091d1
    Step 11/15 : RUN cd /u01 &&  $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/idmqs.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME &&  rm -f /u01/*.jar /u01/oraInst.loc /u01/*.response  rm -f ${OPATCH_PATCH_DIR}/Dockerfile &&  rm -f ${PATCH_DIR}/Dockerfile
     ---> Running in 20f2db667806
    Launcher log file is /tmp/OraInstall2020-10-19_01-17-47PM/launcher2020-10-19_01-17-47PM.log.
    Extracting the installer . . . . . . Done
    Checking if CPU speed is above 300 MHz.   Actual 2294.876 MHz    Passed
    Checking swap space: must be greater than 512 MB.   Actual 15999 MB    Passed
    Checking if this platform requires a 64-bit JVM.   Actual 64    Passed (64-bit not required)
    Checking temp space: must be greater than 300 MB.   Actual 28676 MB    Passed
    Preparing to launch the Oracle Universal Installer from /tmp/OraInstall2020-10-19_01-17-47PM
    Log: /tmp/OraInstall2020-10-19_01-17-47PM/install2020-10-19_01-17-47PM.log
    Setting ORACLE_HOME...
    Copyright (c)  2010, 2019, Oracle and/or its affiliates. All rights reserved.
    Reading response file..
    Skipping Software Updates
    Validations are disabled for this session.
    Verifying data
    Copying Files
    Percent Complete : 10
    Percent Complete : 20
    Percent Complete : 30
    Percent Complete : 40
    Percent Complete : 50
    Percent Complete : 60
    Percent Complete : 70
    Percent Complete : 80
    Percent Complete : 90
    Percent Complete : 100
 
    The installation of Oracle Fusion Middleware 12c Identity and Access Management 12.2.1.4.0 completed successfully.
    Logs successfully copied to /u01/oracle/.inventory/logs.
    Removing intermediate container 20f2db667806
     ---> b75e69778dec
    Step 12/15 : WORKDIR ${ORACLE_HOME}
     ---> Running in 64d16739266e
    Removing intermediate container 64d16739266e
     ---> a93d9e3e4b8b
    Step 13/15 : RUN opatchzip=`ls ${OPATCH_PATCH_DIR}/p*.zip 2>/dev/null`;     if [ ! -z "$opatchzip" ]; then       cd ${OPATCH_PATCH_DIR};        echo -e "\nBelow patch present in opatch_patch directory. Applying this patch:" ;       ls p*.zip ;       echo -e "" ;       opatchfile=`ls p*.zip` ;       $JAVA_HOME/bin/jar xf $opatchfile ;       $JAVA_HOME/bin/java -jar ${OPATCH_PATCH_DIR}/6880880/opatch_generic.jar -silent oracle_home=$ORACLE_HOME;       if [ $? -ne 0 ]; then         echo "Applying patch to opatch Failed" ;         exit 1 ;       fi;       cd /tmp;       rm  ${OPATCH_PATCH_DIR}/*.zip;       rm -r ${OPATCH_PATCH_DIR}/;     fi
     ---> Running in 9790e875024d
    Removing intermediate container 9790e875024d
     ---> 0e07de14b0b2
    Step 14/15 : RUN patchzips=`ls ${PATCH_DIR}/p*.zip 2>/dev/null`;     if [ ! -z "$patchzips" ]; then       cd ${PATCH_DIR};        echo -e "\nBelow patches present in patches directory. Applying these patches:";       ls p*.zip;       echo -e "";       $ORACLE_HOME/OPatch/opatch napply -silent -oh $ORACLE_HOME -jre $JAVA_HOME -phBaseDir ${PATCH_DIR};       if [ $? -ne 0 ]; then         echo "opatch apply Failed";         exit 1;       fi;       $ORACLE_HOME/OPatch/opatch util cleanup -silent -oh ${ORACLE_HOME};       if [ $? -ne 0 ]; then         echo "opatch cleanup Failed";         exit 1;       fi;       cd /tmp;       rm ${PATCH_DIR}/*.zip;       rm -r ${PATCH_DIR}/;       rm -rf ${ORACLE_HOME}/cfgtoollogs/opatch/*;       echo -e "\nPatches applied in OIG Oracle Home are:";       cd $ORACLE_HOME/OPatch;       $ORACLE_HOME/OPatch/opatch lspatches;     else       echo -e "\nNo patches present in patches directory. Skipping patch application.";     fi
     ---> Running in 04434d5f71f4

    Below patches present in patches directory. Applying these patches:
    p30680769_122140_Generic.zip
    p30779352_122140_Generic.zip
    p31287540_122140_Generic.zip
    p31396632_122140_Generic.zip
    p31403376_122140_Generic.zip
    p31470730_122140_Generic.zip
    p31488215_122140_Generic.zip
    p31497461_12214200624_Generic.zip
    p31537019_122140_Generic.zip
    p31537918_122140_Generic.zip
    p31544353_122140_Linux-x86-64.zip

    Oracle Interim Patch Installer version 13.9.4.2.4
    Copyright (c) 2020, Oracle Corporation.  All rights reserved.


    Oracle Home       : /u01/oracle
    Central Inventory : /u01/oracle/.inventory
       from           : /u01/oracle/oraInst.loc
    OPatch version    : 13.9.4.2.4
    OUI version       : 13.9.4.0.0
    Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-10-19_13-19-28PM_1.log


    OPatch detects the Middleware Home as "/u01/oracle"

    Verifying environment and performing prerequisite checks...

    The following patches are duplicate and are skipped:
    [ 122145 31488215 31537019  ]

    OPatch continues with these patches:   31537918  30680769  30779352  31287540  31396632  31403376  31497461  31544353

    Do you want to proceed? [y|n]
    Y (auto-answered by -silent)
    User Responded with: Y
    All checks passed.

    Please shutdown Oracle instances running out of this ORACLE_HOME on the local system.
    (Oracle Home = '/u01/oracle')


    Is the local system ready for patching? [y|n]
    Y (auto-answered by -silent)
    User Responded with: Y
    Backing up files...
    Applying interim patch '31537918' to OH '/u01/oracle'
    ApplySession: Optional component(s) [ oracle.oim.remotemanager, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.

    Patching component oracle.oim.server, 12.2.1.4.0...

    Patching component oracle.oim.server, 12.2.1.4.0...

    Patching component oracle.oim.designconsole, 12.2.1.4.0...
    Applying interim patch '30680769' to OH '/u01/oracle'

    Patching component oracle.osb.server, 12.2.1.4.0...

    Patching component oracle.osb.server, 12.2.1.4.0...
    Applying interim patch '30779352' to OH '/u01/oracle'

    Patching component oracle.servicebus.plugins, 12.2.1.4.0...

    Patching component oracle.osb.server, 12.2.1.4.0...
    Applying interim patch '31287540' to OH '/u01/oracle'
    ApplySession: Optional component(s) [ oracle.fmwconfig.common.wls.shared, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.

    Patching component oracle.fmwconfig.common.wls.shared.internal, 12.2.1.4.0...
    Applying interim patch '31396632' to OH '/u01/oracle'
    ApplySession: Optional component(s) [ oracle.bpm.processspaces, 12.2.1.4.0 ] , [ oracle.integration.bpm, 12.2.1.4.0 ] , [ oracle.mft.apachemina, 2.0.4.0.1 ] , [ oracle.bpm.mgmt, 12.2.1.4.0 ] , [ oracle.soa.workflow.wc, 12.2.1.4.0 ] , [ oracle.mft.bouncycastle, 1.46.0.0.1 ] , [ oracle.mft.bouncycastle, 1.46.0.0.1 ] , [ oracle.mft, 12.2.1.4.0 ] , [ oracle.mft, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.

    Patching component oracle.rcu.soainfra, 12.2.1.4.0...

    Patching component oracle.rcu.soainfra, 12.2.1.4.0...

    Patching component oracle.bpm.addon, 12.2.1.4.0...

    Patching component oracle.integration.bam, 12.2.1.4.0...

    Patching component oracle.integration.soainfra, 12.2.1.4.0...

    Patching component oracle.integration.soainfra, 12.2.1.4.0...
 
    Patching component oracle.bpm.plugins, 12.2.1.4.0...

    Patching component oracle.soa.all.client, 12.2.1.4.0...

    Patching component oracle.mft.client, 12.2.1.4.0...

    Patching component oracle.soa.procmon, 12.2.1.4.0...

    Patching component oracle.soacommon.plugins, 12.2.1.4.0...

    Patching component oracle.soa.common.adapters, 12.2.1.4.0...
    Applying interim patch '31403376' to OH '/u01/oracle'

    Patching component oracle.webcenter.wccore, 12.2.1.4.0...
    Applying interim patch '31497461' to OH '/u01/oracle'
    ApplySession: Optional component(s) [ oracle.oim.remotemanager, 12.2.1.4.0 ]  not present in the Oracle Home or a higher version is found.

    Patching component oracle.oim.server, 12.2.1.4.0...

    Patching component oracle.oim.designconsole, 12.2.1.4.0...
    Applying interim patch '31544353' to OH '/u01/oracle'

    Patching component oracle.adr, 12.1.2.0.0...
    Patches 31537918,30680769,30779352,31287540,31396632,31403376,31497461,31544353 successfully applied.
    Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2020-10-19_13-19-28PM_1.log

    OPatch succeeded.
    Oracle Interim Patch Installer version 13.9.4.2.4
    Copyright (c) 2020, Oracle Corporation.  All rights reserved.


    Oracle Home       : /u01/oracle
    Central Inventory : /u01/oracle/.inventory
       from           : /u01/oracle/oraInst.loc
    OPatch version    : 13.9.4.2.4
    OUI version       : 13.9.4.0.0
    Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-10-19_13-26-07PM_1.log


    OPatch detects the Middleware Home as "/u01/oracle"

    Invoking utility "cleanup"
    OPatch will clean up 'restore.sh,make.txt' files and 'scratch,backup' directories.
    You will be still able to rollback patches after this cleanup.
    Do you want to proceed? [y|n]
    Y (auto-answered by -silent)
    User Responded with: Y

    Backup area for restore has been cleaned up. For a complete list of files/directories
    deleted, Please refer log file.

    OPatch succeeded.

    Patches applied in OIG Oracle Home are:
    31544353;One-off
    31497461;One-off
    31403376;WebCenter Core Bundle Patch 12.2.1.4.200526
    31396632;SOA Bundle Patch 12.2.1.4.200524
    31287540;One-off
    30779352;OSB Bundle Patch 12.2.1.4.200117
    30680769;One-off
    31537918;OIM BUNDLE PATCH 12.2.1.4.200624
    31488215;ADF BUNDLE PATCH 12.2.1.4.200613
    31537019;WLS PATCH SET UPDATE 12.2.1.4.200624
    122145;Bundle patch for Oracle Coherence Version 12.2.1.4.5

    OPatch succeeded.
    Removing intermediate container 04434d5f71f4
     ---> a1b93666eec6
    Step 15/15 : CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
     ---> Running in 94cd000b0c83
    Removing intermediate container 94cd000b0c83
     ---> b7073c584105
    Successfully built b7073c584105
    Successfully tagged oracle/oig:12.2.1.4.0

      Oracle OIM suite Docker Image for version: 12.2.1.4.0 is ready to be extended.

        --> oracle/oig:12.2.1.4.0

      Build completed in 746 seconds.

	  

  3. Run the `docker images` command to show the OIG image is installed into the repository:
    
	$ docker images
    
   The output should look similar to the following:
   
    REPOSITORY                                                  TAG             IMAGE ID      CREATED             SIZE
    oracle/oig                                                  12.2.1.4.0      b7073c584105  3 minutes ago       7.88GB
	container-registry.oracle.com/soasuite                      2.2.1.4-200612  9e9262639994  6 weeks ago         2.32GB
    oracle/soasuite                                             12.2.1.4.0      9e9262639994  6 weeks ago         2.32GB

   The OIG docker image is now built successfully! 
   
   To create OIG Docker containers refer to the **OIG Docker Container Configuration** below.



## OIG Docker Container Configuration
 
 To configure the OIG Docker Containers follow the tutorial [Creating Oracle Identity Governance Docker Containers](https://docs.oracle.com/en/middleware/idm/identity-governance/12.2.1.4/tutorial-oig-docker/)

## OIG Kubernetes Configuration

To configure the OIG Containers with Kubernetes see the [Oracle Identity Governance on Kubernetes](https://oracle.github.io/fmw-kubernetes/oig/) documentation. 
 
## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.
	
	
