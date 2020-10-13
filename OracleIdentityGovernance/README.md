# Pre-General Availability: 2020-05-13 <br><br>

# ORACLE CONFIDENTIAL. For authorized use only. Do not distribute to third parties.<br><br>


# Licensing & Copyright

## License<br>
To download and run Oracle Fusion Middleware products, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.<br><br>

All scripts and files hosted in this project and GitHub [docker-images/OracleIdentityGovernance](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.<br><br>

## Copyright<br>
Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.<br>
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl<br><br>

## Legal Notices<br>

Oracle Identity Governance (OIG) on Docker Setup Beta Readme<br>
Oracle Identity Governance 12c (12.2.1.4.0) OIG on Docker Beta Testing<br>
Pre-General Availability: 2020-05-13<br><br>

Copyright © 2020, 2020, Oracle and/or its affiliates.<br>
Primary Author: Mike Howlett<br>
Contributors: Rishi Agarwal<br>

Legal Notices<br>
This software and related documentation are provided under a license agreement containing restrictions on use and disclosure and are protected by intellectual property laws. Except as expressly permitted in your license agreement or allowed by law, you may not use, copy, reproduce, translate, broadcast, modify, license, transmit, distribute, exhibit, perform, publish, or display any part, in any form, or by any means. Reverse engineering, disassembly, or decompilation of this software, unless required by law for interoperability, is prohibited.
The information contained herein is subject to change without notice and is not warranted to be error-free. If you find any errors, please report them to us in writing.
If this is software or related documentation that is delivered to the U.S. Government or anyone licensing it on behalf of the U.S. Government, then the following notice is applicable:<br>

U.S. GOVERNMENT END USERS: Oracle programs (including any operating system, integrated software, any programs embedded, installed or activated on delivered hardware, and modifications of such programs) and Oracle computer documentation or other Oracle data delivered to or accessed by U.S. Government end users are "commercial computer software" or “commercial computer software documentation” pursuant to the applicable Federal Acquisition Regulation and agency-specific supplemental regulations. As such, the use, reproduction, duplication, release, display, disclosure, modification, preparation of derivative works, and/or adaptation of i) Oracle programs (including any operating system, integrated software, any programs embedded, installed or activated on delivered hardware, and modifications of such programs), ii) Oracle computer documentation and/or iii) other Oracle data, is subject to the rights and limitations specified in the license contained in the applicable contract. The terms governing the U.S. Government’s use of Oracle cloud services are defined by the applicable contract for such services. No other rights are granted to the U.S. Government.<br>

This software or hardware is developed for general use in a variety of information management applications. It is not developed or intended for use in any inherently dangerous applications, including applications that may create a risk of personal injury. If you use this software or hardware in dangerous applications, then you shall be responsible to take all appropriate fail-safe, backup, redundancy, and other measures to ensure its safe use. Oracle Corporation and its affiliates disclaim any liability for any damages caused by use of this software or hardware in dangerous applications.
Oracle and Java are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of their respective owners. Intel and Intel Inside are trademarks or registered trademarks of Intel Corporation. All SPARC trademarks are used under license and are trademarks or registered trademarks of SPARC International, Inc. AMD, Epyc, and the AMD logo are trademarks or registered trademarks of Advanced Micro Devices. UNIX is a registered trademark of The Open Group.
This software or hardware and documentation may provide access to or information about content, products, and services from third parties. Oracle Corporation and its affiliates are not responsible for and expressly disclaim all warranties of any kind with respect to third-party content, products, and services unless otherwise set forth in an applicable agreement between you and Oracle. Oracle Corporation and its affiliates will not be responsible for any loss, costs, or damages incurred due to your access to or use of third-party content, products, or services, except as set forth in an applicable agreement between you and Oracle.
This documentation is in pre-General Availability status and is intended for demonstration and preliminary use only. It may not be specific to the hardware on which you are using the software. Oracle Corporation and its affiliates are not responsible for and expressly disclaim all warranties of any kind with respect to this documentation and will not be responsible for any loss, costs, or damages incurred due to the use of this documentation.<br>

