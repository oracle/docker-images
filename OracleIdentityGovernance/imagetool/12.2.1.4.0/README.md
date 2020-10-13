Building OIG image with WebLogic Image Tool
=============================================

## Contents

1. [Introduction](#1-introduction-1)
2. [Download the required packages/installers&Patches](#2-download-the-required-packagesinstallerspatches)
3. [Required build files](#3-required-build-files)
4. [Steps to create image](#4-steps-to-create-image)
5. [Sample Dockerfile generated with imagetool](#5-sample-dockerfile-generated-with-imagetool)

# 1. Introduction

This README describes the steps involved in building OIG image with the WebLogic Image Tool. To setup the WebLogic Image Tool,  

Download WebLogic Image Tool version 1.8.0 from the release [page](https://github.com/oracle/weblogic-image-tool/releases/download/release-1.8.0/imagetool.zip).

Unzip the release ZIP file to a desired location.

Run the following commands to setup imagetool
  $ cd your_unzipped_location/bin
  $ source setup.sh

# 2. Download the required packages/installers&Patches

Download the required installers from the [Oracle Software Delivery Cloud](https://edelivery.oracle.com/) and save them in a directory of your choice. Below the list of packages/installers & patches required for SOA image.
```
JDK
    jdk-8u241-linux-x64.tar.gz

FMW INFRA
    fmw_12.2.1.4.0_infrastructure.jar

FMW INFRA PATCHES
    p28186730_139422_Generic.zip(Opatch)
    p30432881_122140_Generic.zip(OWSM)
    p30513324_122140_Linux-x86-64.zip(OSS)
    p30581253_122140_Generic.zip(ADF)
    p30689820_122140_Generic.zip(WLS)
    p30729380_122140_Generic.zip(COH)

SOA/OSB
    fmw_12.2.1.4.0_soa.jar
    fmw_12.2.1.4.0_osb.jar

SOA/OSB PATCHES
    p30749990_122140_Generic.zip(SOA)
    p30779352_122140_Generic.zip(OSB)

IDM
    fmw_12.2.1.4.0_idm.jar
```

# 3. Required build files

The following files from this [repository](./) will be used for building the image,

        additionalBuildCmds.txt
        buildArgs

Update the repository location in `buildArgs` file in place of the place holder %DOCKER_REPO%

```diff
< --additionalBuildCommands %DOCKER_REPO%/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
---
> --additionalBuildCommands /scratch/brkarthi/source/FMW-DockerImages/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt
```
Similarily, update the placeholders %JDK_VERSION% & %BUILDTAG%


# 4. Steps to create image

### i) Add JDK package to Imagetool cache

```bash
    $ imagetool cache addInstaller --type jdk --version 8u241 --path <download location>/jdk-8u241-linux-x64.tar.gz
```

### ii) Add installers to Imagetool cache

```bash
    $ imagetool cache addInstaller --type fmw --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_infrastructure.jar
    $ imagetool cache addInstaller --type soa --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_soa.jar
    $ imagetool cache addInstaller --type osb --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_osb.jar
   $ imagetool cache addInstaller --type idm --version 12.2.1.4.0 --path <download location>/fmw_12.2.1.4.0_idm.jar
     
```
### iii) Add Patches to Imagetool cache

```bash
    $ imagetool cache addEntry --key 28186730_13.9.4.2.2 --path <download location>/p28186730_139422_Generic.zip
    $ imagetool cache addEntry --key 30432881_12.2.1.4.0 --path <download location>/p30432881_122140_Generic.zip
    $ imagetool cache addEntry --key 30513324_12.2.1.4.0 --path <download location>/p30513324_122140_Linux-x86-64.zip
    $ imagetool cache addEntry --key 30581253_12.2.1.4.0 --path <download location>/p30581253_122140_Generic.zip
    $ imagetool cache addEntry --key 30689820_12.2.1.4.0 --path <download location>/p30689820_122140_Generic.zip
    $ imagetool cache addEntry --key 30729380_12.2.1.4.0 --path <download location>/p30729380_122140_Generic.zip
    $ imagetool cache addEntry --key 30749990_12.2.1.4.0 --path <download location>/p30749990_122140_Generic.zip
    $ imagetool cache addEntry --key 30779352_12.2.1.4.0 --path <download location>/p30779352_122140_Generic.zip
```

### iv) Updated patch/Opatch to the buildAgrs

Append patch and opatch list to be used for image creation to the `buildArgs` file. Below the sample options for the above patches,

```
--patches 30432881_12.2.1.4.0,30513324_12.2.1.4.0,30581253_12.2.1.4.0,30689820_12.2.1.4.0,30729380_12.2.1.4.0,30749990_12.2.1.4.0,30779352_12.2.1.4.0
--opatchBugNumber=28186730_13.9.4.2.2
```
Below a sample `buildArgs` file after appending patch/Opacth detals,
```
create
--jdkVersion=8u241
--type oig
--version=12.2.1.4.0
--tag=200506.0000
--additionalBuildCommands /scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/imagetool/12.2.1.4.0/additionalBuildCmds.txt                    
--additionalBuildFiles /scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/createDomainAndStart.sh,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/createOIMDomain.py,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/dbUtils.class,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/oim_soa_integration.py,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/startAdmin.sh,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/startMS.sh,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/update_listenaddress.py,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/wait-for-it.sh,/scratch/anujpand/gitrepo/FMW-DockerImages/OracleIdentityGovernance/dockerfiles/12.2.1.4.0/container-scripts/xaview.sql

```

### v) Create image

Execute the below command to create the SOA image,

```bash
        $ imagetool @buildArgs
```

# 5. Sample Dockerfile generated with imagetool

```Dockerfile
########## BEGIN DOCKERFILE ##########
#
# Copyright (c) 2019, 2020, Oracle and/or its affiliates.  All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
FROM oraclelinux:7-slim as OS_UPDATE
LABEL com.oracle.weblogic.imagetool.buildid="24e2c406-c6fb-4406-9689-d65e0885c004"
USER root

RUN yum -y --downloaddir= install gzip tar unzip \
 && yum -y --downloaddir= clean all \
 && rm -rf /var/cache/yum/* \
 && rm -rf 

## Create user and group
RUN if [ -z "$(getent group oracle)" ]; then hash groupadd &> /dev/null && groupadd oracle || exit -1 ; fi \
 && if [ -z "$(getent passwd oracle)" ]; then hash useradd &> /dev/null && useradd -g oracle oracle || exit -1; fi \
 && mkdir /u01 \
 && chown oracle:oracle /u01

# Install Java
FROM OS_UPDATE as JDK_BUILD
LABEL com.oracle.weblogic.imagetool.buildid="24e2c406-c6fb-4406-9689-d65e0885c004"

ENV JAVA_HOME=/u01/jdk

COPY --chown=oracle:oracle JDK-1.8.0-241-07-191216.1.8.0.241.007.0.tar.gz /tmp/imagetool/

USER oracle


RUN tar xzf /tmp/imagetool/JDK-1.8.0-241-07-191216.1.8.0.241.007.0.tar.gz -C /u01 \
 && mv /u01/jdk* /u01/jdk \
 && rm -rf /tmp/imagetool


# Install Middleware
FROM OS_UPDATE as WLS_BUILD
LABEL com.oracle.weblogic.imagetool.buildid="24e2c406-c6fb-4406-9689-d65e0885c004"

ENV JAVA_HOME=/u01/jdk \
    ORACLE_HOME=/u01/oracle \
    OPATCH_NO_FUSER=true

RUN mkdir -p /u01/oracle \
 && mkdir -p /u01/oracle/oraInventory \
 && chown oracle:oracle /u01/oracle/oraInventory \
 && chown oracle:oracle /u01/oracle

COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

COPY --chown=oracle:oracle fmw_12.2.1.4.0_infrastructure.jar fmw.rsp /tmp/imagetool/
COPY --chown=oracle:oracle fmw_12.2.1.4.0_soa.jar soa.rsp /tmp/imagetool/
COPY --chown=oracle:oracle fmw_12.2.1.4.0_osb.jar osb.rsp /tmp/imagetool/
COPY --chown=oracle:oracle fmw_12.2.1.4.0_idm.jar idm.rsp /tmp/imagetool/
COPY --chown=oracle:oracle oraInst.loc /u01/oracle/



USER oracle


RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_infrastructure.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/fmw.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_soa.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/soa.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_osb.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/osb.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation
RUN  \
 /u01/jdk/bin/java -Xmx1024m -jar /tmp/imagetool/fmw_12.2.1.4.0_idm.jar -silent ORACLE_HOME=/u01/oracle \
    -responseFile /tmp/imagetool/idm.rsp -invPtrLoc /u01/oracle/oraInst.loc -ignoreSysPrereqs -force -novalidation





FROM OS_UPDATE as FINAL_BUILD

ARG ADMIN_NAME
ARG ADMIN_HOST
ARG ADMIN_PORT
ARG MANAGED_SERVER_PORT

ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/u01/jdk \
    LC_ALL=${DEFAULT_LOCALE:-en_US.UTF-8} \
    PATH=${PATH}:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle

LABEL com.oracle.weblogic.imagetool.buildid="24e2c406-c6fb-4406-9689-d65e0885c004"

    COPY --from=JDK_BUILD --chown=oracle:oracle /u01/jdk /u01/jdk/

COPY --from=WLS_BUILD --chown=oracle:oracle /u01/oracle /u01/oracle/



USER oracle
WORKDIR /u01/oracle

#ENTRYPOINT /bin/bash

    
    ENV ORACLE_HOME=/u01/oracle \
        USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
        PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin \
        DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
        DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
        DOMAIN_HOME="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"/"${DOMAIN_NAME:-base_domain}" \
        ADMIN_PORT="${ADMIN_PORT:-7001}" \
        SOA_PORT="${SOA_PORT:-8001}" \
        OIM_PORT="${OIM_PORT:-14000}" \
        OIM_SSL_PORT="${OIM_SSL_PORT:-14002}" \
        PATH=$PATH:/u01/oracle \
        DOMAIN_TYPE="oim"
    
    USER root
    
    RUN mkdir -p /u01/oracle/dockertools 
        
    COPY --chown=oracle:oracle files/createDomainAndStart.sh files/createOIMDomain.py files/dbUtils.class files/oim_soa_integration.py files/startAdmin.sh files/startMS.sh files/update_listenaddress.py files/wait-for-it.sh files/xaview.sql /u01/oracle/dockertools/
    RUN chmod a+xr /u01/oracle/dockertools/*.* && \
         chown -R oracle:oracle /u01/oracle/dockertools
    
    USER oracle
    WORKDIR $ORACLE_HOME
    CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]

########## END DOCKERFILE ##########
```