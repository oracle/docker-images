Building an Oracle Access Management Image using Dockerfile Samples
==========================================================================
Sample Docker configurations to facilitate installation, configuration, and environment setup for Docker users. This Image includes binaries for Oracle Access Management (OAM) Release 12.2.1.4.0 and it has capability to create FMW Infrastructure domain and OAM specific Managed Servers.

***Image***: oracle/oam:<version; example:12.2.1.4.0>

## Prerequisites
The following prerequisites are necessary before building OAM Docker images:

* A working installation of Docker 18.03 or later

## Prerequisites for OAM on Kubernetes

Refer to the [Prerequisites](https://oracle.github.io/fmw-kubernetes/oam/prerequisites) in the Oracle Access Management Kubernetes documentation.


## How to build
This project offers a sample Dockerfile and scripts to build an Oracle Access Management 12cPS4 (12.2.1.4) image. 

Building your own OAM image involves the following steps:

* Pulling the Oracle JDK Base Image
* Pulling the Oracle FMW Infrastructure 12.2.1.4 image
* Downloading the OAM Docker files
* Downloading the 12.2.1.4.0 Identity Management shiphome and Patches
* Building the OAM image


### Pulling the Oracle JDK (Server JRE) base image

  1. Launch a browser and access the [Oracle Container Registry](https://container-registry.oracle.com/).
  2. Click **Sign In** and login with your username and password.
  3. In the **Search** field enter **serverjre** and press Enter.
  4. Click **serverjre** Oracle Java SE (Server JRE).
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
  
  7. Pull the serverjre image:
  
    $ docker pull container-registry.oracle.com/java/serverjre:8
	
   The output should look similar to the following:
   
    Trying to pull repository container-registry.oracle.com/java/serverjre ...
    8: Pulling from container-registry.oracle.com/java/serverjre
    79ccf0f4e30f: Pull complete
    e390a2324633: Pull complete
    5ad645011c2e: Pull complete
    Digest: sha256:7d67c2e1dcfe0b4a8d3a196a18034a6cd25eda91cf1397753266e97740d714d1
    Status: Downloaded newer image for container-registry.oracle.com/java/serverjre:8
    container-registry.oracle.com/java/serverjre:8

  
  8. Run the `docker tag` command to tag the image as follows:
  
    $ docker tag container-registry.oracle.com/java/serverjre:8 oracle/serverjre:8
	
   No output is returned to the screen.
   
   
### Pulling the Oracle FMW Infrastructure 12.2.1.x image

  1. Launch a browser and access the [Oracle Container Registry](https://container-registry.oracle.com/).
  2. Click **Sign In** and login with your username and password.
  3. In the **Search** field enter **fmw-infrastructure** and press Enter.
  4. Click **fmw-infrastructure** Oracle Fusion Middleware Infrastructure.
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
  
  7. Pull the latest fmw-infrastructure image:
  
    $ docker pull container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
	
   The output should look similar to the following:
   
    Trying to pull repository container-registry.oracle.com/middleware/fmw-infrastructure ...
    12.2.1.4: Pulling from container-registry.oracle.com/middleware/fmw-infrastructure
    bce8f778fef0: Pull complete
    9adc5789a738: Pull complete
    b80677728d7c: Pull complete
    abcd1f688714: Pull complete
    59760436a4c4: Pull complete
    23a18e3f8da2: Pull complete
    0e31e4e00dc9: Pull complete
    Digest: sha256:f1aa70158943af2d109dd0720f8a5bd9bfb2e7778c3570520a24a8b176d86d93
    Status: Downloaded newer image for container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
    container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
	
  8. Run the `docker tag` command to tag the image as follows:
  
    docker tag container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4 oracle/fmw-infrastructure:12.2.1.4.0
	
   No output is returned to the screen.

  9. Run the `docker images` command to show the image is installed into the repository. The output should look similar to this:
	
	$ docker images
	
    REPOSITORY                                                    TAG                 IMAGE ID            CREATED             SIZE
    container-registry.oracle.com/middleware/fmw-infrastructure   12.2.1.4            760157811a73        4 weeks ago         2.33GB
    oracle/fmw-infrastructure                                     12.2.1.4.0          760157811a73        4 weeks ago         2.33GB
    container-registry.oracle.com/java/serverjre                  8                   da8a8a240247        2 months ago        305MB
    oracle/serverjre                                              8                   da8a8a240247        2 months ago        305MB
	

	
### Downloading the OAM Docker files

  1. Make a work directory to place the OAM Docker files:
     
	$ mkdir <work directory>
	
  2. Download the OAM Docker files from the OAM [repository](https://github.com/oracle/docker-images) by running the following command:

   
    $ cd <work directory>
	$ git clone https://github.com/oracle/docker-images

### Downloading the 12.2.1.4.0 Identity Management shiphome and Patches

  1. Download the [Oracle Identity and Access Management 12cPS4 software](https://www.oracle.com/middleware/technologies/identity-management/downloads.html) to a stage directory. Unzip the downloaded `fmw_12.2.1.4.0_idm_Disk1_1of1.zip` file and copy the `fmw_12.2.1.4.0_idm.jar` to `<work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/`:
    
	$ unzip fmw_12.2.1.4.0_idm_Disk1_1of1.zip
    $ cp fmw_12.2.1.4.0_idm.jar <work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/fmw_12.2.1.4.0_idm_generic.jar
	
   **Note**: The filename must be changed to `fmw_12.2.1.4.0_idm_generic.jar` when copying to the 12.2.1.4.0 directory.	
   
  2. Create the following directories under the `12.2.1.4.0` directory:
	
	$ mkdir -p <work directory>/OracleAccessManagement/dockerfiles/12.2.1.4.0/patches
	$ mkdir -p <work directory>/OracleAccessManagement/dockerfiles/12.2.1.4.0/opatch_patch
	
  3. View the latest `manifest.<date>.properties` from this [repository](./imagetool/12.2.1.4.0).	
  
     Look at the `[XXXX_PATCH]` sections and download the one off patches referenced. For example, the `manifest.oam.july2020.properties` below shows the following required patches under `[INFRA_PATCH]` and `[OAM_PATCH]`:     
 
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


    [OAM]
    fmw_12.2.1.4.0_idm_generic.jar

    [OAM_PATCH]
    p31556630_122140_Generic.zip:OAM
   
   
  6. Download any patches listed in the manifest file from [My Oracle Support](https://support.oracle.com).

  7. Copy any `Opatch` patches to `<work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/opatch_patch/`.
  
  8. Copy the rest of the patches to `<work directory>/docker/imagesOracleAccessManagement/dockerfiles/12.2.1.4.0/patches/`.
  
  9. Run the following command to change the permissions on the patch files: 
  
    $ chmod 644 <work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/patches/*
	$ chmod 644 <work directory>/docker-images/OracleAccessManagement/dockerfiles/12.2.1.4.0/opatch_patch/*
  
  
### Building the Oracle Access Management 12.2.1.x image

  1. Run the following to set the proxy server appropriately. This is required so the build process can pull the relevant Linux packages via yum:

    $ export http_proxy=http://<proxy_server_hostname>:<proxy_server_port>
    $ export https_proxy=http://<proxy_server_hostname>:<proxy_server_port>
	
  2. Run the following command to build the OAM image:

    $ cd <work directory>/docker-images/OracleAccessManagement/dockerfiles
    $ sh buildDockerImage.sh -v 12.2.1.4.0

   The output should look similar to the following:
    
    version --> 12.2.1.4.0
    Proxy settings were found and will be used during build.
    Building image 'oracle/oam:12.2.1.4.0' ...
    Proxy Settings '--build-arg http_proxy=http://proxy.example.com:80 --build-arg http_proxy=http://proxyexample.com:80 --build-arg https_proxy=http://proxy.example.com:80 --build-arg no_proxy=localhost,127.0.0.0/8,.us.oracle.com,.oraclecorp.com,/var/run/docker.sock,10.247.94.49,10.247.94.62,10.242.241.207'
    Sending build context to Docker daemon  1.491GB
    Step 1/27 : FROM oracle/fmw-infrastructure:12.2.1.4.0 as base
     ---> 9e9262639994
    Step 2/27 : MAINTAINER OAM Development <Kaushik C>
     ---> Running in cfd0076ece84
    Removing intermediate container cfd0076ece84
     ---> 6d63b2bbb271
    Step 3/27 : ENV FMW_IDM_JAR=fmw_12.2.1.4.0_idm_generic.jar     BASE_DIR=/u01     ORACLE_HOME=/u01/oracle     PATCH_DIR=/tmp/patches     OPATCH_PATCH_DIR=/tmp/opatch     OPATCH_NO_FUSER=true     SCRIPT_DIR=/u01/oracle/dockertools     PROPS_DIR=/u01/oracle/properties     USER_PROJECTS_DIR=/u01/oracle/user_projects     DOMAIN_ROOT=/u01/oracle/user_projects/domains     DOMAIN_NAME="${DOMAIN_NAME:-oam_domain}"     DOMAIN_HOME="${DOMAIN_ROOT}"/"${DOMAIN_NAME}"     ADMIN_USER="${ADMIN_USER:-}"     ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"     CONNECTION_STRING="${CONNECTION_STRING:-OamDB:1521/orclpdb1.localdomain}"     CONTAINER_DIR=/u01/oracle/user_projects/container     ADMIN_LISTEN_HOST="${ADMIN_LISTEN_HOST:-}"     ADMIN_NAME="${ADMIN_NAME:-AdminServer}"     ADMIN_LISTEN_PORT="${ADMIN_LISTEN_PORT:-7001}"     DOMAIN_TYPE="${DOMAIN_TYPE:-oam}"     RCUPREFIX=${RCUPREFIX:-OAM01}     DB_USER=${DB_USER:-}     DB_PASSWORD=${DB_PASSWORD:-}     DB_SCHEMA_PASSWORD=${DB_SCHEMA_PASSWORD:-}     USER_MEM_ARGS=${USER_MEM_ARGS:-"-Djava.security.egd=file:/dev/./urandom"}     JAVA_OPTIONS="${JAVA_OPTIONS} -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true"     PATH=$PATH:/usr/java/default/bin:$ORACLE_HOME/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/dockertools
     ---> Running in a9d94f5b059e
    Removing intermediate container a9d94f5b059e
     ---> d4b9c4229e53
    Step 4/27 : USER root
     ---> Running in a180f9ee65e1
    Removing intermediate container a180f9ee65e1
     ---> 76787e49a7f6
    Step 5/27 : RUN mkdir -p ${BASE_DIR} &&     chmod a+xr ${BASE_DIR} && chown oracle:oracle ${BASE_DIR} &&     mkdir -p ${USER_PROJECTS_DIR} &&     chown -R oracle:oracle ${USER_PROJECTS_DIR} && chmod -R 775 ${USER_PROJECTS_DIR} &&     mkdir -p ${CONTAINER_DIR} &&     chown -R oracle:oracle ${CONTAINER_DIR} && chmod -R 775 ${CONTAINER_DIR} &&     mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} &&     mkdir -p ${PROPS_DIR} && chown oracle:oracle ${PROPS_DIR} &&     yum install -y libaio &&     yum install -y hostname &&     rm -rf /var/cache/yum &&     mkdir ${PATCH_DIR} &&     mkdir ${OPATCH_PATCH_DIR} &&     chown -R oracle:oracle ${BASE_DIR} &&     chown -R oracle:oracle ${PATCH_DIR} &&     chown -R oracle:oracle ${OPATCH_PATCH_DIR}
     ---> Running in df8d2fd3fcd9
    Loaded plugins: ovl
    Package libaio-0.3.109-13.el7.x86_64 already installed and latest version
    Nothing to do
    Loaded plugins: ovl
    Resolving Dependencies
     --> Running transaction check
    ---> Package hostname.x86_64 0:3.13-3.el7_7.1 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ================================================================================
     Package         Arch          Version                  Repository         Size
    ================================================================================
    Installing:
     hostname        x86_64        3.13-3.el7_7.1           ol7_latest         16 k

    Transaction Summary
    ================================================================================
    Install  1 Package

    Total download size: 16 k
    Installed size: 19 k
    Downloading packages:
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : hostname-3.13-3.el7_7.1.x86_64                               1/1
      Verifying  : hostname-3.13-3.el7_7.1.x86_64                               1/1
   
    Installed:
      hostname.x86_64 0:3.13-3.el7_7.1

    Complete!
    Removing intermediate container df8d2fd3fcd9
     ---> 29cfb27f18d1
    Step 6/27 : FROM base as builder
     ---> 29cfb27f18d1
    Step 7/27 : COPY --chown=oracle:oracle Dockerfile patches/* ${PATCH_DIR}/
     ---> 17437aaab618
    Step 8/27 : COPY --chown=oracle:oracle Dockerfile opatch_patch/* ${OPATCH_PATCH_DIR}/
     ---> f6c61a4b0775
    Step 9/27 : COPY container-scripts/* ${SCRIPT_DIR}/
     ---> 56e8737e2173
    Step 10/27 : COPY install/* ${BASE_DIR}/
     ---> c5c3f8b89e7c
    Step 11/27 : ADD  $FMW_IDM_JAR ${BASE_DIR}/
     ---> 203724057409
    Step 12/27 : RUN cd ${BASE_DIR} && chmod 755 *.jar &&      chmod a+xr ${SCRIPT_DIR}/* &&      chown -R oracle:oracle ${CONTAINER_DIR} && chmod -R 775 ${CONTAINER_DIR} &&      chown oracle:oracle ${SCRIPT_DIR}/*
     ---> Running in 763ecc076210
    Removing intermediate container 763ecc076210
     ---> 99fa29a17768
    Step 13/27 : USER oracle
     ---> Running in 96c756500030
    Removing intermediate container 96c756500030
     ---> 1a8bf2dc3d96
    Step 14/27 : WORKDIR ${ORACLE_HOME}
     ---> Running in 19eaaf932500
    Removing intermediate container 19eaaf932500
     ---> 7955d38e095d
    Step 15/27 : RUN cd ${BASE_DIR} &&  $JAVA_HOME/bin/java -jar ${BASE_DIR}/$FMW_IDM_JAR -silent -responseFile ${BASE_DIR}/iam.response -invPtrLoc ${ORACLE_HOME}/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=${ORACLE_HOME} &&  rm -fr ${BASE_DIR}/*.jar ${BASE_DIR}/*.response &&  rm -f ${OPATCH_PATCH_DIR}/Dockerfile &&  rm -f ${PATCH_DIR}/Dockerfile
     ---> Running in e9c7d3357679
    Launcher log file is /tmp/OraInstall2020-08-13_09-31-45AM/launcher2020-08-13_09-31-45AM.log.
    Extracting the installer . . . . . . Done
    Checking if CPU speed is above 300 MHz.   Actual 2294.876 MHz    Passed
    Checking swap space: must be greater than 512 MB.   Actual 15999 MB    Passed
    Checking if this platform requires a 64-bit JVM.   Actual 64    Passed (64-bit not required)
    Checking temp space: must be greater than 300 MB.   Actual 62692 MB    Passed
    Preparing to launch the Oracle Universal Installer from /tmp/OraInstall2020-08-13_09-31-45AM
    Log: /tmp/OraInstall2020-08-13_09-31-45AM/install2020-08-13_09-31-45AM.log
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
    ...etc
	...
    Below patch present in opatch_patch directory. Applying this patch:
    p28186730_139424_Generic.zip

    Launcher log file is /tmp/OraInstall2020-08-13_09-33-01AM/launcher2020-08-13_09-33-01AM.log.
    Extracting the installer . . . . Done
    Checking if CPU speed is above 300 MHz.   Actual 2294.876 MHz    Passed
    Checking swap space: must be greater than 512 MB.   Actual 15999 MB    Passed
    Checking if this platform requires a 64-bit JVM.   Actual 64    Passed (64-bit not required)
    Checking temp space: must be greater than 300 MB.   Actual 63168 MB    Passed
    Preparing to launch the Oracle Universal Installer from /tmp/OraInstall2020-08-13_09-33-01AM
    Installation Summary

    Disk Space : Required 34 MB, Available 63,132 MB
    Feature Sets to Install:
         Next Generation Install Core 13.9.4.0.1
         OPatch 13.9.4.2.4
         OPatch Auto OPlan 13.9.4.2.4
    Session log file is /tmp/OraInstall2020-08-13_09-33-01AM/install2020-08-13_09-33-01AM.log

    Loading products list. Please wait.
     1%
     40%
     98%
     99%

    Updating Libraries

    Starting Installations
     1%
     2%
     3%
     etc
     89%
     90%

    etc...

    The install operation completed successfully.

    Logs successfully copied to /u01/oracle/oraInventory/logs.
    Removing intermediate container 7dfeb304b049
     ---> 6ff8e03fc57c
    etc....
 
    Below patches present in patches directory. Applying these patches:
    p31470730_122140_Generic.zip
    p31488215_122140_Generic.zip
    p31537019_122140_Generic.zip
    p31544353_122140_Linux-x86-64.zip
    p31556630_122140_Generic.zip

    Oracle Interim Patch Installer version 13.9.4.2.4
    Copyright (c) 2020, Oracle Corporation.  All rights reserved.


    Oracle Home       : /u01/oracle
    Central Inventory : /u01/oracle/oraInventory
       from           : /u01/oracle/oraInst.loc
    OPatch version    : 13.9.4.2.4
    OUI version       : 13.9.4.0.0
    Log file location : /u01/oracle/cfgtoollogs/opatch/opatch2020-08-13_09-34-18AM_1.log


    OPatch detects the Middleware Home as "/u01/oracle"

    Verifying environment and performing prerequisite checks...
    OPatch continues with these patches:   122145  31488215  31537019  31544353  31556630

    Do you want to proceed? [y|n]
    Y (auto-answered by -silent)
    User Responded with: Y
    All checks passed.

     Applying interim patch '122145' to OH '/u01/oracle'
     etc...

    Patching component oracle.oam.server, 12.2.1.4.0...
    Patches 122145,31488215,31537019,31544353,31556630 successfully applied.
    Log file location: /u01/oracle/cfgtoollogs/opatch/opatch2020-08-13_09-34-18AM_1.log

    OPatch succeeded.
    Patches applied in OAM oracle home are:
    31556630;OAM BUNDLE PATCH 12.2.1.4.200629
    31544353;One-off
    31537019;WLS PATCH SET UPDATE 12.2.1.4.200624
    31488215;ADF BUNDLE PATCH 12.2.1.4.200613
    122145;Bundle patch for Oracle Coherence Version 12.2.1.4.5

    etc....
	
	Successfully built 7296d843c766
    Successfully tagged oracle/oam:12.2.1.4.0

      Oracle OAM suite Docker Image for version: 12.2.1.4.0 is ready to be extended.

        --> oracle/oam:12.2.1.4.0

      Build completed in 786 seconds.
	  

  3. Run the `docker images` command to show the OAM image is installed into the repository:
    
	$ docker images
    
   The output should look similar to the following:
   
    REPOSITORY                                                  TAG             IMAGE ID     CREATED       SIZE
    oracle/oam                                                    12.2.1.4.0          4896be1e0f6b        6 minutes ago       4.07GB
    container-registry.oracle.com/middleware/fmw-infrastructure   12.2.1.4-200612     9e9262639994        6 weeks ago         2.32GB
    oracle/fmw-infrastructure                                     12.2.1.4.0          9e9262639994        6 weeks ago         2.32GB
    container-registry.oracle.com/java/serverjre                  8                   757bd3c830d9        3 months ago        293MB


   The OAM docker image is now built successfully! 
   
   To create OAM Docker containers refer to the **OAM Docker Container Configuration** below.



## OAM Docker Container Configuration
 
 To configure the OAM Docker Containers follow the tutorial [Creating Oracle Access Management Docker Containers](https://docs.oracle.com/en/middleware/idm/access-manager/12.2.1.4/tutorial-oam-docker/)
 
## OAM Kubernetes Configuration

To configure the OAM Containers with Kubernetes see the [Oracle Access Management on Kubernetes](https://oracle.github.io/fmw-kubernetes/oam/) documentation.

## Copyright
Copyright (c) 2020 Oracle and/or its affiliates.