The information contained in this document is for informational sharing purposes only and should be considered in your capacity as a customer advisory board member or pursuant to your pre-General Availability trial agreement only. It is not a commitment to deliver any material, code, or functionality, and should not be relied upon in making purchasing decisions. The development, release, and timing of any features or functionality described in this document remains at the sole discretion of Oracle.<br>

This document in any form, software or printed matter, contains proprietary information that is the exclusive property of Oracle. Your access to and use of this confidential material is subject to the terms and conditions of your Oracle Master Agreement, Oracle License and Services Agreement, Oracle PartnerNetwork Agreement, Oracle distribution agreement, or other license agreement which has been executed by you and Oracle and with which you agree to comply. This document and information contained herein may not be disclosed, copied, reproduced, or distributed to anyone outside Oracle without prior written consent of Oracle. This document is not part of your license agreement nor can it be incorporated into any contractual agreement with Oracle or its subsidiaries or affiliates.<br>

## ORACLE CONFIDENTIAL. For authorized use only. Do not distribute to third parties.

Oracle Identity Governance (OIG) on Docker
===========================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Hardware and Software Requirements](#2-hardware-and-software-requirements)
3. [Prerequisites](#3-prerequisites)
4. [Deploy the OIG Container](#4-deploy-the-oig-container)
5. [How to Tear Down an OIG Container Deployment](#5-how-to-tear-down-an-oig-container-deployment)
6. [Appendix A: Encrypting SSO Password in config.json](#6-appendix-a-encrypting-sso-password-in-configjson)


# 1. Introduction
This project offers Dockerfiles and scripts to build an Oracle Identity Governance image based on 12cPS4 (12.2.1.4.0) release. Use this Docker Image to facilitate installation, configuration, and environment setup for DevOps users. 

Files are provided for deploying the OIG image in two use cases:

*  Deployment using an Oracle Database container.
*  Deployment using an external Oracle Database instance.

This Image refers to binaries for OIG Release 12.2.1.4.0.

***Image***: oig:latest

# 2. Hardware and Software Requirements
The Oracle Identity Governance Docker Image has been tested and is known to run on following hardware and software:

## 2.1 Hardware Requirements

| Hardware  | Size                                              |
| :-------- | :-------------------------------------------------|
| RAM       | Min 16GB                                          |
| Disk Space| Min 50GB (ensure 10G+ available in Docker Home)   |

## 2.2 Software Requirements

| Software       | Version                         | Command to verify version |
| :------------- | :----------------------------:  | :-----------------------: |
| OS             | Oracle Linux 7u5 or higher      | more /etc/oracle-release  |
| Docker         | Docker version 18.03 or higher  | docker version            |
| Docker-compose | Docker-compose 1.25.4 or higher | docker-compose version    |

**Note**: if using an external Oracle database ensure that the database used meets the requirements detailed in the OIG installation documentation:

Installing and Configuring Oracle Identity and Access Management (12.2.1.4.0)<br>
2 Preparing to Install and Configure Oracle Identity and Access Management<br>
[About Database Requirements for an Oracle Fusion Middleware Installation](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/inoam/preparing-install-and-configure-product.html#GUID-4D3068C8-6686-490A-9C3C-E6D2A435F20A)

# 3. Prerequisites

## 3.1 Load OIG Docker Image

Download the image parts from the Beta site to your host.  The downloaded parts should look similar to below:

        [dockeruser@mydockerhost]$ ls -ltr OIG_12.2.1.4.0.z*
        -rw-r--r-- 1 oracle dba 1290123387 Apr 27 03:49 OIG_12.2.1.4.0.z03
        -rw-r--r-- 1 oracle dba 1310720000 Apr 27 03:50 OIG_12.2.1.4.0.z02
        -rw-r--r-- 1 oracle dba 1310720000 Apr 27 03:53 OIG_12.2.1.4.0.z01
        -rw-r--r-- 1 oracle dba 1310720000 Apr 27 03:54 OIG_12.2.1.4.0.z00
        
**Note**: `dockeruser` and `mydockerhost` are example user/host for the purposes of this example only.  You should run all commands using your own Docker user and host values.

**Note**: `md5sum` values for these files are available in the **Instructions.txt** file provided on the Beta site.

Assemble the parts into a single zip file:

        [dockeruser@mydockerhost]$ cat OIG_12.2.1.4.0.z* > oigdockerimage.zip
        
Unzip the resulting file to get the image tarball:

        [dockeruser@mydockerhost]$ unzip oigdockerimage.zip
        Archive:  oigdockerimage.zip
        
        # ls -ltr *tar
        -rw-rw-rw- 1 oracle dba 6403137536 Apr 24 07:10 OIG_12.2.1.4.0.tar
        
Load the OIG image:

        [dockeruser@mydockerhost]$ docker load < OIG_12.2.1.4.0.tar
        5102fc2ee26e: Loading layer [==================================================>]  124.4MB/124.4MB
        ddf9ceb14f95: Loading layer [==================================================>]  10.97MB/10.97MB
        b3126971f632: Loading layer [==================================================>]  20.99kB/20.99kB
        a8b7d10f7eab: Loading layer [==================================================>]  152.2MB/152.2MB
        ac78a2dc4b22: Loading layer [==================================================>]  2.048GB/2.048GB
        4eef77e2ad88: Loading layer [==================================================>]  27.65kB/27.65kB
        d0e6b2c82b99: Loading layer [==================================================>]  382.9MB/382.9MB
        db0296c44a10: Loading layer [==================================================>]  1.566GB/1.566GB
        443112d1188c: Loading layer [==================================================>]   2.56kB/2.56kB
        c907a0de10bc: Loading layer [==================================================>]  1.358GB/1.358GB
        028f9dd7e654: Loading layer [==================================================>]  52.74kB/52.74kB
        dc297307ae3e: Loading layer [==================================================>]  52.74kB/52.74kB
        29e458e42829: Loading layer [==================================================>]  760.7MB/760.7MB
        Loaded image ID: sha256:30056bdeb48e49689ff2b2168e8d0eecc03a2a3fbc9bb65bdcc6e52b25b5b390

List the docker image:

        [dockeruser@mydockerhost]$ docker images
        REPOSITORY  TAG                 IMAGE ID            CREATED             SIZE
        <none>      <none>              30056bdeb48e        4 days ago          6.36GB

The image you are interested in is REPOSITORY=\<none> TAG=\<none>
        
Tag the image so that it can be recognised as 'oig:latest':

        [dockeruser@mydockerhost]$ docker tag <IMAGEID> oig:latest

For example: 

        [dockeruser@mydockerhost]$ docker tag 30056bdeb48e oig:latest
		
Confirm that the image is tagged as 'oig:latest':

        [dockeruser@mydockerhost]$ docker images | grep oig
        oig         latest              30056bdeb48e        4 days ago          6.36GB
        
## 3.2 Update OracleIdentityGovernance/setenv.sh file

The OracleIdentityGovernance/setenv.sh file contains the environment variables that are passed to the YAML scripts used to create the container.  You should update the values of these environment variables with values specific to your own environment.

**Note**: If using the external database method of deployment, you should update the database environment variables to the values for the external Oracle database that you are targetting.  If using the container database, you can use the default values.

| **Environment Variable** | **Description**                                              | **Default Value**           | **Example**               |
| ------------------------ | -----------------------------------------------------------  | --------------------------- | ------------------------- |
| DC_USERHOME              | Docker Host directory where all domain/db data is kept.      | /scratch/${USER}/docker/OIG |/u01/app/docker/OIG        |
| http_proxy               | Proxy details if you have an internal proxy.                 |                             |http://myproxy.com         |
| https_proxy              |                                                              |                             |http://myproxy.com         |
| no_proxy                 |                                                              |                             |http://myproxy.com         |
| DC_HOSTNAME              | Docker hostname                                              | `hostname -f`               |mydockerhost.example.com   |
| DC_ORCL_PORT             | DB Port                                                      | 1521                        |                           |
| DC_ORCL_OEM_PORT         | DB OEM Port                                                  | 5500                        |                           |
| DC_ORCL_SID              | Oracle DB Service Name                                       | oimdb                       |                           |
| DC_ORCL_PDB              | Oracle Pluggable DB Service Name                             | oimpdb                      |                           |
| DC_ORCL_SYSPWD           | DB SYS password                                              |                             |                           |
| DC_ORCL_HOST             | DB Hostname                                                  | ${DC_HOSTNAME}              |mydbhost.example.com       |
| DC_ORCL_DBDATA           | DB Data File Location                                        | ${DC_USERHOME}/dbdata       |/u01/app/docker/OIG/dbdata |
| DC_ADMIN_PWD             | WLS Admin Server password                                    | welcome1                    |                           |
| OIG_IMAGE                | OIG Docker Image Tag                                         | oig:latest                  |                           |
| DC_RCU_SCHPWD            | RCU password                                                 | welcome1                    |                           |
| DC_RCU_OIMPFX            | RCU OIM Prefix                                               | OIM03                       |MYOIG                      |

**Note**: the <code>DC_USERHOME</code> variable must be set to a directory to which the user running the containers has full access (777).  The other variables can use the default values, or be amended to a value to meet your specific requirements.

# 4 Deploy the OIG Container

## 4.1 Create the DB container [OPTIONAL]

**Note**: this step is only required if you are deploying on a container database.

OIG requires a database to store the configuration information and RCU schema information. If you do not have a database available and require one for testing, then you can use an Oracle Database Docker image. The instructions below show how to install the database image and start the container.

Launch a browser and access the Oracle Container Registry. In the Search field enter 'enterprise' and press Enter. Click Repository: 'enterprise', Description 'Oracle Database Enterprise Edition'.

In the Terms and Conditions box, select Language as English. Click Continue and ACCEPT "Terms and Restrictions". 

On your Docker environment, login to the Oracle Container Registry and enter your username and password when prompted:

        [dockeruser@mydockerhost]$ docker login container-registry.oracle.com
        Username: <username>
        Password: <password>

For example:

        [dockeruser@mydockerhost]$ docker login container-registry.oracle.com
        Username: <emailaddress>
        Password: <password>
        WARNING! Your password will be stored unencrypted in /home/dockeruser/.docker/config.json.
        Configure a credential helper to remove this warning. See
        https://docs.docker.com/engine/reference/commandline/login/#credentials-store
       
        Login Succeeded

**Note**: If by default your SSO user/pwd is stored unencrypted in base64 in ~/.docker/config.json and you want to encrypt it then follow Appendix A : Encrypting SSO Password in config.json

Pull the Oracle Database image:

        [dockeruser@mydockerhost]$ docker pull container-registry.oracle.com/database/enterprise:12.2.0.1

The output will look similar to the following:

        [dockeruser@mydockerhost]$ docker pull container-registry.oracle.com/database/enterprise:12.2.0.1
        Trying to pull repository container-registry.oracle.com/database/enterprise ...
        12.2.0.1: Pulling from container-registry.oracle.com/database/enterprise
        f07cd347d7cc: Pull complete
        e6d45c5d2f56: Pull complete
        0c3e3e3a81c6: Pull complete
        522e6a16038b: Pull complete
        b49278619f9a: Pull complete
        Digest: sha256:1f700299f7a96c5ffcdb14e251745f1cf3832fc32fff59ee7fdce956bd5b5bf8
        Status: Downloaded newer image for container-registry.oracle.com/database/enterprise:12.2.0.1

Run the docker images command to show the image is installed into the repository. The output should look similar to this:

        [dockeruser@mydockerhost]$ docker images
        REPOSITORY                                        TAG      IMAGE ID     CREATED     SIZE
        container-registry.oracle.com/database/enterprise 12.2.0.1 12a359cd0528 2 years ago 3.44GB

Tag the image so that it matches what is expected in the Docker Compose scripts:

        [dockeruser@mydockerhost]$ docker tag \
        container-registry.oracle.com/database/enterprise:12.2.0.1 \
        localhost/oracle/database:12.2.0.1-ee

Check the images to see that the image has been tagged correctly:

        [dockeruser@mydockerhost]$ docker images
        REPOSITORY                                        TAG         IMAGE ID     CREATED      SIZE
        container-registry.oracle.com/database/enterprise 12.2.0.1    12a359cd0528 2 years ago  3.44GB
        localhost/oracle/database                         12.2.0.1-ee 12a359cd0528 2 years ago  3.44GB

Set the environment for the database container creation:

        [dockeruser@mydockerhost]$ cd OracleIdentityGovernance/samples
        
        [dockeruser@mydockerhost]$ . ../setenv.sh
        INFO: Setting up OIM Docker Environment...
        INFO: Environment variables
        DC_ADMIN_PWD=<password>
        DC_DDIR_OIM=/scratch/dockeruser/docker/OIG/oimdomain
        DC_HOSTNAME=mydockerhost.example.com
        DC_ORCL_DBDATA=/scratch/dockeruser/docker/OIG/dbdata
        DC_ORCL_HOST=mydockerhost.example.com
        DC_ORCL_OEM_PORT=5500
        DC_ORCL_PDB=oimpdb
        DC_ORCL_PORT=1521
        DC_ORCL_SID=oimdb
        DC_ORCL_SYSPWD=<password>
        DC_RCU_OIMPFX=<rcu_prefix>
        DC_RCU_SCHPWD=<password>
        DC_USERHOME=/scratch/dockeruser/docker/OIG

        [dockeruser@mydockerhost]$ cd containerizedDB/
        
        [dockeruser@mydockerhost]$ docker-compose up -d oimdb
        Creating oimdb ... done
        
Check the logs for any errors:

        [dockeruser@mydockerhost]$ docker logs -f oimdb
        
Output should be similar to the following:

        ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: knl_test7

        LSNRCTL for Linux: Version 12.2.0.1.0 - Production on 08-APR-2020 14:28:40

        Copyright (c) 1991, 2016, Oracle.  All rights reserved.

        Starting /opt/oracle/product/12.2.0.1/dbhome_1/bin/tnslsnr: please wait...

        TNSLSNR for Linux: Version 12.2.0.1.0 - Production
        System parameter file is /opt/oracle/product/12.2.0.1/dbhome_1/network/admin/listener.ora
        Log messages written to /opt/oracle/diag/tnslsnr/e0d1a0af12d2/listener/alert/log.xml
        Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
        Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))

        Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
        STATUS of the LISTENER
        ------------------------
        Alias                     LISTENER
        Version                   TNSLSNR for Linux: Version 12.2.0.1.0 - Production
        Start Date                08-APR-2020 14:28:40
        Uptime                    0 days 0 hr. 0 min. 0 sec
        Trace Level               off
        Security                  ON: Local OS Authentication
        SNMP                      OFF
        Listener Parameter File   /opt/oracle/product/12.2.0.1/dbhome_1/network/admin/listener.ora
        Listener Log File         /opt/oracle/diag/tnslsnr/e0d1a0af12d2/listener/alert/log.xml
        Listening Endpoints Summary...
        (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
        (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))
        The listener supports no services
        The command completed successfully
        ...
        Copying database files
        1% complete
        13% complete
        25% complete
        Creating and starting Oracle instance
        26% complete
        30% complete
        31% complete
        35% complete
        38% complete
        39% complete
        41% complete
        Completing Database Creation
        42% complete
        43% complete
        44% complete
        46% complete
        47% complete
        50% complete
        Creating Pluggable Databases
        55% complete
        75% complete
        Executing Post Configuration Actions
        100% complete
        Look at the log file "/opt/oracle/cfgtoollogs/dbca/oimdb/oimdb.log" for further details.

        SQL*Plus: Release 12.2.0.1.0 Production on Wed Apr 8 14:35:31 2020

        Copyright (c) 1982, 2016, Oracle.  All rights reserved.

        Connected to:
        Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

        SQL>
        System altered.

        SQL>
        Pluggable database altered.

        SQL> Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
        #########################
        DATABASE IS READY TO USE!
        #########################
        Completed: alter pluggable database oimpdb open
        2020-04-08T14:35:30.963478+00:00
        OIMPDB(3):CREATE SMALLFILE TABLESPACE "USERS" LOGGING  
          DATAFILE  '/opt/oracle/oradata/oimdb/oimpdb/users01.dbf' SIZE 5M 
        REUSE AUTOEXTEND ON NEXT  1280K MAXSIZE UNLIMITED  EXTENT MANAGEMENT LOCAL  SEGMENT SPACE MANAGEMENT  AUTO
        OIMPDB(3):Completed: CREATE SMALLFILE TABLESPACE "USERS" LOGGING  
          DATAFILE  '/opt/oracle/oradata/oimdb/oimpdb/users01.dbf' 
        SIZE 5M REUSE AUTOEXTEND ON NEXT  1280K MAXSIZE UNLIMITED  EXTENT MANAGEMENT LOCAL  
          SEGMENT SPACE MANAGEMENT  AUTO
        OIMPDB(3):ALTER DATABASE DEFAULT TABLESPACE "USERS"
        OIMPDB(3):Completed: ALTER DATABASE DEFAULT TABLESPACE "USERS"
        2020-04-08T14:35:31.807261+00:00
        ALTER SYSTEM SET control_files='/opt/oracle/oradata/oimdb/control01.ctl' SCOPE=SPFILE;
        ALTER PLUGGABLE DATABASE oimpdb SAVE STATE
        Completed:    ALTER PLUGGABLE DATABASE oimpdb SAVE STATE

## 4.2 Start External Database and Set Environment [OPTIONAL]

If you have omitted step 4.1 and are deploying on an external Oracle datase then start up the database and set the environment as follows:

        [dockeruser@mydockerhost]$ cd OracleIdentityGovernance/samples
        
        [dockeruser@mydockerhost]$ . ../setenv.sh
        INFO: Setting up OIM Docker Environment...
        INFO: Environment variables
        DC_ADMIN_PWD=<password>
        DC_DDIR_OIM=/scratch/dockeruser/docker/OIG/oimdomain
        DC_HOSTNAME=mydockerhost.example.com
        DC_ORCL_DBDATA=/scratch/dockeruser/docker/OIG/dbdata
        DC_ORCL_HOST=mydockerhost.example.com
        DC_ORCL_OEM_PORT=5500
        DC_ORCL_PDB=oimpdb
        DC_ORCL_PORT=1521
        DC_ORCL_SID=oimdb
        DC_ORCL_SYSPWD=<password>
        DC_RCU_OIMPFX=<rcu_prefix>
        DC_RCU_SCHPWD=<password>
        DC_USERHOME=/scratch/dockeruser/docker/OIG

        [dockeruser@mydockerhost]$ cd externalDB/
        
**Note**: if you are using Service Name rather than SID for your connection details then please update the /OracleIdentityGovernance/samples/externalDB/docker-compose.yaml and set the CONNECTION_STRING parameter using the format `${DC_ORCL_HOST}:${DC_ORCL_PORT}/<DB_Service_Name>`.

## 4.3 Create and Start AdminServer Container

This step assumes that the database created in the previous step or the external database is up and running:

Run the <code>docker-compose</code> command to create the container:

        [dockeruser@mydockerhost]$ docker-compose up -d oimadmin
        Recreating oimadmin ... done
        
Tail the logs until the AdminServer is running:

        [dockeruser@mydockerhost]$ docker logs -f oimadmin
        INFO: CONNECTION_STRING = mydockerhost.example.com:1521/oimpdb
        INFO: RCUPREFIX         = <rcu_prefix>
        INFO: DB_PASSWORD       = <password>
        *** Driver loaded
        Conection created successfuly

        CREATE VIEW d$pending_xatrans$ AS

        (SELECT global_tran_fmt, global_foreign_id, branch_id
        
        FROM sys.pending_trans$ tran, sys.pending_sessions$ sess

        WHERE tran.local_tran_id = sess.local_tran_id

        AND tran.state != 'collecting'

        AND BITAND(TO_NUMBER(tran.session_vector),

        POWER(2, (sess.session_id - 1))) = sess.session_id)

        /
        .....
        Repository Creation Utility - Create : Operation Completed

        Initializing WebLogic Scripting Tool (WLST) ...
        .....
        INFO: Starting the Admin Server...
        INFO: Logs = /u01/oracle/user_projects/domains/infra_domain/logs/as.log
        <Apr 8, 2020 3:09:38,089 PM UTC> <Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>
        INFO: Admin server is running
        INFO: Admin server running, ready to start managed server
        
Verify the AdminServer by logging into the WebLogic Server Administration Console using the following address:

        http:://mydockerhost.example.com:7001/console
        
Use the credentials:

+ Username : weblogic
+ Password : value of $DC_ADMIN_PWD

## 4.4 Create and Start the SOA Managed Server Container

This step assumes that the database and AdminServer are both up and running:

Run the <code>docker-compose</code> command to create the container:

        [dockeruser@mydockerhost]$ docker-compose up -d soams
        oimadmin is up-to-date
        Creating soams ... done
        
Tail the logs until the SOA Managed Server is running:

        [dockeruser@mydockerhost]$ docker logs -f soams
        INFO: Starting the managed server soa_server1
        INFO: Waiting for the Managed Server to accept requests...
        SOA Platform is running and accepting requests. Start up took 87846 ms, partition=DOMAIN
        INFO: Managed Server is running
        INFO: Managed server has been started
        INFO: Running SOA Mbean
        
Verify the SOA Managed Server by logging into the SOA Platform Welcome screen using the following address:

        http:://mydockerhost.example.com:8001/soa-infra/
        
Use the credentials:

+ Username : weblogic
+ Password : value of $DC_ADMIN_PWD

## 4.5 Create and Start the OIM Managed Server Container

This step assumes that the database, AdminServer and SOA Managed Server are both up and running:

Run the <code>docker-compose</code> command to create the container:

        [dockeruser@mydockerhost]$ docker-compose up -d oimms
        oimadmin is up-to-date
        Creating oimms ... done
        
Tail the logs until the OIM Managed Server is running:

        [dockeruser@mydockerhost]$ docker logs -f oimms
        INFO: Starting the managed server oim_server1
        INFO: Waiting for the Managed Server to accept requests...
        <Apr 15, 2020 1:57:52,575 PM UTC> <Notice> <WebLogicServer> <BEA-000360> <The server started in RUNNING mode.>
        INFO: Managed Server is running
        INFO: Managed server has been started
        INFO: Running SOA Mbean
        INFO: OIM SOA Integration Mbean executed successfully.
        
Verify the OIM Managed Server by logging into the Identity Self Service Console using the following address:

        http:://mydockerhost.example.com:14000/identity
        
Use the credentials:

+ Username : xelsysadm
+ Password : value of $DC_ADMIN_PWD

Validate the containers using the <code>docker</code> command:

        [dockeruser@mydockerhost]$ docker ps | grep oig:latest
        c8c3baa5f980  oig:latest  "/bin/bash -c /u01/o…"   About an hour ago   Up 51 minutes  
          0.0.0.0:14000-14002->14000-14002/tcp  oimms
        c585f2542a96  oig:latest  "/bin/bash -c /u01/o…"   3 hours ago         Up 3 hours     
          0.0.0.0:8001-8003->8001-8003/tcp      soams
        d284e686ebf4  oig:latest  "/bin/bash -c 'sleep…"   7 days ago          Up 7 days      
          0.0.0.0:7001->7001/tcp                oimadmin

**Note**: if you have used the containerized database you will see and additional container, <code>oimdb</code>.

# 5 How to Tear Down an OIG Container Deployment

You may have a requirement to clear down you existing OIG container environment and redeploy, for example to use different parameters.  In order to do this you need to stop and remove the containers you created and remove or rename the host directory where you maintain your domain/db data.

Firstly, stop your OIG containers:

        [dockeruser@mydockerhost]$ docker stop oimms soams oimadmin [oimdb]
        oimms
        soams
        oimadmin
        [oimdb]

**Note**: only include the containerized database <code>oimdb</code> if you have used it as your repository.

Delete the containers from your Docker environment:

        [dockeruser@mydockerhost]$ docker rm oimms soams oimadmin [oimdb]
        oimms
        soams
        oimadmin
        [oimdb]
        
Remove all directories and data below $DC_USERHOME, in the example above /scratch/${USER}/docker/OIG.

        [dockeruser@mydockerhost]$ rm -rf /scratch/${USER}/docker/OIG/*

**Note**: as an alternative to removing the directories you could use a different directory for the new deployment.

You should now be able to follow the steps above to create a new environment.  If using an external datatbase, use a new value for DC_RCU_OIMPFX to avoid schema name clashes.

# 6 Appendix A: Encrypting SSO Password in config.json

By default, executing the docker login command results in your SSO user/password being stored unencrypted in base64 format in ~/.docker/config.json. If you want to fix this you need to store your details in an external credentials store. There are numerous methods of achieving this as documented in https://docs.docker.com/engine/reference/commandline/login/#credentials-store.  Which method you choose to achieve this is for you to decide. The steps below outline how to achieve this using the `docker-credential-secretservice`.

Run the following in a terminal window:

        [dockeruser@mydockerhost]$ export https_proxy=<proxy_server_host>:<proxy_port>
        [dockeruser@mydockerhost]$ mkdir /scratch/dockercred
        [dockeruser@mydockerhost]$ cd /scratch/dockercred
        [dockeruser@mydockerhost]$ sudo wget 
        https://github.com/docker/docker-credential-helpers/releases/download/v0.6.3/\
        docker-credential-secretservice-v0.6.3-amd64.tar.gz
          && tar -xf docker-credential-secretservice-v0.6.3-amd64.tar.gz && chmod +x docker-credential-secretservice
        [dockeruser@mydockerhost]$ sed -i '0,/{/s/{/{\n\t"credsStore": "secretservice",/'~/.docker/config.json


After running the above commands the ~/.docker/config.json should look like this:

        {
            "credsStore": "secretservice",
            "auths": {
                "container-registry.oracle.com": {
                    "auth": "cnVzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx5"
                }
            },
            "HttpHeaders": {
                "User-Agent": "Docker-Client/18.09.8-ol (linux)"
            },
        }

**Note**: the "auth" param is where your unencrypted base64 user:pwd is currently stored.

Run the following and when prompted login with your SSO username and password:

        [dockeruser@mydockerhost]$ export PATH=/scratch/dockercred:$PATH
        [dockeruser@mydockerhost]$ docker logout
        [dockeruser@mydockerhost]$ docker login container-registry.oracle.com
        Username: <username>
        Password: <pwd>

The message "Login Succeeded" should be displayed.

After a successful login, the  ~/.docker/config.json should now look like this and the user/pwd is no longer shown:

        {
            "auths": {
                "container-registry.oracle.com": {}
            },
            "HttpHeaders": {
                "User-Agent": "Docker-Client/18.09.8-ol (linux)"
            },
            "credsStore": "secretservice"
            
